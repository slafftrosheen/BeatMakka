"""Blender: preserve a Tripo candidate, normalize scale and author a local R15 rig.

The source keeps smooth skin weights; the offline Studio mesh route uses dominant
triangle bone groups for restrained idle animation. This is not final rig acceptance.
"""
import bpy, json, math, sys, argparse, hashlib
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--slug',required=True);p.add_argument('--model',required=True);p.add_argument('--height',type=float,required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);slug=a.slug.lower();ident='NQ-NPC-'+a.slug.upper();height=a.height
source=ROOT/a.model;out=ROOT/'assets/production/needle-quay/models/refined';out.mkdir(parents=True,exist_ok=True)
maps=ROOT/'assets/production/needle-quay/character-maps';maps.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
# Provider front is +X; authored district characters face -Y in Blender.
rotation=Matrix.Rotation(-math.pi/2,4,'Z')
points=[rotation@o.matrix_world@v.co for o in objects for v in o.data.vertices]
lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)))
scale=height/(hi.z-lo.z);offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
for o in objects:
 transform=rotation@o.matrix_world
 for v in o.data.vertices:v.co=(transform@v.co-offset)*scale
 o.matrix_world=Matrix.Identity(4)
 o.data.update()
 for poly in o.data.polygons:poly.use_smooth=True
for o in objects:
 for material in o.data.materials:
  material.diffuse_color=(1,1,1,1)
  for node in material.node_tree.nodes:
   if node.type!='TEX_IMAGE' or not node.image:continue
   im=node.image
   if 'base_color' in im.name:
    im.scale(1024,1024);im.filepath_raw=str(maps/(slug+'_color.png'));im.file_format='PNG';im.save();im.pack()
   elif 'normal' in im.name:
    im.scale(512,512);im.filepath_raw=str(maps/(slug+'_normal.png'));im.file_format='PNG';im.save();im.pack()
   elif 'roughness' in im.name:
    im.scale(512,512);pixels=list(im.pixels[:]);rough=bpy.data.images.new(slug+'_rough',512,512)
    for i in range(0,len(pixels),4):pixels[i:i+4]=[pixels[i+1],pixels[i+1],pixels[i+1],1]
    rough.pixels=pixels;rough.filepath_raw=str(maps/(slug+'_rough.png'));rough.file_format='PNG';rough.save();rough.pack()

segments={'LowerTorso':((0,0,.46),(0,0,.58)), 'UpperTorso':((0,0,.58),(0,0,.76)), 'Head':((0,0,.76),(0,0,.98))}
for sign,side in ((-1,'Left'),(1,'Right')):
 segments.update({side+'UpperArm':((sign*.135,0,.71),(sign*.205,0,.57)),side+'LowerArm':((sign*.205,0,.57),(sign*.258,-.01,.46)),side+'Hand':((sign*.258,-.01,.46),(sign*.27,-.01,.40)),side+'UpperLeg':((sign*.08,0,.46),(sign*.085,0,.26)),side+'LowerLeg':((sign*.085,0,.26),(sign*.085,0,.085)),side+'Foot':((sign*.085,0,.085),(sign*.085,-.08,.035))})
segments={k:(Vector(x)*height,Vector(y)*height) for k,(x,y) in segments.items()}
data=bpy.data.armatures.new(ident+'_R15');rig=bpy.data.objects.new(ident+'_R15',data);bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,(head,tail) in segments.items():
 bone=data.edit_bones.new(name);bone.head=head;bone.tail=tail
for bone in data.edit_bones:
 name=bone.name;parent=None
 if name=='UpperTorso':parent='LowerTorso'
 elif name=='Head':parent='UpperTorso'
 elif 'UpperArm' in name:parent='UpperTorso'
 elif 'LowerArm' in name:parent=name.replace('LowerArm','UpperArm')
 elif 'Hand' in name:parent=name.replace('Hand','LowerArm')
 elif 'UpperLeg' in name:parent='LowerTorso'
 elif 'LowerLeg' in name:parent=name.replace('LowerLeg','UpperLeg')
 elif 'Foot' in name:parent=name.replace('Foot','LowerLeg')
 if parent:bone.parent=data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
def distance(v,segment):
 start,end=segment;delta=end-start;t=max(0,min(1,(v-start).dot(delta)/delta.length_squared));return (v-(start+t*delta)).length
for o in objects:
 groups={n:o.vertex_groups.new(name=n) for n in segments}
 for v in o.data.vertices:
  z=v.co.z/height;x=abs(v.co.x)/height
  if z>.775:names=['Head']
  elif z<.46 and x<.16:names=[n for n in segments if 'Leg' in n or 'Foot' in n or n=='LowerTorso']
  elif x>.145 and z<.74:names=[n for n in segments if 'Arm' in n or 'Hand' in n]
  else:names=['UpperTorso','LowerTorso','Head']
  nearest=sorted(names,key=lambda n:distance(v.co,segments[n]))[:2]
  weights=[1/max(.015*height,distance(v.co,segments[n]))**4 for n in nearest];total=sum(weights)
  for name,weight in zip(nearest,weights):groups[name].add([v.index],weight/total,'REPLACE')
 modifier=o.modifiers.new('R15 skin weights','ARMATURE');modifier.object=rig;o.parent=rig
bpy.context.scene['production_stage']='DCC_CLEAN_CANDIDATE_PENDING_VISUAL_REVIEW'
bpy.ops.wm.save_as_mainfile(filepath=str(out/(ident+'.blend')))
receipt={'id':ident,'source':a.model,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'height_studs':height,'triangles':sum(len(p.vertices)-2 for o in objects for p in o.data.polygons),'bones':list(segments),'source_skinning':'distance-weighted R15 candidate; deformation review pending','studio_animation':'dominant triangle groups; restrained rigid idle','art_approved':False}
(out/(ident+'.json')).write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt))
