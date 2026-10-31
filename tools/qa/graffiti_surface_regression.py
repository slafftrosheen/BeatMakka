"""Validate reviewed graffiti panels against the exact rendered local triangles.

No Studio, uploads, mesh conversions or dependencies are installed by this tool.
Uses the same existing numpy dependency as the local geometry audit tools.
Run --legacy to reproduce the bounding-box defect; --write refreshes anchors only
after complete panel coverage and foreground-intersection checks pass.
"""

import argparse
import hashlib
import json
import re
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "src/shared/QuayGraffitiAnchors.luau"
# Texture-aware side/back projections reviewed in output/graffiti-surface-debug.
# Reviewed coordinates follow the runtime basis correction (-x, y, z): the same
# source panels are now left walls, without changing source models or textures.
# Coordinates and dimensions are Art-local studs, before runtime model scale.
PANELS = [
    ("GRA-01", "NQ-BLD-13", "left", -3.5, 5, 10, 6),
    ("GRA-02", "NQ-BLD-01", "left", 2, 7.5, 8, 4),
    ("GRA-03", "NQ-BLD-09", "left", -5.5, 4.5, 5, 2.5),
    ("GRA-06", "NQ-BLD-09", "back", 0, 4, 7, 5),
    ("GRA-07", "NQ-BLD-13", "back", 0, 4.5, 10, 6),
    ("GRA-08", "NQ-BLD-03", "left", -4, 8, 3, 2.25),
    ("GRA-09", "NQ-BLD-08", "back", .6, 3.7, 1.6, 1.2),
    ("GRA-10", "NQ-BLD-01", "back", 0, 6.6, 8, 3.2),
]


def decode(path):
    text = path.read_text(encoding="utf-8")
    match = re.search(r"\[(=+)\[", text)
    return json.loads(text[match.end():text.index("]" + match[1] + "]", match.end())])


def catalog():
    chunks = []
    for index in range(1, 17):
        text = (ROOT / f"src/shared/LocalMeshCatalogData{index}.luau").read_text()
        chunks.append(re.search(r"\[=\[(.*)\]=\]", text, re.S)[1])
    records = {asset["id"]: asset for asset in json.loads("".join(chunks))}
    # Keep precedence identical to LocalArtLibrary.
    for name in ("QuayArchitectureCatalog", "QuayBuildingCatalog"):
        for asset in decode(ROOT / f"src/shared/{name}.luau"):
            records[asset["id"]] = asset
    return records


def triangles(asset):
    result, parts = [], []
    for part in asset["parts"]:
        path = ROOT / "assets/local-demo/content" / part["uri"].removeprefix("rbxasset://")
        payload = path.read_bytes()
        assert hashlib.sha256(payload).hexdigest() == part["sha256"], path
        for line in payload.decode("ascii").splitlines()[2:]:
            fields = [[float(v) for v in s.split(",")]
                      for s in re.findall(r"\[([^\]]+)\]", line)]
            result.append(np.array(fields)[[0, 3, 6]] + part["center"])
            parts.append(part)
    return np.array(result), parts


def surface_at(tris, side, horizontal, height):
    axis, horizontal_axis = (0, 2) if side in ("right", "left") else (2, 0)
    direction = -1 if side == "left" else 1
    q = tris[:, :, [horizontal_axis, 1]]
    a, b = q[:, 1] - q[:, 0], q[:, 2] - q[:, 0]
    det = a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]
    valid = abs(det) > 1e-9
    det = np.where(valid, det, 1)
    p = np.array([horizontal, height]) - q[:, 0]
    s = (p[:, 0] * b[:, 1] - p[:, 1] * b[:, 0]) / det
    t = (a[:, 0] * p[:, 1] - a[:, 1] * p[:, 0]) / det
    depth = tris[:, 0, axis] + s * (tris[:, 1, axis] - tris[:, 0, axis]) + t * (
        tris[:, 2, axis] - tris[:, 0, axis])
    valid &= (s >= -1e-6) & (t >= -1e-6) & (s + t <= 1 + 1e-6)
    assert valid.any(), "No rendered surface at the proposed anchor"
    index = int(np.argmax(np.where(valid, depth * direction, -np.inf)))
    position = np.zeros(3)
    position[axis], position[horizontal_axis], position[1] = depth[index], horizontal, height
    triangle = tris[index]
    normal = np.cross(triangle[1] - triangle[0], triangle[2] - triangle[0])
    normal /= np.linalg.norm(normal)
    if normal[axis] * direction < 0:
        normal = -normal
    return index, position, normal


def clip(polygon, axis, sign, limit):
    output = []
    for a, b in zip(polygon, polygon[1:] + polygon[:1]):
        inside_a, inside_b = sign * a[axis] <= limit, sign * b[axis] <= limit
        if inside_a:
            output.append(a)
        if inside_a != inside_b:
            fraction = (sign * limit - a[axis]) / (b[axis] - a[axis])
            output.append(a + (b - a) * fraction)
    return output


