"""Blender-only intake: preserve geometry, measure, and render supplied building candidates."""
import bpy, json, math
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/supplied/buildings/set-01'
OUT = ROOT / 'assets/production/needle-quay/building-intake-set-01'
OUT.mkdir(parents=True, exist_ok=True)
records = []
for entry in json.loads((BASE / 'provenance.json').read_text(encoding='utf-8'))['assets']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / entry['file']))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    points = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
    lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    center = (lo + hi) / 2
    span = max(hi - lo)
    textures = [{'name': i.name, 'size': list(i.size), 'packed': bool(i.packed_file)} for i in bpy.data.images if i.type == 'IMAGE']
    record = dict(entry, meshes=len(meshes), triangles=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons), materials=len(bpy.data.materials), textures=textures, dimensions_xyz=list(hi-lo), bounds_min=list(lo), bounds_max=list(hi), blender=bpy.app.version_string)
    for image in bpy.data.images:
        if image.type == 'IMAGE':
            try: image.pack()
            except RuntimeError: pass
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / (entry['id'] + '.blend')))
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 12
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 560
    scene.render.resolution_y = 560
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('Neutral inspection')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (.24,.24,.24,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .65
    scene.view_settings.view_transform = 'AgX'
    bpy.ops.object.light_add(type='AREA', location=center + Vector((span,-span,span*1.8)))
    light = bpy.context.object
    light.data.energy = 160 * span * span
    light.data.shape = 'DISK'
    light.data.size = span * 1.5
    light.rotation_euler = (center-light.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=center+Vector((span*.85,-span*1.8,span*.85)))
    camera = bpy.context.object
    camera.rotation_euler = (center-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = span*1.5
    camera.data.clip_end = max(1000,span*10)
    scene.camera = camera
    scene.render.image_settings.file_format = 'PNG'
    scene.render.filepath = str(OUT/(entry['id']+'.png'))
    bpy.ops.render.render(write_still=True)
    records.append(record)
    (OUT/'inspection.json').write_text(json.dumps({'stage':'candidate - Blender intake only','assets':records},indent=2),encoding='utf-8')
print('INTAKE COMPLETE',len(records))
