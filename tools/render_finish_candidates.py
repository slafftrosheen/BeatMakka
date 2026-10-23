"""Blender background-only neutral inspection of existing candidate geometry.

No mesh export, source edits, GPU use, foreground window or uploads.
Usage: blender --background --threads 2 --python tools/render_finish_candidates.py
"""
import hashlib
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
candidate = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'tactile-v1'
assert candidate in ('tactile-v1', 'assets-folder-v1')
asset = sys.argv[sys.argv.index('--')+2] if '--' in sys.argv and len(sys.argv) > sys.argv.index('--')+2 else 'H01'
assert asset in ('H01', 'P01')
OUT = ROOT / ('docs/evidence/a01-07/neutral' if candidate == 'tactile-v1' else 'docs/evidence/a01-07-assets/neutral')
if asset != 'H01':
    OUT = OUT / asset
MAPS = ROOT / 'assets/candidates/materials' / candidate
SOURCE = ROOT / 'assets/optimized' / asset / f'{asset}_atlas_v1.glb'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
points = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
low = Vector([min(p[i] for p in points) for i in range(3)])
high = Vector([max(p[i] for p in points) for i in range(3)])
center, span = (low + high) / 2, max(high - low)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 12
scene.render.threads_mode = 'FIXED'
scene.render.threads = 2
scene.render.resolution_x = scene.render.resolution_y = 384
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.world = bpy.data.worlds.new('NeutralWorld')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.18, 0.18, 0.18, 1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.7
scene.view_settings.view_transform = 'AgX'
for name, position, energy, size in [('Key', (-1,-2,3), 700, 5), ('Fill', (2,1,2), 400, 4)]:
    data = bpy.data.lights.new(name, 'AREA')
    data.energy, data.shape, data.size = energy, 'DISK', size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = center + Vector(position) * span
    obj.rotation_euler = (center - obj.location).to_track_quat('-Z','Y').to_euler()
cam_data = bpy.data.cameras.new('ReviewCamera')
cam_data.type, cam_data.ortho_scale = 'ORTHO', span * 1.45
cam = bpy.data.objects.new('ReviewCamera', cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
mat = bpy.data.materials.new('CandidatePBR')
mat.use_nodes = True
nodes, links = mat.node_tree.nodes, mat.node_tree.links
bsdf = nodes.get('Principled BSDF')
color = nodes.new('ShaderNodeTexImage')
rough = nodes.new('ShaderNodeTexImage')
metal = nodes.new('ShaderNodeTexImage')
rough.image = bpy.data.images.load(str(MAPS/'shared/atlas_roughness.png'))
metal.image = bpy.data.images.load(str(MAPS/'shared/atlas_metalness.png'))
rough.image.colorspace_settings.name = metal.image.colorspace_settings.name = 'Non-Color'
links.new(color.outputs['Color'], bsdf.inputs['Base Color'])
links.new(rough.outputs['Color'], bsdf.inputs['Roughness'])
links.new(metal.outputs['Color'], bsdf.inputs['Metallic'])
for obj in objects:
    obj.data.materials.clear()
    obj.data.materials.append(mat)
views = {'front': (1,-1.5,1.2), 'rear': (-1,1.5,0.9)}
for finish in ['quay','chalk','coral','afterhours']:
    color.image = bpy.data.images.load(str(MAPS/'sets'/finish/'atlas_basecolor.png'))
    for name, direction in views.items():
        cam.location = center + Vector(direction).normalized() * span * 3
        cam.rotation_euler = (center - cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath = str(OUT / f'{finish}-{name}.png')
        bpy.ops.render.render(write_still=True)
(OUT/'receipt.json').write_text(json.dumps({
    'stage': 'candidate neutral inspection; no art approval or Studio import',
    'blender': bpy.app.version_string, 'engine': 'Cycles CPU, 12 samples, 2 threads',
    'source': str(SOURCE.relative_to(ROOT)).replace('\\','/'),
    'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'geometry_exported': False, 'views': list(views), 'finishes': 4,
    'candidate': candidate, 'asset': asset,
    'limitations': 'Geometry-only material review; deterministic controls are separate. Shared UVs cannot author per-object edge wear. Neutral review does not establish dusk, gameplay-distance or human acceptance.',
},indent=2)+'\n',encoding='utf-8')
