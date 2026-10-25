"""Blender-authored sunset cubemap for the local artbook lighting pass."""
import bpy,math,json,hashlib
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1];O=R/'assets/production/needle-quay/sky';O.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
world=bpy.data.worlds.new('Quay sunset');world.use_nodes=True;scene.world=world
n=world.node_tree.nodes;l=world.node_tree.links;sky=n.new('ShaderNodeTexSky');sky.sky_type='MULTIPLE_SCATTERING'
sky.sun_elevation=math.radians(5);sky.sun_rotation=math.radians(115);sky.sun_disc=False
sky.air_density=1.3;sky.aerosol_density=2.3;sky.ozone_density=1.4
coords=n.new('ShaderNodeTexCoord');stretch=n.new('ShaderNodeVectorMath');stretch.operation='MULTIPLY';stretch.inputs[1].default_value=(3,3,9);l.new(coords.outputs['Normal'],stretch.inputs[0])
noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=2;noise.inputs['Detail'].default_value=4;noise.inputs['Roughness'].default_value=.65;l.new(stretch.outputs[0],noise.inputs['Vector'])
mask=n.new('ShaderNodeValToRGB');mask.color_ramp.elements[0].position=.48;mask.color_ramp.elements[1].position=.68;l.new(noise.outputs['Fac'],mask.inputs['Fac'])
cloud=n.new('ShaderNodeValToRGB');cloud.color_ramp.elements[0].position=.3;cloud.color_ramp.elements[0].color=(.27,.16,.31,1);cloud.color_ramp.elements[1].position=.72;cloud.color_ramp.elements[1].color=(1,.55,.28,1);l.new(noise.outputs['Fac'],cloud.inputs['Fac'])
mix=n.new('ShaderNodeMixRGB');l.new(mask.outputs['Color'],mix.inputs[0]);l.new(sky.outputs['Color'],mix.inputs[1]);l.new(cloud.outputs['Color'],mix.inputs[2]);l.new(mix.outputs['Color'],n.get('Background').inputs['Color']);n.get('Background').inputs['Strength'].default_value=.55
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='PERSP';camera.data.lens=18;camera.data.sensor_width=36
faces={'rt':(1,0,0),'lf':(-1,0,0),'ft':(0,-1,0),'bk':(0,1,0),'up':(0,0,1),'dn':(0,0,-1)}
for name,direction in faces.items():
 camera.rotation_euler=Vector(direction).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(O/'QuaySunset.blend'))
(O/'provenance.json').write_text(json.dumps({'generator':'tools/build_quay_sunset.py','route':'Blender Nishita sunset with seamless world-space procedural peach/lavender cloud field, no external images','uploaded':False,'faces':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob('*.png')}},indent=2))
