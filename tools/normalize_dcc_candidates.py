"""Normalize approved Tripo geometry candidates to project dimensions in Blender.

Raw provider files are read-only inputs. The export target dimensions use Blender
Z-up scene axes [width, depth, height]; glTF export writes the normal Y-up file.
"""
import bpy
import bmesh
import json
import math
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SPECS = {
    # asset_id: (source path, width, depth, height, quarter-turn yaw)
    "H02": ("assets/candidates/tripo-out/b04-h02-compact-speaker-stack-090d3674/model.glb", 4.0, 3.0, 8.0, -90),
    "H03": ("assets/candidates/tripo-out/b05-h03-vinyl-crate-shell-0959611a/model.glb", 3.0, 3.0, 2.5, -90),
    "H04": ("assets/candidates/tripo-out/b06-h04-maintenance-helper-robot-d452487b/model.glb", 3.5, 3.0, 4.0, -90),
    "H05": ("assets/candidates/dcc-source/H05_base_repaired_unscaled.glb", 2.5, 3.0, 12.0, 0),
    "P01": ("assets/candidates/tripo-out/b07-p01-studio-workbench-8fc6650b/model.glb", 8.0, 4.0, 3.5, -90),
    "P02": ("assets/candidates/tripo-out/b08-p02-round-workshop-stool-3c9288ec/model.glb", 2.5, 2.5, 3.0, 0),
    "P03": ("assets/candidates/tripo-out/b09-p03-listening-bench-a484dfae/model.glb", 7.0, 2.5, 3.5, -90),
    "P04": ("assets/candidates/tripo-out/b10-p04-record-browsing-bin-c79fb1fa/model.glb", 5.0, 3.0, 3.5, -90),
}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def local_bounds(mesh_objects):
    points = [obj.matrix_world @ vertex.co for obj in mesh_objects for vertex in obj.data.vertices]
    mins = [min(point[i] for point in points) for i in range(3)]
    maxs = [max(point[i] for point in points) for i in range(3)]
    return mins, maxs, [maxs[i] - mins[i] for i in range(3)]


