"""Migrate generated local meshes from a reflected to a proper source basis.

The previous Blender -> Roblox map (x,z,y) has determinant -1. Reversing face
winding repaired culling but retained mirrored geometry/text. The correct
front-preserving map (-x,z,y) has determinant +1. This offline migration applies
the relative X reflection to generated positions/normals/centers and reverses
triangle corners together with their original UVs. It never changes images or
source GLB/BLEND files. Original generated mesh files remain available.

Run without flags to inspect; --write applies the idempotent basis migration.
Installation/package generation is deliberately a separate existing workflow.
"""

import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "assets/local-demo/content"
BASIS = "blender_to_roblox_front_minus_z_v2"
CATALOGS = (
    "CompanionModels", "QuayDressingCatalog", "QuayBuildingCatalog",
    "QuayVanCatalog", "QuayLiftupCatalog", "QuayArchitectureCatalog",
)
MANIFESTS = (
    "assets/production/needle-quay/architecture-artbook/manifest.json",
    "assets/production/needle-quay/dressing/manifest.json",
    "assets/production/needle-quay/liftup/manifest.json",
    "assets/production/needle-quay/models/supplied-buildings/manifest.json",
    "assets/production/needle-quay/models/supplied-van/manifest.json",
)


def digest(payload):
    return hashlib.sha256(payload).hexdigest()


def decode_lua(path):
    text = path.read_text(encoding="utf-8")
    opening = re.search(r"\[(=+)\[", text)
    assert opening, path
    return json.loads(text[opening.end():text.index("]" + opening[1] + "]", opening.end())])


def lua_json(value):
    return ("-- Generated local geometry; proper source basis, original UV corner associations.\n"
            "return game:GetService(\"HttpService\"):JSONDecode([=["
            + json.dumps(value, separators=(",", ":")) + "]=])\n").encode()


def reflect_position(row):
    assert len(row) == 3
    row[0] = -row[0]


def reflect_frame(row):
    # Conjugate the entire rigid transform by S=diag(-1,1,1), including the
    # quaternion's axial-vector parity. Negating translation alone breaks skins.
    assert len(row) == 7
    row[0], row[4], row[5] = -row[0], -row[4], -row[5]


def reflected_vector_text(text):
    values = text.split(",")
    assert len(values) == 3
    values[0] = format(-float(values[0]), ".7g")
    return ",".join(values)