def validate(tris, position, normal, width, height):
    right = np.cross(normal, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, normal)
    q = (tris - position) @ np.array([right, up, normal]).T
    # Clip every foreground triangle, including tiny fixtures between sample rays.
    # This rejects any window/door frame, pipe, planter or trim crossing the panel.
    foreground = 0
    for triangle in q:
        if max(triangle[:, 2]) < .025:
            continue
        polygon = list(triangle)
        for axis, sign, limit in ((0, 1, width / 2), (0, -1, width / 2),
                                  (1, 1, height / 2), (1, -1, height / 2)):
            if polygon:
                polygon = clip(polygon, axis, sign, limit)
        if len(polygon) >= 3 and max(p[2] for p in polygon) > .025:
            area = abs(sum(a[0] * b[1] - b[0] * a[1]
                           for a, b in zip(polygon, polygon[1:] + polygon[:1]))) / 2
            foreground += area > .0001
    # Dense support rays include every corner/edge; a hole cannot use a back wall.
    a, b = q[:, 1, :2] - q[:, 0, :2], q[:, 2, :2] - q[:, 0, :2]
    det = a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]
    valid = abs(det) > 1e-9
    det = np.where(valid, det, 1)
    unsupported, samples = 0, 0
    for y in np.linspace(-height / 2, height / 2, max(2, int(height / .1) + 1)):
        for x in np.linspace(-width / 2, width / 2, max(2, int(width / .1) + 1)):
            p = np.array([x, y]) - q[:, 0, :2]
            s = (p[:, 0] * b[:, 1] - p[:, 1] * b[:, 0]) / det
            t = (a[:, 0] * p[:, 1] - a[:, 1] * p[:, 0]) / det
            inside = valid & (s >= -1e-6) & (t >= -1e-6) & (s + t <= 1 + 1e-6)
            depth = q[:, 0, 2] + s * (q[:, 1, 2] - q[:, 0, 2]) + t * (
                q[:, 2, 2] - q[:, 0, 2])
            unsupported += abs(max(depth[inside], default=-999)) > .025
            samples += 1
    return int(foreground), int(unsupported), samples


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--legacy", action="store_true")
    args = parser.parse_args()
    assets, anchors, failures = catalog(), {}, 0
    layout = (ROOT / "src/shared/QuayStreetLayout.luau").read_text()
    for ident, building, side, horizontal, height, width, panel_height in PANELS:
        row = re.search(r'\{\s*id\s*=\s*"' + ident + r'"([^}]+)\}', layout)
        assert row, f"{ident} is missing from street layout"
        fields = row[1]
        for name, expected in (("building", building), ("wall", side)):
            assert re.search(name + r'\s*=\s*"' + expected + '"', fields), f"{ident}: {name} drift"
        for name, expected in (("width", width), ("height", panel_height)):
            value = re.search(name + r"\s*=\s*([0-9.]+)", fields)
            assert value and float(value[1]) == expected, f"{ident}: {name} drift"
        asset = assets[building]
        tris, parts = triangles(asset)
        index, position, normal = surface_at(tris, side, horizontal, height)
        if args.legacy:
            # Reproduce old box-edge placement for the same panel: source bounds
            # can include cornices/fixtures and are not a facade surface.
            axis = 0 if side in ("right", "left") else 2
            position[axis] = tris[:, :, axis].min() - .12 if side == "left" else tris[:, :, axis].max() + .12
        foreground, unsupported, samples = validate(tris, position, normal, width, panel_height)
        passed = foreground == unsupported == 0
        failures += not passed
        print(f"{'PASS' if passed else 'FAIL'} {ident} {building}/{side}: "
              f"{samples} support rays, {unsupported} unsupported, {foreground} foreground triangles")
        anchors[ident] = dict(
            building=building, wall=side, center=[round(float(v), 8) for v in position],
            normal=[round(float(v), 8) for v in normal], width=width, height=panel_height,
            source=asset["source"], source_sha256=asset["source_sha256"],
            coordinate_basis=asset.get("coordinate_basis"),
            mesh_sha256=parts[index]["sha256"], mesh_center=parts[index]["center"],
            mesh_size=parts[index]["size"], support_samples=samples,
        )
    assert failures == 0, f"{failures} panels do not sit on unobstructed rendered walls"
    if args.write:
        TARGET.write_text(
            "-- Generated by tools/qa/graffiti_surface_regression.py --write.\n"
            "-- Reviewed Art-local wall panels; source hashes invalidate stale anchors.\n"
            "return game:GetService(\"HttpService\"):JSONDecode([=["
            + json.dumps(anchors, separators=(",", ":")) + "]=])\n", encoding="utf-8")
    else:
        assert decode(TARGET) == anchors, "Graffiti anchors are stale; inspect art before regenerating"
    print(f"PASS: {len(anchors)} source-bound mesh-wall panels; no uploads")


if __name__ == "__main__":
    main()
