"""Build the small exact-geometry P05 wall shelf without provider spend."""
import bpy
import bmesh
import json
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/cleaned/P05"
OUT.mkdir(parents=True, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)


def srgb_to_linear(v):
    v /= 255.0
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def material(name, rgb, roughness=0.72):
    mat = bpy.data.materials.new(name)
    color = tuple(srgb_to_linear(c) for c in rgb) + (1.0,)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


walnut = material("P05 | Warm Walnut", (113, 73, 46), 0.78)
teal = material("P05 | Workshop Teal", (47, 92, 88), 0.72)
cream = material("P05 | Warm Cream Edge", (232, 216, 183), 0.68)
parts = []


def beveled_box(name, dims, loc, mat, bevel):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Softened board corners", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        mod.affect = "EDGES"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    parts.append(obj)
    return obj


def bracket(name, xcenter):
    half = 0.085
    # Solid triangular side gusset, all within the shelf's 1.5-stud depth.
    yz = [(-0.03, -0.20), (-1.22, -0.20), (-0.03, 0.27)]
    verts = [(xcenter - half, y, z) for y, z in yz] + [(xcenter + half, y, z) for y, z in yz]
    faces = [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)]
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(teal)
    bm = bmesh.new(); bm.from_mesh(mesh); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(mesh); bm.free()
    parts.append(obj)


# Rear mounting board lies on y=0; shelf projects toward the player along -Y.
beveled_box("P05_Wall_Backboard", (6.0, 0.10, 0.70), (0, -0.05, 0), teal, 0.045)
beveled_box("P05_Walnut_Shelf", (5.92, 1.53, 0.16), (0, -0.765, -0.27), walnut, 0.045)
beveled_box("P05_Cream_Front_Edge", (5.82, 0.035, 0.075), (0, -1.4825, -0.27), cream, 0.014)
bracket("P05_Left_Gusset", -2.10)
bracket("P05_Right_Gusset", 2.10)

# Join the static prop while keeping its distinct deterministic palette slots.
bpy.ops.object.select_all(action="DESELECT")
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
shelf = bpy.context.view_layer.objects.active
shelf.name = "P05_Wall_Shelf"
shelf.data.name = "P05_Wall_Shelf_Mesh"
# Fit the visible geometry to the exact depth and put the wall-contact plane on y=0.
rear_y = max(vertex.co.y for vertex in shelf.data.vertices)
front_y = min(vertex.co.y for vertex in shelf.data.vertices)
depth_scale = 1.5 / (rear_y - front_y)
for vertex in shelf.data.vertices:
    vertex.co.y = (vertex.co.y - rear_y) * depth_scale
shelf.data.update()
shelf.location = (0, 0, 0)
shelf.rotation_euler = (0, 0, 0)
shelf.scale = (1, 1, 1)
shelf["asset_id"] = "P05"
shelf["stage"] = "DCC-exact candidate"
shelf["dimensions_game_xyz"] = "6 x 0.7 x 1.5"
shelf["dimensions_blender_xyz"] = "6 x 1.5 x 0.7"
shelf["pivot"] = "rear-center at wall-facing plane y=0"
shelf["front"] = "-Y in Blender scene; -Z in Roblox glTF convention"

bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "P05_wall_shelf.blend"))
bpy.ops.object.select_all(action="DESELECT"); shelf.select_set(True); bpy.context.view_layer.objects.active = shelf
bpy.ops.export_scene.gltf(filepath=str(OUT / "P05_wall_shelf.glb"), export_format="GLB", export_materials="EXPORT", export_yup=True, export_apply=True, use_selection=True)

# Neutral rendered preview, kept outside the exported mesh.
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.render.resolution_x = 900; scene.render.resolution_y = 600; scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"; scene.render.film_transparent = True
if scene.world is None: scene.world = bpy.data.worlds.new("P05_Preview_World")
scene.world.color = (0.12, 0.13, 0.14)
scene.display.shading.light = "STUDIO"; scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True; scene.display.shading.cavity_type = "BOTH"
scene.display.shading.color_type = "MATERIAL"; scene.display.shading.background_type = "WORLD"
camdata = bpy.data.cameras.new("P05_Preview_Camera")
camera = bpy.data.objects.new("P05_Preview_Camera", camdata); scene.collection.objects.link(camera)
camera.location = (2.4, -5.6, 1.7); camdata.type = "ORTHO"; camdata.ortho_scale = 8.2
target = Vector((0, -0.7, 0)); camera.rotation_euler = (target-camera.location).to_track_quat("-Z", "Y").to_euler()
scene.camera = camera; scene.render.filepath = str(OUT / "preview.png"); bpy.ops.render.render(write_still=True)

triangles = sum(len(face.vertices) - 2 for face in shelf.data.polygons)
print(json.dumps({"asset_id":"P05","source":"deterministic Blender construction","glb":"assets/cleaned/P05/P05_wall_shelf.glb","blend":"assets/cleaned/P05/P05_wall_shelf.blend","preview":"assets/cleaned/P05/preview.png","dimensions_game_xyz":[6,0.7,1.5],"dimensions_blender_xyz":[6,1.5,0.7],"pivot":"rear-center at wall-facing plane y=0","front":"-Y Blender; -Z Roblox","mesh_objects":1,"triangles":triangles,"materials":[m.name for m in shelf.data.materials],"uv_layers":[u.name for u in shelf.data.uv_layers],"stage":"DCC-exact candidate; art review and Roblox Studio/runtime validation pending"},indent=2))
