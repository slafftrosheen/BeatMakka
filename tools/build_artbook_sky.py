"""Project the generated artbook panorama into local cubemap faces in Blender.

No image synthesis or cloud noise here: the authored panorama is the source.
The earlier procedural sky and its Blender source remain preserved.
"""
import bpy
import hashlib
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/production/needle-quay/sky-artbook'
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 1
scene.render.resolution_x = scene.render.resolution_y = 1024
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'Standard'
world = bpy.data.worlds.new('Approved board sunset panorama')
world.use_nodes = True
scene.world = world
nodes, links = world.node_tree.nodes, world.node_tree.links
env = nodes.new('ShaderNodeTexEnvironment')
env.image = bpy.data.images.load(str(OUT / 'panorama.png'))
env.image.pack()
env.projection = 'EQUIRECTANGULAR'
links.new(env.outputs['Color'], nodes.get('Background').inputs['Color'])
nodes.get('Background').inputs['Strength'].default_value = 1
bpy.ops.object.camera_add()
camera = bpy.context.object
camera.data.lens, camera.data.sensor_width = 18, 36
scene.camera = camera
for name, direction in {'rt': (1,0,0), 'lf': (-1,0,0), 'ft': (0,-1,0),
                        'bk': (0,1,0), 'up': (0,0,1), 'dn': (0,0,-1)}.items():
    camera.rotation_euler = Vector(direction).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(OUT / (name + '.png'))
    bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'NeedleQuayArtbookSky.blend'))
receipt = json.loads((OUT / 'provenance.json').read_text())
receipt['projection'] = 'Blender environment projection, 90 degree cube faces; no procedural cloud field'
receipt['generator'] = 'tools/build_artbook_sky.py'
receipt['faces'] = {name: hashlib.sha256((OUT/name).read_bytes()).hexdigest()
                    for name in ['rt.png','lf.png','ft.png','bk.png','up.png','dn.png']}
(OUT / 'provenance.json').write_text(json.dumps(receipt, indent=2))
