"""Read-only geometry/UV/skin regression for the source-basis migration.

Uses the existing numpy tool dependency. No Studio, render, upload or source edit.
"""
import hashlib
import json
import re
import struct
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "assets/local-demo/content"


def decode(path):
    text = path.read_text(encoding="utf-8")
    match = re.search(r"\[(=+)\[", text)
    return json.loads(text[match.end():text.index("]" + match[1] + "]", match.end())])


def mesh(uri, expected):
    payload = (CONTENT / uri.removeprefix("rbxasset://")).read_bytes()
    assert hashlib.sha256(payload).hexdigest() == expected
    lines = payload.decode("ascii").splitlines()
    assert lines[0] == "version 1.01" and int(lines[1]) == len(lines) - 2
    return np.array([[[float(v) for v in field.split(",")]
                      for field in re.findall(r"\[([^\]]+)\]", line)]
                     for line in lines[2:]]).reshape(-1, 3, 3, 3)


def direct_gltf():
    """Independent comparison to the original record-store GLB, not an old export."""
    source = ROOT / "assets/supplied/buildings/set-01/record-store.glb"
    raw = source.read_bytes()
    length = struct.unpack_from("<I", raw, 12)[0]
    doc = json.loads(raw[20:20 + length])
    offset = 20 + length
    binary_length, binary_kind = struct.unpack_from("<II", raw, offset)
    assert binary_kind == 0x004E4942
    binary = raw[offset + 8:offset + 8 + binary_length]

    def accessor(index):
        item = doc["accessors"][index]
        view = doc["bufferViews"][item["bufferView"]]
        dtype = np.dtype({5126: "<f4", 5125: "<u4", 5123: "<u2", 5121: "u1"}[item["componentType"]])
        width = {"VEC2": 2, "VEC3": 3, "SCALAR": 1}[item["type"]]
        return np.ndarray((item["count"], width), dtype=dtype, buffer=binary,
                          offset=view.get("byteOffset", 0) + item.get("byteOffset", 0),
                          strides=(view.get("byteStride", width * dtype.itemsize), dtype.itemsize)).copy()

    def transform(node):
        if "matrix" in node:
            return np.array(node["matrix"]).reshape(4, 4, order="F")
        x, y, z, w = node.get("rotation", [0, 0, 0, 1])
        result = np.eye(4)
        result[:3, :3] = np.array([
            [1 - 2 * (y*y + z*z), 2 * (x*y - z*w), 2 * (x*z + y*w)],
            [2 * (x*y + z*w), 1 - 2 * (x*x + z*z), 2 * (y*z - x*w)],
            [2 * (x*z - y*w), 2 * (y*z + x*w), 1 - 2 * (x*x + y*y)],
        ]) @ np.diag(node.get("scale", [1, 1, 1]))
        result[:3, 3] = node.get("translation", [0, 0, 0])
        return result

    primitives = []

    def visit(index, parent):
        node = doc["nodes"][index]
        matrix = parent @ transform(node)
        if "mesh" in node:
            for primitive in doc["meshes"][node["mesh"]]["primitives"]:
                points = accessor(primitive["attributes"]["POSITION"])
                points = (matrix @ np.column_stack([points, np.ones(len(points))]).T).T[:, :3]
                primitives.append((points, accessor(primitive["indices"]).reshape(-1, 3),
                                   accessor(primitive["attributes"]["TEXCOORD_0"])))
        for child in node.get("children", []):
            visit(child, matrix)

    for index in doc["scenes"][doc.get("scene", 0)]["nodes"]:
        visit(index, np.eye(4))
    points = np.concatenate([item[0] for item in primitives])
    low, high = points.min(0), points.max(0)
    origin = np.array([(low[0] + high[0]) / 2, low[1], (low[2] + high[2]) / 2])
    scale = min(32 / (high[0] - low[0]), 24 / (high[1] - low[1]), 16 / (high[2] - low[2]))
    # glTF is already Y-up: the correct frontage conversion is a proper Y rotation.
    source_points = np.concatenate([((p - origin) * [-1, 1, -1] * scale)[i] for p, i, _ in primitives])
    source_uvs = np.concatenate([uv[i] for _, i, uv in primitives])
    asset = next(item for item in decode(ROOT / "src/shared/QuayBuildingCatalog.luau")
                 if item["id"] == "NQ-BLD-02")
    part = asset["parts"][0]
    runtime = mesh(part["uri"], part["sha256"])
    position_error = float(np.max(np.abs(source_points - runtime[:, :, 0] - part["center"])))
    runtime_uvs = runtime[:, :, 2, :2].copy()
    runtime_uvs[:, :, 1] = 1 - runtime_uvs[:, :, 1]  # Observed legacy .mesh import boundary.
    uv_error = float(np.max(np.abs(source_uvs - runtime_uvs)))
    assert position_error < 0.0001 and uv_error < 0.000001
    return {"asset": asset["id"], "triangles": len(runtime),
            "original_source_sha256": hashlib.sha256(raw).hexdigest(),
            "max_position_error_studs": position_error, "max_native_gltf_uv_error": uv_error}