class Migration:
    def __init__(self):
        self.writes, self.meshes, self.assets, self.sources = {}, {}, {}, {}
        self.clips = set()

    def stage(self, path, payload):
        if path.exists() and path.read_bytes() == payload:
            return
        previous = self.writes.get(path)
        assert previous is None or previous == payload, f"Conflicting output: {path}"
        self.writes[path] = payload

    def mesh(self, uri, expected):
        if uri in self.meshes:
            assert self.meshes[uri]["before_sha256"] == expected
            return self.meshes[uri]
        relative = uri.removeprefix("rbxasset://")
        source = (CONTENT / relative).resolve()
        assert source.is_relative_to(CONTENT.resolve()) and source.suffix == ".mesh"
        original = source.read_bytes()
        assert digest(original) == expected, f"Existing mesh hash mismatch: {source}"
        lines = original.decode("ascii").splitlines()
        assert lines[0] == "version 1.01" and len(lines) - 2 == int(lines[1])
        output = lines[:2]
        for line in lines[2:]:
            fields = re.findall(r"\[([^\]]+)\]", line)
            assert len(fields) == 9
            corners = [fields[index:index + 3] for index in (0, 3, 6)]
            # UV strings travel with their original vertex; neither U nor V flips.
            output.append("".join(
                "[" + reflected_vector_text(corners[index][0]) + "]"
                "[" + reflected_vector_text(corners[index][1]) + "]"
                "[" + corners[index][2] + "]" for index in (0, 2, 1)))
        payload = ("\n".join(output) + "\n").encode("ascii")
        after = digest(payload)
        stem = source.stem.replace(expected[:12], after[:12])
        if stem == source.stem:
            stem += "_basis-v2_" + after[:12]
        destination = source.with_name(stem + ".mesh")
        self.stage(destination, payload)
        result = {
            "before_uri": uri, "before_sha256": expected,
            "uri": "rbxasset://" + destination.relative_to(CONTENT).as_posix(),
            "sha256": after, "triangles": int(lines[1]),
            "uv_corner_values_unchanged": True,
        }
        self.meshes[uri] = result
        return result

    def part(self, part):
        result = self.mesh(part["uri"], part["sha256"])
        part["uri"], part["sha256"] = result["uri"], result["sha256"]
        reflect_position(part["center"])
        for point, _ in part.get("weights", []):
            reflect_position(point)

    def asset(self, asset):
        if asset.get("coordinate_basis") == BASIS:
            return False
        before_source = asset.get("source_sha256")
        for part in asset["parts"]:
            self.part(part)
        if asset.get("skin"):
            self.part(asset["skin"])
        for lod in asset.get("lods", []):
            for part in lod["parts"]:
                self.part(part)
        supplied = asset.get("suppliedSkin")
        if supplied:
            for part in supplied["parts"]:
                self.part(part)
            for frame in supplied["rest"].values():
                reflect_frame(frame)
            self.clips.update(supplied["clips"].values())
        for position in asset.get("joints", {}).values():
            reflect_position(position)
        for position in asset.get("lights", []):
            reflect_position(position)
        if asset.get("sign"):
            reflect_position(asset["sign"]["position"])
        asset["coordinate_basis"] = BASIS
        assert asset.get("source_sha256") == before_source
        source_path = ROOT / asset["source"]
        if source_path.exists() and asset["source"] not in self.sources:
            self.sources[asset["source"]] = digest(source_path.read_bytes())
        self.assets[asset["id"]] = asset
        return True

    def build(self):
        mesh_manifest_path = ROOT / "assets/local-demo/mesh-manifest.json"
        mesh_manifest = json.loads(mesh_manifest_path.read_text(encoding="utf-8"))
        if any([self.asset(asset) for asset in mesh_manifest["assets"]]):
            self.stage(mesh_manifest_path, (json.dumps(mesh_manifest, indent=2) + "\n").encode())

        catalog_path = ROOT / "src/shared/LocalMeshCatalog.luau"
        chunk_names = re.findall(r"require\(script\.Parent\.(LocalMeshCatalogData\d+)\)", catalog_path.read_text())
        chunks = []
        for name in chunk_names:
            text = (ROOT / "src/shared" / (name + ".luau")).read_text()
            opening = re.search(r"\[(=+)\[", text)
            chunks.append(text[opening.end():text.rindex("]" + opening[1] + "]")])
        records = json.loads("".join(chunks))
        if any([self.asset(asset) for asset in records]):
            payload = json.dumps(records, separators=(",", ":"))
            names = []
            for index, start in enumerate(range(0, len(payload), 140000), 1):
                name = "LocalMeshCatalogData" + str(index)
                names.append(name)
                self.stage(ROOT / "src/shared" / (name + ".luau"),
                           ("return [=[" + payload[start:start + 140000] + "]=]\n").encode())
            self.stage(catalog_path, ("-- Generated source-faithful local mesh catalog.\n"
                       "return game:GetService(\"HttpService\"):JSONDecode(table.concat({"
                       + ",".join("require(script.Parent." + name + ")" for name in names)
                       + "}))\n").encode())

        for name in CATALOGS:
            path = ROOT / "src/shared" / (name + ".luau")
            assets = decode_lua(path)
            if any([self.asset(asset) for asset in assets]):
                self.stage(path, lua_json(assets))

        for relative in MANIFESTS:
            path = ROOT / relative
            manifest = json.loads(path.read_text())
            changed = False
            for asset in manifest.get("assets", []):
                changed |= self.asset(asset)
            for layout in manifest.get("layout", {}).values():
                if layout.get("coordinate_basis") != BASIS:
                    layout["door_x"] = -layout["door_x"]
                    layout["coordinate_basis"] = BASIS
                    changed = True
            if changed:
                self.stage(path, (json.dumps(manifest, indent=2) + "\n").encode())

        for name in ("QuayBuildingLayout", "QuayVanLayout"):
            path = ROOT / "src/shared" / (name + ".luau")
            layouts = decode_lua(path)
            changed = False
            for layout in layouts.values():
                if layout.get("coordinate_basis") != BASIS:
                    layout["door_x"] = -layout["door_x"]
                    layout["coordinate_basis"] = BASIS
                    changed = True
            if changed:
                self.stage(path, lua_json(layouts))

        for name in ("NeedleQuayGeometry", "NeedleQuayCharacters"):
            path = ROOT / "src/shared" / (name + ".luau")
            assets = decode_lua(path)
            changed = False
            for asset in assets:
                if asset.get("coordinate_basis") == BASIS:
                    continue
                for part in asset["parts"]:
                    reflect_position(part["position"])
                asset["coordinate_basis"] = BASIS
                changed = True
            if changed:
                self.stage(path, lua_json(assets))

        for module in sorted(self.clips):
            path = ROOT / "src/shared" / (module + ".luau")
            clip = decode_lua(path)
            if clip.get("coordinate_basis") != BASIS:
                for sample in clip["samples"]:
                    for frame in sample:
                        reflect_frame(frame)
                clip["coordinate_basis"] = BASIS
                self.stage(path, lua_json(clip))

        # This supplied-character manifest lists runtime filenames separately.
        path = ROOT / "assets/production/needle-quay/companions/supplied/manifest.json"
        manifest = json.loads(path.read_text())
        replacements = {old.removeprefix("rbxasset://needle-quay/"): row["uri"].removeprefix("rbxasset://needle-quay/")
                        for old, row in self.meshes.items()}
        changed = False
        for character in manifest["characters"]:
            if character.get("coordinate_basis") != BASIS:
                character["runtime_content_files"] = [replacements.get(value, value)
                                                       for value in character["runtime_content_files"]]
                character["coordinate_basis"] = BASIS
                changed = True
        if changed:
            self.stage(path, (json.dumps(manifest, indent=2) + "\n").encode())

    def apply(self):
        backup = Path.home() / ".codex/backups/BeatMaka" / ("mesh-basis-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        for path, payload in self.writes.items():
            if path.exists():
                target = backup / path.relative_to(ROOT)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(path.read_bytes())
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)
        for source, expected in self.sources.items():
            assert digest((ROOT / source).read_bytes()) == expected, f"Source changed: {source}"
        return str(backup)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    migration = Migration()
    migration.build()
    summary = {
        "coordinate_basis": BASIS, "old_basis_determinant": -1, "new_basis_determinant": 1,
        "generated_mesh_files": len(migration.meshes),
        "triangles": sum(row["triangles"] for row in migration.meshes.values()),
        "unique_asset_ids": len(migration.assets), "source_files_unchanged": len(migration.sources),
        "animation_clip_modules": len(migration.clips), "pending_writes": len(migration.writes),
        "uv_values_changed": 0, "source_images_changed": 0, "uploads": 0,
    }
    if args.write and migration.writes:
        summary["backup"] = migration.apply()
        evidence = ROOT / "docs/evidence/local-mesh-basis-v2.json"
        evidence.parent.mkdir(parents=True, exist_ok=True)
        evidence.write_text(json.dumps({**summary, "generated_at": datetime.now(timezone.utc).isoformat(),
                                       "meshes": list(migration.meshes.values()),
                                       "source_sha256_after": migration.sources,
                                       "stage": "SOURCE_GEOMETRY_VERIFIED_RUNTIME_PENDING"}, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
