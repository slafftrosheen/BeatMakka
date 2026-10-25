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
l.new(sky.outputs['Color'],n.get('Background').inputs['Color']);n.get('Background').inputs['Strength'].default_value=.35
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='PERSP';camera.data.lens=18;camera.data.sensor_width=36
faces={'rt':(1,0,0),'lf':(-1,0,0),'ft':(0,-1,0),'bk':(0,1,0),'up':(0,0,1),'dn':(0,0,-1)}
for name,direction in faces.items():
 camera.rotation_euler=Vector(direction).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(O/'QuaySunset.blend'))
(O/'provenance.json').write_text(json.dumps({'generator':'tools/build_quay_sunset.py','route':'Blender Nishita physically authored sunset, no external images','uploaded':False,'faces':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob('*.png')}},indent=2))
