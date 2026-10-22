"""Decode our own optimized GLBs for local EditableMesh review through Studio MCP.

No Roblox asset upload, network download, new geometry, or third-party importer.
Supports the uncompressed triangle GLBs exported by build_optimized_assets.py.
"""
from pathlib import Path
import json
import struct
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "work/studio-payloads"
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((ROOT / "docs/evidence/optimized-assets.json").read_text())
DTYPES = {5126: "<f4", 5125: "<u4", 5123: "<u2", 5121: "u1"}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def transform(node):
    if "matrix" in node:
        return np.array(node["matrix"]).reshape((4, 4), order="F")
    m = np.eye(4)
    x, y, z, w = node.get("rotation", [0, 0, 0, 1])
    m[:3, :3] = [[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                 [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                 [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]]
    m[:3, :3] = m[:3, :3] @ np.diag(node.get("scale", [1, 1, 1]))
    m[:3, 3] = node.get("translation", [0, 0, 0])
    return m


for asset in report["assets"]:
    raw = (ROOT / asset["output"]).read_bytes()
    length = struct.unpack_from("<I", raw, 12)[0]
    doc = json.loads(raw[20:20 + length])
    offset = 20 + length
    bin_length, bin_type = struct.unpack_from("<II", raw, offset)
    assert bin_type == 0x004E4942
    binary = raw[offset + 8:offset + 8 + bin_length]

    def accessor(index):
        a = doc["accessors"][index]
        v = doc["bufferViews"][a["bufferView"]]
        dtype = np.dtype(DTYPES[a["componentType"]])
        width = WIDTHS[a["type"]]
        start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
        return np.ndarray((a["count"], width), dtype=dtype, buffer=binary, offset=start,
                          strides=(v.get("byteStride", width * dtype.itemsize), dtype.itemsize)).copy()

    parts = []
    # glTF front is +Z; rotate 180 degrees around Y for the project's -Z front.
    basis = np.diag([-1, 1, -1, 1])

    def visit(index, parent):
        node = doc["nodes"][index]
        matrix = parent @ transform(node)
        if "mesh" in node:
            for p in doc["meshes"][node["mesh"]]["primitives"]:
                assert p.get("mode", 4) == 4
                attrs = p["attributes"]
                positions = accessor(attrs["POSITION"])
                positions = (basis @ matrix @ np.column_stack([positions, np.ones(len(positions))]).T).T[:, :3]
                normals = accessor(attrs["NORMAL"])
                normals = (basis[:3, :3] @ np.linalg.inv(matrix[:3, :3]).T @ normals.T).T
                normals /= np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-8)
                indices = accessor(p["indices"]).flatten().reshape((-1, 3)) + 1
                parts.append({"name": node.get("name", asset["id"]),
                              "positions": np.round(positions, 6).tolist(), "normals": np.round(normals, 6).tolist(),
                              "uvs": np.round(accessor(attrs["TEXCOORD_0"]), 6).tolist(), "triangles": indices.tolist(),
                              "bounds_min": positions.min(axis=0).tolist(), "bounds_max": positions.max(axis=0).tolist()})
        for child in node.get("children", []): visit(child, matrix)

    for node in doc["scenes"][doc.get("scene", 0)]["nodes"]: visit(node, np.eye(4))
    assert sum(len(p["triangles"]) for p in parts) == asset["after"]["triangles"]
    payload = {"id": asset["id"], "source": asset["output"], "sha256": asset["sha256"],
               "resolution": asset["texture_size"], "parts": parts}
    (OUT / (asset["id"] + ".json")).write_text(json.dumps(payload, separators=(",", ":")) + "\n")
print("Prepared 20 local-review mesh payloads with positions, normals, UVs, part groups and hashes.")