def make_preview(mesh_objects, path, height):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = True
    if scene.world is None:
        scene.world = bpy.data.worlds.new("DCC_Preview_World")
    scene.world.color = (0.12, 0.13, 0.14)
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.display.shading.cavity_type = "BOTH"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.background_type = "WORLD"
    target = Vector((0, 0, height * 0.5))
    span = max(height, max(local_bounds(mesh_objects)[2]))
    camera_data = bpy.data.cameras.new("DCC_Preview_Camera")
    camera = bpy.data.objects.new("DCC_Preview_Camera", camera_data)
    scene.collection.objects.link(camera)
    camera.location = (span * 0.55, -span * 2.3, height * 1.2)
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = max(span * 1.35, 1.0)
    scene.camera = camera
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def normalize(asset_id):
    source_rel, width, depth, height, yaw_degrees = SPECS[asset_id]
    source = ROOT / source_rel
    out_dir = ROOT / "assets" / "cleaned" / asset_id
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = {
        "H02": "H02_compact_speaker_stack",
        "H03": "H03_vinyl_crate_shell",
        "H04": "H04_maintenance_helper_robot",
        "H05": "H05_curved_street_lamp_scaled",
        "P01": "P01_studio_workbench",
        "P02": "P02_round_workshop_stool",
        "P03": "P03_listening_bench",
        "P04": "P04_record_browsing_bin",
    }[asset_id]
    out_glb = out_dir / f"{stem}.glb"
    out_blend = out_dir / f"{stem}.blend"
    preview = out_dir / ("preview_scaled.png" if asset_id == "H05" else "preview.png")

    reset_scene()
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"{asset_id}: no mesh objects in {source}")
    if any(len(obj.data.vertices) == 0 for obj in meshes):
        raise RuntimeError(f"{asset_id}: empty mesh in source")

    # Bake the importer-applied Y-up transforms before changing axes or dimensions.
    for mesh in meshes:
        bpy.ops.object.select_all(action="DESELECT")
        mesh.select_set(True)
        bpy.context.view_layer.objects.active = mesh
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Join source mesh objects only after their transforms have been baked.
    bpy.ops.object.select_all(action="DESELECT")
    for mesh in meshes:
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = f"{asset_id}_Geometry"
    obj.data.name = f"{asset_id}_Geometry_Mesh"

    yaw = math.radians(yaw_degrees)
    cos_yaw, sin_yaw = math.cos(yaw), math.sin(yaw)
    points = []
    for vertex in obj.data.vertices:
        x, y, z = vertex.co
        points.append(Vector((cos_yaw * x - sin_yaw * y, sin_yaw * x + cos_yaw * y, z)))
    mins = [min(point[i] for point in points) for i in range(3)]
    maxs = [max(point[i] for point in points) for i in range(3)]
    source_dimensions = [maxs[i] - mins[i] for i in range(3)]
    if min(source_dimensions) <= 1e-8:
        raise RuntimeError(f"{asset_id}: degenerate source bounds {source_dimensions}")
    target_dimensions = [width, depth, height]
    scales = [target_dimensions[i] / source_dimensions[i] for i in range(3)]

    transformed = [Vector((p.x * scales[0], p.y * scales[1], p.z * scales[2])) for p in points]
    mins = [min(point[i] for point in transformed) for i in range(3)]
    maxs = [max(point[i] for point in transformed) for i in range(3)]
    center_x = (mins[0] + maxs[0]) * 0.5
    center_y = (mins[1] + maxs[1]) * 0.5
    for vertex, point in zip(obj.data.vertices, transformed):
        vertex.co = (point.x - center_x, point.y - center_y, point.z - mins[2])
    obj.data.update()
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = (0.0, 0.0, 0.0)
    obj.rotation_euler = (0.0, 0.0, 0.0)
    obj.scale = (1.0, 1.0, 1.0)
    obj["asset_id"] = asset_id
    obj["stage"] = "DCC-clean candidate"
    obj["dimensions_game_xyz"] = f"{width:g} x {height:g} x {depth:g}"
    obj["dimensions_blender_xyz"] = f"{width:g} x {depth:g} x {height:g}"
    obj["pivot"] = "floor-center at object origin"
    obj["yaw_degrees_applied"] = yaw_degrees

    # Store an editable Blender source before adding preview-only camera and lights.
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(out_glb), export_format="GLB", export_materials="EXPORT",
        export_yup=True, export_apply=True, use_selection=True,
    )
    make_preview([obj], preview, height)
    triangulate_count = sum(len(face.vertices) - 2 for face in obj.data.polygons)
    return {
        "asset_id": asset_id,
        "source": source.relative_to(ROOT).as_posix(),
        "cleaned_glb": out_glb.relative_to(ROOT).as_posix(),
        "editable_source": out_blend.relative_to(ROOT).as_posix(),
        "preview": preview.relative_to(ROOT).as_posix(),
        "yaw_degrees_applied": yaw_degrees,
        "source_bounds_after_orientation": [round(value, 6) for value in source_dimensions],
        "scale_applied": [round(value, 6) for value in scales],
        "target_blender_bounds_xyz": target_dimensions,
        "target_game_dimensions_xyz": [width, height, depth],
        "pivot": "floor-center at object origin; geometry minimum Z=0",
        "triangles": triangulate_count,
        "mesh_objects": 1,
        "materials": [mat.name for mat in obj.data.materials if mat],
        "uv_layers": [uv.name for uv in obj.data.uv_layers],
        "stage": "DCC-clean geometry candidate; art and Studio/runtime acceptance pending",
    }


asset_ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if not asset_ids:
    raise SystemExit("Pass one or more IDs after --, for example: H02 H03")
unknown = [asset_id for asset_id in asset_ids if asset_id not in SPECS]
if unknown:
    raise SystemExit(f"Unknown asset IDs: {unknown}")
results = [normalize(asset_id) for asset_id in asset_ids]
print(json.dumps(results, indent=2))