def main():
    receipt = json.loads((ROOT / "docs/evidence/local-mesh-basis-v2.json").read_text())
    triangles = 0
    for item in receipt["meshes"]:
        before = mesh(item["before_uri"], item["before_sha256"])
        after = mesh(item["uri"], item["sha256"])[:, [0, 2, 1]]
        assert before.shape == after.shape
        np.testing.assert_array_equal(after[:, :, 0], before[:, :, 0] * [-1, 1, 1])
        np.testing.assert_array_equal(after[:, :, 1], before[:, :, 1] * [-1, 1, 1])
        np.testing.assert_array_equal(after[:, :, 2], before[:, :, 2])
        triangles += len(before)
    for relative, expected in receipt["source_sha256_after"].items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == expected

    backup = Path(receipt["backup"])
    current = decode(ROOT / "src/shared/CompanionModels.luau")
    previous = {item["id"]: item for item in decode(backup / "src/shared/CompanionModels.luau")}
    clip_names, skin_parts = set(), 0
    for item in current:
        old = previous[item["id"]]
        assert item["source_sha256"] == old["source_sha256"]
        skin, old_skin = item.get("suppliedSkin"), old.get("suppliedSkin")
        if not skin:
            continue
        for name, frame in skin["rest"].items():
            expected = np.array(old_skin["rest"][name]) * [-1, 1, 1, 1, -1, -1, 1]
            np.testing.assert_array_equal(frame, expected)
        for part, old_part in zip(skin["parts"], old_skin["parts"]):
            np.testing.assert_array_equal(part["center"], np.array(old_part["center"]) * [-1, 1, 1])
            assert part["size"] == old_part["size"] and len(part["weights"]) == len(old_part["weights"])
            for (point, weights), (old_point, old_weights) in zip(part["weights"], old_part["weights"]):
                np.testing.assert_array_equal(point, np.array(old_point) * [-1, 1, 1])
                assert weights == old_weights
            skin_parts += 1
        clip_names.update(skin["clips"].values())
    frames = 0
    for name in clip_names:
        after = decode(ROOT / "src/shared" / (name + ".luau"))
        before = decode(backup / "src/shared" / (name + ".luau"))
        old_frames = np.array(before["samples"])
        np.testing.assert_array_equal(after["samples"], old_frames * [-1, 1, 1, 1, -1, -1, 1])
        frames += int(np.prod(old_frames.shape[:-1]))
    result = {"status": "PASS", "mesh_files": len(receipt["meshes"]), "triangles": triangles,
              "uv_corner_values_changed": 0, "sources_unchanged": len(receipt["source_sha256_after"]),
              "supplied_skin_parts": skin_parts, "animation_clips": len(clip_names),
              "animation_bone_frames": frames, "original_glb_comparison": direct_gltf(),
              "runtime_acceptance": "PENDING_ROOT_STUDIO_CHECK"}
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
