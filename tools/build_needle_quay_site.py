"""Assemble a local Blender visual review scene from authored asset sources."""
import bpy,json,math,xml.etree.ElementTree as ET
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1];O=R/'assets/production/needle-quay/site';O.mkdir(exist_ok=True)
D=json.loads((R/'data/needle-quay-environment.v1.json').read_text(encoding='utf-8'))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(rgb):
 m=bpy.data.materials.new('site');m.diffuse_color=(*rgb,1);m.use_nodes=True;bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*(pow(v,2.2) for v in rgb),1);bs.inputs['Roughness'].default_value=.85;return m
def box(name,size,pos,rgb):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat(rgb));return o
def name(e):return e.findtext('Properties/string[@name="Name"]','')
tree=ET.parse(R/'assets/blockouts/needle-quay/NeedleQuayEnvironmentBlockout.rbxmx')
for folder in tree.iter('Item'):
 if name(folder) not in ('GroundAndConnectedRoutes','Parking_4'):continue
 for p in folder.iter('Item'):
  if p.attrib.get('class')!='Part':continue
  s=p.find('Properties/Vector3[@name="size"]');c=p.find('Properties/CoordinateFrame[@name="CFrame"]');color=p.find('Properties/Color3[@name="Color"]')
  sz=[float(s.findtext(a)) for a in ('X','Z','Y')];pos=[float(c.findtext(a)) for a in ('X','Z','Y')];rgb=[float(color.findtext(a)) for a in ('R','G','B')];o=box(name(p),sz,pos,rgb)
  o.rotation_euler[2]=-math.atan2(float(c.findtext('R02','0')),float(c.findtext('R00','1')))
for b in D['buildings']:
 ident=b['id'];file=R/f'assets/production/needle-quay/models/{ident}/{ident}.blend'
 with bpy.data.libraries.load(str(file),link=False) as (src,dst):dst.objects=[n for n in src.objects if n not in ('Camera','Area')]
 x,z=b['blockout_center_xz_studs'];w,d,h=b['blockout_dimensions_wdh_studs']
 for o in dst.objects:
  if o is None or o.type!='MESH':continue
  bpy.context.collection.objects.link(o);o.location+=Vector((x-(w/2 if ident=='NQ-BLD-02' else 0),z-(d/2 if ident=='NQ-BLD-02' else 0),0))
 # Graphic remains separate from architecture, with explicit local placement.
 bpy.ops.mesh.primitive_plane_add(size=1,location=(x,z-d/2-.91,min(h-3,14)));o=bpy.context.object;o.name=b['sign_id'];o.rotation_euler[0]=math.pi/2;o.scale=(min(w-2,24),2,1)
 m=bpy.data.materials.new(b['sign_id']);m.use_nodes=True;tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(R/f"assets/production/needle-quay/graphics/{b['sign_id']}.png"));m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes['Principled BSDF'].inputs['Base Color']);o.data.materials.append(m)
box('LoopVan_LayoutProxy',(22,9,10),(-170,78,5),(.18,.36,.34))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12;scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(.45,.48,.43)
bpy.ops.object.light_add(type='SUN',location=(0,0,300));sun=bpy.context.object;sun.rotation_euler=(.4,-.5,-.4);sun.data.energy=2
bpy.ops.object.camera_add(location=(380,-450,390));cam=bpy.context.object;target=Vector((0,15,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=620;scene.camera=cam
bpy.ops.wm.save_as_mainfile(filepath=str(O/'NeedleQuayDistrict.blend'))
for state in ('before','after'):
 for o in bpy.context.scene.objects:
  if 'Amber' in o.name or 'LightInsert' in o.name:
   for m in o.data.materials:
    if m.use_nodes:
     bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Emission Color'].default_value=(.65,.3,.08,1);bs.inputs['Emission Strength'].default_value=1.5 if state=='after' else 0
 scene.render.filepath=str(O/(state+'.png'));bpy.ops.render.render(write_still=True)
cam.location=(0,0,600);cam.rotation_euler=(0,0,0);cam.data.ortho_scale=650;scene.render.filepath=str(O/'plan.png');bpy.ops.render.render(write_still=True)
(O/'README.md').write_text('# Local district visualization\n\nSource buildings and separate sign planes assembled at register coordinates. Before/After demonstrates shared geometry with switched amber inserts only. LoopVan is a layout proxy. Scene is a visual candidate, not a runtime restoration implementation or a replacement for the Rojo blockout. No uploads.\n')
