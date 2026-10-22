"""Blender: preserve accepted geometry/part boundaries; consolidate material draws.

New UVs explicitly target FZ_MaterialAtlas_v1. Static dressing is grouped while
functional/moving parts remain independent. Do not run this on raw Tripo files.
Outputs are new textured variants, not replacements for human-approved sources.
"""
import bpy
import contextlib
import hashlib
import io
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
MATERIALS = ROOT / "assets/production/materials"
LAYOUT = json.loads((MATERIALS / "layout.json").read_text())
SLOTS = LAYOUT["slots"]


def choose_slot(material):
    if material is None:
        return 0
    name = material.name.lower()
    for terms, slot in [(("rubber", "pad", "tire", "tread"), 11), (("wood", "walnut", "timber"), 5),
                        (("leaf", "leaves", "foliage"), 9), (("fabric", "canvas", "weave"), 10),
                        (("glass", "amber", "emiss", "light"), 4), (("baremetal", "steel", "chrome"), 8),
                        (("coral",), 3), (("cream",), 2), (("graphite", "dark"), 7),
                        (("teal",), 0), (("stone", "sand"), 6)]:
        if any(term in name for term in terms):
            return slot
    color = list(material.diffuse_color[:3])
    if material.use_nodes:
        node = next((n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if node:
            color = list(node.inputs["Base Color"].default_value[:3])
    return min(range(8), key=lambda i: sum((color[c] * 255 - SLOTS[i]["color"][c]) ** 2 for c in range(3)))


def authored_region(aid, face, low, span):
    """Explicit new color-zone proposals for geometry-only Material_0 sources.

    Coordinates are Blender width/depth/height; the reviewed front faces -Y.
    These regions are not inferred texture data or inherited art approval.
    """
    x, y, z = [(face.center[i] - low[i]) / span[i] for i in range(3)]
    if aid == "H02":
        if y < .24 and ((.13 < z < .60 and .13 < x < .87) or (.69 < z < .94 and .18 < x < .82)): return 7
        if x < .055 or x > .945 or z < .035 or z > .965: return 2
        return 0
    if aid == "H03": return 5
    if aid == "H04":
        if z < .20: return 11
        if z > .64:
            if y < .30 and .76 < z < .84 and (.22 < x < .43 or .57 < x < .78): return 7
            return 2
        if x < .17 or x > .83: return 2
        if y < .18 and .33 < z < .56: return 2
        return 0
    if aid == "H05":
        if z > .94: return 2
        if z > .80 and y < .50: return 4
        return 0
    if aid == "P01": return 5 if z > .74 else 0
    if aid == "P02": return 5 if z > .74 else 7
    if aid in ("P03", "P04", "P06"): return 5
    if aid == "P07":
        if z > .72: return 0
        if z > .56: return 2
        return 11
    if aid == "P11": return 0 if z > .88 else 12
    if aid == "P16": return 7 if y < .20 and z > .46 else 0
    return None


def material(size):
    suffix = "_512" if size == 512 else ""
    mat = bpy.data.materials.new("FZ_SharedAtlas_v1")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    shader = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    for name, path, target, noncolor in (
        ("BaseColor", MATERIALS / "sets/quay" / ("atlas_basecolor" + suffix + ".png"), "Base Color", False),
        ("Roughness", MATERIALS / "shared" / ("atlas_roughness" + suffix + ".png"), "Roughness", True),
        ("Metalness", MATERIALS / "shared" / ("atlas_metalness" + suffix + ".png"), "Metallic", True),
    ):
        texture = nodes.new("ShaderNodeTexImage")
        texture.name = name
        texture.image = bpy.data.images.load(str(path))
        texture.image.colorspace_settings.name = "Non-Color" if noncolor else "sRGB"
        links.new(texture.outputs["Color"], shader.inputs[target])
    return mat


def measure(meshes):
    points = [obj.matrix_world @ Vector(v) for obj in meshes for v in obj.bound_box]
    return {
        "triangles": sum(sum(len(p.vertices) - 2 for p in obj.data.polygons) for obj in meshes),
        "mesh_objects": len(meshes),
        "material_primitives": sum(len({p.material_index for p in obj.data.polygons}) for obj in meshes),
        "bounds_min": [min(v[i] for v in points) for i in range(3)],
        "bounds_max": [max(v[i] for v in points) for i in range(3)],
    }


def group_parts(aid, meshes):
    groups = {}
    for obj in meshes:
        name = obj.name
        group = name
        if aid == "P12": group = "P12_PlantCluster"
        elif aid == "P13": group = "P13_Diffuser" if "Diffuser" in name else "P13_StaticBody"
        elif aid == "P14":
            group = "P14_StatusInsert" if "Status_Insert" in name else "P14_Socket" if "Socket" in name else "P14_StaticBody"
        elif aid == "I01": group = "I01_SwingingSign" if "Swinging" in name else "I01_FixedMount"
        elif aid == "I04":
            group = name if ("Indicator" in name and "Lens" in name) or "Teal_Knob" in name else "I04_StaticBody"
        elif aid == "I05":
            group = name if "Dial_Knob" in name or "Status_Lens" in name or "Status_Insert" in name else "I05_StaticBody"
        groups.setdefault(group, []).append(obj)
    membership = {name: [o.name for o in objects] for name, objects in groups.items()}
    for name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects: obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1: bpy.ops.object.join()
        bpy.context.view_layer.objects.active.name = name
    return [o for o in bpy.context.scene.objects if o.type == "MESH"], membership


def preview(output, meshes):
    for obj in meshes:
        for mat in obj.data.materials:
            if mat and mat.use_nodes:
                shader = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
                if shader and shader.inputs["Base Color"].is_linked:
                    mat.node_tree.nodes.active = shader.inputs["Base Color"].links[0].from_node
    values = measure(meshes)
    low, high = Vector(values["bounds_min"]), Vector(values["bounds_max"])
    center = (low + high) * .5
    span = max(high - low)
    camera = bpy.data.objects.new("ReviewCamera", bpy.data.cameras.new("ReviewCamera"))
    bpy.context.scene.collection.objects.link(camera)
    camera.location = center + Vector((span * .9, -span * 2.4, span * 1.3))
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = span * 1.45
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 384
    scene.render.resolution_y = 384
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(output.with_suffix(".png"))
    with contextlib.redirect_stdout(io.StringIO()): bpy.ops.render.render(write_still=True)


def build(asset):
    aid = asset["id"]
    src = ROOT / asset["dcc_candidate"]
    output = ROOT / "assets/optimized" / aid / (aid + "_atlas_v1.glb")
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    with contextlib.redirect_stdout(io.StringIO()):
        bpy.ops.import_scene.gltf(filepath=str(src))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    before = measure(meshes)
    size = min(1024, asset.get("texture_cap_px") or 512)
    shared = material(size)
    mapping = {}
    for obj in meshes:
        mesh = obj.data
        indices = [choose_slot(m) for m in mesh.materials]
        generic = [m is None or m.name.startswith("Material_") for m in mesh.materials]
        for mat, slot in zip(mesh.materials, indices):
            mapping[mat.name if mat else "unassigned"] = SLOTS[slot]["name"]
        uv = mesh.uv_layers.active or mesh.uv_layers.new(name="AtlasUV")
        uv.name = "AtlasUV"
        low = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
        span = [max(max(v.co[i] for v in mesh.vertices) - low[i], .0001) for i in range(3)]
        for face in mesh.polygons:
            slot = indices[face.material_index] if face.material_index < len(indices) else 0
            if face.material_index < len(generic) and generic[face.material_index]:
                region = authored_region(aid, face, low, span)
                if region is not None: slot = region
            dominant = max(range(3), key=lambda i: abs(face.normal[i]))
            axes = [i for i in range(3) if i != dominant]
            col, row = slot % 4, slot // 4
            for loop in face.loop_indices:
                co = mesh.vertices[mesh.loops[loop].vertex_index].co
                u, v = [(co[axis] - low[axis]) / span[axis] for axis in axes]
                # Eight-pixel inset in 256px source tiles keeps mip bleed away.
                uv.data[loop].uv = ((col + .03125 + u * .9375) / 4, (3 - row + .03125 + v * .9375) / 4)
            face.material_index = 0
        mesh.materials.clear()
        mesh.materials.append(shared)
        obj["TextureLayout"] = "FZ_MaterialAtlas_v1"
        obj["MaterialSet"] = "quay"
        obj["AssetId"] = aid
        obj["TextureResolution"] = size
    meshes, membership = group_parts(aid, meshes)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    with contextlib.redirect_stdout(io.StringIO()):
        bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", use_selection=True,
                                  export_apply=True, export_extras=True, export_materials="EXPORT")
    # Validate the actual exported file, not just the working Blender scene.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    with contextlib.redirect_stdout(io.StringIO()):
        bpy.ops.import_scene.gltf(filepath=str(output))
    imported = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    after = measure(imported)
    assert before["triangles"] == after["triangles"], aid + ": geometry changed"
    assert len(membership) == after["mesh_objects"], aid + ": functional grouping changed"
    assert all(abs(before[key][i] - after[key][i]) < .001 for key in ("bounds_min", "bounds_max") for i in range(3)), aid + ": bounds changed"
    assert after["triangles"] <= asset["full_asset_triangle_budget"], aid + ": triangle cap"
    images = [{"name": im.name, "size": list(im.size)} for im in bpy.data.images if im.type == "IMAGE" and im.size[0] > 0]
    assert all(max(im["size"]) <= size for im in images), aid + ": texture cap"
    preview(output, imported)
    return {"id": aid, "source": src.relative_to(ROOT).as_posix(), "source_sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
            "output": output.relative_to(ROOT).as_posix(), "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
            "bytes": output.stat().st_size, "before": before, "after": after, "texture_size": size,
            "images": images, "slot_mapping": mapping, "texture_layout": "FZ_MaterialAtlas_v1",
            "part_groups": membership, "preview": output.with_suffix(".png").relative_to(ROOT).as_posix(),
            "review": "New textured variant: static Blender re-import checked; visual/Studio/runtime acceptance pending."}


assets = json.loads((ROOT / "data/assets.json").read_text(encoding="utf-8"))["assets"]
results = [build(a) for a in assets if a.get("dcc_candidate")]
report = {"blender": bpy.app.version_string, "policy": "No decimation; preserve geometry, bounds, functional parts and accepted source files. Static dressing grouped; new planar atlas UVs and one material per MeshPart. Workbench previews inspect color/UVs, not PBR lighting.",
          "assets": results,
          "totals": {"triangles": sum(r["after"]["triangles"] for r in results),
                     "before_material_primitives": sum(r["before"]["material_primitives"] for r in results),
                     "before_mesh_objects": sum(r["before"]["mesh_objects"] for r in results),
                     "after_mesh_objects": sum(r["after"]["mesh_objects"] for r in results),
                     "after_material_primitives": sum(r["after"]["material_primitives"] for r in results)}}
dest = ROOT / "docs/evidence/optimized-assets.json"
dest.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report["totals"]))
