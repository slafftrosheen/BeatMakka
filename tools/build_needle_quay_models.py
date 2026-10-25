"""Blender batch: deterministic separated building/NPC source candidates.

Invoke Blender --background --python this_file. Never overwrites accepted H04.
Building dimensions follow canonical layout proxies, not generated image arrows.
"""
import bpy,math,json,hashlib,xml.etree.ElementTree as ET
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
OUT=R/'assets/production/needle-quay/models';OUT.mkdir(parents=True,exist_ok=True)
D=json.loads((R/'data/needle-quay-environment.v1.json').read_text(encoding='utf-8'))
TREE=ET.parse(R/'assets/blockouts/needle-quay/NeedleQuayEnvironmentBlockout.rbxmx')
COLORS={'teal':(47,92,88),'cream':(232,216,183),'coral':(202,116,83),'walnut':(121,81,59),'stone':(183,156,126),'graphite':(44,48,49),'amber':(243,182,95),'skin':(184,118,75),'hair':(64,43,32)}
MATS={}
def mat(name,rgb=None):
 if name in MATS:return MATS[name]
 rgb=rgb or COLORS[name];m=bpy.data.materials.new(name);m.diffuse_color=(*(v/255 for v in rgb),1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*(pow(v/255,2.2) for v in rgb),1);bs.inputs['Roughness'].default_value=.72
 MATS[name]=m;return m
def cube(name,size,pos,color='teal',bevel=.08):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(mat(color))
 if bevel:
  mod=o.modifiers.new('Soft edges','BEVEL');mod.width=min(bevel,min(size)/5);mod.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def cylinder(name,radius,depth,pos,color='graphite',rotate=False):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=radius,depth=depth,location=pos);o=bpy.context.object;o.name=name
 if rotate:o.rotation_euler[0]=math.pi/2
 o.data.materials.append(mat(color));return o
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def sphere(name,size,pos,color='skin'):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1,location=pos);o=bpy.context.object;o.name=name;o.scale=tuple(v/2 for v in size);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat(color))
 for p in o.data.polygons:p.use_smooth=True
 return o
def beam(name,a,b,width,color='teal'):
 a,b=Vector(a),Vector(b);o=cube(name,(width,width,(b-a).length),(a+b)/2,color);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def rigid_rig(width,scale):
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='CharacterRig';bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0]);bones={}
 defs={'LowerTorso':((0,0,2.3),(0,0,3.1),None),'UpperTorso':((0,0,3.1),(0,0,4.5),'LowerTorso'),'Head':((0,0,4.5),(0,0,5.9),'UpperTorso')}
 for side,sg in [('Left',-1),('Right',1)]:
  x=sg*(width*.9+.36);lx=sg*.48*width
  defs[side+'UpperArm']=((x,0,4.2),(x,0,3.3),'UpperTorso');defs[side+'LowerArm']=((x,0,3.3),(x,0,2.45),side+'UpperArm');defs[side+'Hand']=((x,0,2.45),(x,0,1.95),side+'LowerArm')
  defs[side+'UpperLeg']=((lx,0,2.45),(lx,0,1.3),'LowerTorso');defs[side+'LowerLeg']=((lx,0,1.3),(lx,0,.45),side+'UpperLeg');defs[side+'Foot']=((lx,0,.45),(lx,-.4,.15),side+'LowerLeg')
 for n,(a,b,parent) in defs.items():
  bone=rig.data.edit_bones.new(n);bone.head=Vector(a)*scale;bone.tail=Vector(b)*scale;bones[n]=bone
  if parent:bone.parent=bones[parent]
 bpy.ops.object.mode_set(mode='OBJECT')
 for o in meshes:
  base=o.name.split('.')[0];target=base if base in defs else 'Head' if any(t in base for t in ['Eye','Hair','Ear','Nose','Brow','Mouth','Goggle','Beard']) else 'UpperTorso' if 'Arm' not in base else 'LowerTorso'
  vg=o.vertex_groups.new(name=target);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('RigidJointDeformation','ARMATURE');mod.object=rig;o.parent=rig
 rig['RigStatus']='15 named rigid bones with unit weights; Roblox humanoid import and animation acceptance pending'
 return rig
def name(e):return e.findtext('Properties/string[@name="Name"]','')
def v3(e,tag):
 p=e.find('Properties/'+tag);return tuple(float(p.findtext(a,'0')) for a in ('X','Y','Z'))
def save_asset(ident,title,height):
 folder=OUT/ident;folder.mkdir(exist_ok=True)
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in objects:
  bpy.context.view_layer.objects.active=o;o.select_set(True)
  if not o.data.uv_layers:
   bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15192,island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
  o.select_set(False)
 tris=sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
 for o in bpy.context.scene.objects:o.select_set(o.type in ('MESH','ARMATURE'))
 glb=folder/(ident+'.glb');bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',use_selection=True,export_yup=True,export_extras=True)
 blend=folder/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8
 scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True
 world=bpy.data.worlds.new('Neutral studio');scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.55,.55,1)
 world.node_tree.nodes['Background'].inputs[1].default_value=.8
 bounds=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box];lo=Vector(tuple(min(v[i] for v in bounds) for i in range(3)));hi=Vector(tuple(max(v[i] for v in bounds) for i in range(3)));center=(lo+hi)/2;extent=max(hi-lo)
 bpy.ops.object.light_add(type='AREA',location=(extent,-extent,height+extent));light=bpy.context.object;light.data.energy=1000*max(1,extent/10);light.data.shape='DISK';light.data.size=extent
 bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=extent*1.55
 previews=[]
 for label,vec in [('neutral',(1,-1,.8)),('front',(0,-1,.05)),('side',(1,0,.05)),('top',(0,0,1))]:
  cam.location=center+Vector(vec).normalized()*extent*3;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(folder/(label+'.png'));bpy.ops.render.render(write_still=True);previews.append(str((folder/(label+'.png')).relative_to(R)).replace('\\','/'))
 return {'id':ident,'name':title,'source':str(blend.relative_to(R)).replace('\\','/'),'glb':str(glb.relative_to(R)).replace('\\','/'),'sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'triangles':tris,'mesh_objects':len(objects),'bone_count':sum(len(o.data.bones) for o in bpy.context.scene.objects if o.type=='ARMATURE'),'bounds_xyz_blender':list(hi-lo),'units':'1 local source unit = 1 authored stud; verify importer unit settings','previews':previews,'stage':'DETERMINISTIC_3D_CANDIDATE','dcc_clean_accepted':False,'art_approved':False,'studio_imported':False,'runtime_verified':False}
results=[]
for b in D['buildings']:
 clear();MATS.clear();ident=b['id'];x,z=b['blockout_center_xz_studs'];w,d,h=b['blockout_dimensions_wdh_studs']
 node=next(e for e in TREE.iter('Item') if e.attrib.get('class')=='Model' and name(e).startswith(ident+'_'))
 for e in node.iter('Item'):
  if e.attrib.get('class')!='Part':continue
  n=name(e);trans=float(e.findtext('Properties/float[@name="Transparency"]','0'))
  if ident=='NQ-BLD-13' and 'Roof' in n:continue
  if trans>=1 or n.endswith('PivotMarker') or n=='FloorCenterPivot':continue
  sz=v3(e,'Vector3[@name="size"]');p=v3(e,'CoordinateFrame[@name="CFrame"]');color=e.find('Properties/Color3[@name="Color"]');rgb=tuple(round(float(color.findtext(c))*255) for c in ('R','G','B'))
  key='source_'+str(rgb);mat(key,rgb);cube(n,(sz[0],sz[2],sz[1]),(p[0]-x,p[2]-z,p[1]),key)
 # Shared chunky trim and repeated modular joints, not random surface noise.
 if ident!='NQ-BLD-05':
  for xx in (-w/2+.3,w/2-.3):cube('CornerTrim',(.6,.7,h-1),(xx,-d/2+.4,(h-1)/2+.5),'cream')
 for xx in (-w/2+1,w/2-1):
  cube('FacadeLampBracket',(.35,.7,.3),(xx,-d/2-.4,min(h-3,10)),'graphite')
  cube('AmberLightInsert',(.6,.4,.9),(xx,-d/2-.55,min(h-3,9.5)),'amber')
 if ident in ['NQ-BLD-02','NQ-BLD-06','NQ-BLD-07','NQ-BLD-08','NQ-BLD-11']:
  cube('WalnutDoorLeaf',(3,.25,7),(-w*.24,-d/2-.12,3.5),'walnut');cube('SeparateDoorHandle',(.15,.25,.6),(-w*.24+1,-d/2-.35,3.6),'amber')
 if ident in ['NQ-BLD-09','NQ-BLD-13']:
  for sign in (-1,1):cube('LoadingDoorLeaf',(w*.21,.3,9),(sign*w*.11,-d/2-.2,4.8),'walnut')
  for zz in (-d*.3,d*.3):cylinder('RightWallPipe',.3,h*.65,(w/2+.35,zz,h*.4),'graphite')
 if ident=='NQ-BLD-10':
  for xx in [-w*.36,-w*.12,w*.12,w*.36]:
   cube('UpperWindowFrame',(5,.3,6),(xx,-d/2-.2,18),'cream');cube('UpperWindowDarkFill',(4.2,.1,5.2),(xx,-d/2-.4,18),'graphite');cube('UpperWindowSill',(5.5,1,.35),(xx,-d/2-.6,15),'walnut')
 if ident=='NQ-BLD-11':
  for xx in (-5,0,5):cylinder('ScenicWasherPorthole',1.8,.3,(xx,-d/2-.3,5.6),'graphite',True);cylinder('WasherInnerDisc',1.4,.35,(xx,-d/2-.5,5.6),'teal',True)
 if ident=='NQ-BLD-12':
  cube('ExternalRelayCabinet',(3,1.2,4),(3,-d/2-.7,2.5),'graphite');cube('RelaySignalInsert',(.6,.1,.6),(3,-d/2-1.35,3),'amber')
 if ident=='NQ-BLD-07':cube('TicketHatch',(8,.4,4),(-2,-d/2-.3,5.5),'teal')
 if ident=='NQ-BLD-08':
  for xx in (-w/2+2,w/2-2):cube('SupplyCrate',(2,2,2),(xx,-d/2-1.4,1),'walnut')
 if ident=='NQ-BLD-06':cube('ServingLedge',(8,1,.3),(2,-d/2-.65,3.6),'walnut')
 # Architectural vocabulary: cornices, frames, mullions and deliberate broad relief.
 for zz in (-d/2+.3,d/2-.3):cube('CreamRoofCornice',(w,.65,.65),(0,zz,h-.5),'cream')
 for xx in (-w/2+.3,w/2-.3):cube('CreamSideCornice',(.65,d,.65),(xx,0,h-.5),'cream')
 if ident not in ('NQ-BLD-04','NQ-BLD-05'):
  for xx in (-w/3,w/3):
   cube('WindowHeader',(w/5+.6,.4,.45),(xx,-d/2-.28,9.25),'cream');cube('WindowSill',(w/5+.6,.7,.4),(xx,-d/2-.35,3.75),'walnut')
   for side in (-1,1):cube('WindowJamb',(.35,.4,5.5),(xx+side*(w/10+.1),-d/2-.3,6.5),'cream')
   cube('WindowMullion',(.25,.45,5.2),(xx,-d/2-.38,6.5),'walnut')
  cube('PlinthBand',(w,.65,.7),(0,-d/2+.1,.6),'stone')
  for zz in (-d*.32,d*.32):cube('SideBrickPilaster',(.6,1,h-1),(w/2-.2,zz,(h-1)/2),'walnut')
  # Wide shallow mortar courses: geometry, not tiny individually modeled bricks.
  for level in range(2,int(h-2),3):cube('SideMasonryCourse',(.08,d-.8,.09),(w/2+.02,0,level),'walnut',0)
 if ident=='NQ-BLD-01':
  for xx in (-7,7):cube('EntrancePortalPost',(1.3,1.2,12),(xx,-d/2+.1,6.1),'teal')
  cube('MarqueeHousing',(25,1,3),(0,-d/2-.1,15),'teal');cube('MarqueeCreamInset',(23,.16,2.2),(0,-d/2-.66,15),'cream')
  for xx in range(-10,11,4):sphere('MarqueeBulb',(.3,.25,.3),(xx,-d/2-.82,13.8),'amber')
 if ident=='NQ-BLD-02':
  cylinder('VinylSign',3,.35,(0,-d/2-.45,18),'graphite',True);cylinder('VinylLabel',1,.4,(0,-d/2-.65,18),'coral',True)
  for xx in (-11,11):
   cube('VinylCrate',(4,2,2.5),(xx,-d/2-1.1,1.25),'walnut')
   for offset in (-.7,0,.7):cube('PlainRecordSleeve',(3.1,.12,2.8),(xx,-d/2-1.1+offset,2.7),'cream')
 if ident=='NQ-BLD-03':
  cube('SlidingDoorRail',(18,.7,.5),(5,-d/2-.4,11),'graphite');cube('SlidingDoorLeaf',(8,.3,9),(w/2-5,-d/2-.35,5),'walnut')
  cylinder('P16_GrilleRim',1.6,.35,(9,-d/2-.4,6),'teal',True)
  for i in range(5):
   a=i*math.tau/5;beam('FanBlade',(9,-d/2-.7,6),(9+math.cos(a)*1.2,-d/2-.7,6+math.sin(a)*1.2),.3,'graphite')
 if ident=='NQ-BLD-04':
  for i,xx in enumerate((-18,-6,6,18)):
   for stripe in range(6):cube('StallCanopyStripe',(1.5,5,.18),(xx-3.75+stripe*1.5,7,7.4),'coral' if stripe%2 else 'cream')
   for side in (-1,1):cube('StallCanopyPost',(.25,.25,7),(xx+side*4,7,3.5),'teal')
 if ident=='NQ-BLD-05':
  cylinder('RoundSignalFrame',2,.4,(0,-d/2-.2,8),'cream',True);cylinder('AmberSignalWindow',1.55,.45,(0,-d/2-.45,8),'amber',True)
  for zz in (-3,3):cube('CableClamp',(.15,.5,.4),(w/2+.1,zz,7),'graphite')
 if ident in ('NQ-BLD-06','NQ-BLD-07','NQ-BLD-08'):
  awn=cube('FrontAwning',(w-2,2,.22),(0,-d/2-.7,9.8 if h>11 else h-1.5),'coral' if ident=='NQ-BLD-06' else 'teal');awn.rotation_euler[0]=-.18
 if ident=='NQ-BLD-13':
  # Distinct low pitched roof from broad exact panels.
  for side in (-1,1):
   roof=cube('PitchedRoofPanel',(w/2+1,d,.45),(side*w/4,0,h-2),'teal');roof.rotation_euler[1]=side*.18
 if ident=='NQ-BLD-02':
  for o in bpy.context.scene.objects:
   if o.type=='MESH':o.location+=Vector((w/2,d/2,0))
 results.append(save_asset(ident,b['name'],h))
 (OUT/'buildings-progress.json').write_text(json.dumps(results,indent=2)+'\n')

# Six new articulated rigid-part candidates; Mica is explicitly canonical H04.
NPCS=[('TORI','Tori',5.8,1.25,'teal','cream'),('IVO','Ivo',6.6,.88,'teal','teal'),('NAYA','Naya',5.6,1.1,'cream','cream'),('SANA','Sana Bell',5.9,1.08,'coral','coral'),('RONAN','Ronan Wren',6.3,1.0,'graphite','graphite'),('NELL','Nell Fen',5.7,1.3,'teal','teal')]
npcs=[]
for slug,title,height,width,torso,sleeve in NPCS:
 clear();MATS.clear();s=height/6
 cube('LowerTorso',(1.5*width,.8,1),(0,0,2.6),torso);cube('UpperTorso',(1.8*width,.9,1.5),(0,0,3.7),torso)
 for side in (-1,1):
  x=side*.48*width
  cube(('Left' if side<0 else 'Right')+'UpperLeg',(.65,.7,1.2),(x,0,1.85),'walnut');cube(('Left' if side<0 else 'Right')+'LowerLeg',(.6,.65,1.05),(x,0,.85),'walnut');cube(('Left' if side<0 else 'Right')+'Foot',(.7,1.05,.5),(x,-.15,.25),'walnut')
  x=side*(width*.9+.36)
  cube(('Left' if side<0 else 'Right')+'UpperArm',(.58,.65,1.0),(x,0,3.7),sleeve);cube(('Left' if side<0 else 'Right')+'LowerArm',(.48,.55,.85),(x,0,2.85),'skin');cube(('Left' if side<0 else 'Right')+'Hand',(.5,.5,.5),(x,0,2.2),'skin')
 sphere('Head',(1.5,1.25,1.5),(0,0,5.15),'skin');sphere('HairCap',(1.55,1.28,.7),(0,.12,5.7),'hair')
 for side in (-1,1):
  sphere('Ear_'+str(side),(.28,.3,.4),(side*.74,0,5.05),'skin');sphere('EyeWhite_'+str(side),(.32,.12,.4),(side*.3,-.59,5.25),'cream');sphere('EyePupil_'+str(side),(.17,.08,.25),(side*.3,-.67,5.24),'graphite');cube('Brow_'+str(side),(.32,.08,.08),(side*.3,-.6,5.53),'hair',.03)
 sphere('Nose',(.25,.24,.32),(0,-.64,5.05),'skin');cube('Mouth',(.38,.06,.05),(0,-.59,4.77),'walnut',.02)
 for i in range(6):
  a=i*math.tau/6;sphere('HairLock_'+str(i),(.55,.48,.5),(math.cos(a)*.5,math.sin(a)*.38+.1,5.67),'hair')
 cube('Belt',(1.65*width,.9,.2),(0,0,2.62),'walnut')
 if slug=='TORI':
  for xx in (-.5,.5):cube('ToolPouch',(.4,.3,.5),(xx,-.58,2.6),'coral')
 if slug=='IVO':
  for xx in (-.28,.28):cube('GoggleFrame',(.45,.15,.3),(xx,-.56,5.65),'cream')
 if slug in ('NAYA','SANA'):cube('CrossbodyBag',(.85,.4,1),(1.1*width,-.15,2.8),'coral' if slug=='NAYA' else 'walnut')
 if slug=='RONAN':cube('LongCoat_Back',(1.8,.25,2.6),(0,.55,2.7),'graphite');cube('KeyRingTarget',(.2,.2,.4),(.75,-.6,2.5),'amber')
 if slug=='NELL':cube('ApronFront',(1.7,.12,1.8),(0,-.53,3.15),'cream')
 for o in bpy.context.scene.objects:
  o.location*=s;o.scale*=s;bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 rigid_rig(width,s)
 npcs.append(save_asset('NQ-NPC-'+slug,title,height))
 (OUT/'npcs-progress.json').write_text(json.dumps(npcs,indent=2)+'\n')
mica={'id':'H04','name':'Mica','source':'assets/cleaned/H04/H04_maintenance_helper_robot.blend','glb':'assets/optimized/H04/H04_atlas_v1.glb','stage':'EXISTING_CANONICAL_ASSET_REUSED_NO_REDESIGN','art_acceptance':'See existing H04 evidence; no new promotion'}
(OUT/'model-manifest.json').write_text(json.dumps({'buildings':results,'npcs':npcs+[mica],'provider':'deterministic Blender source; existing canonical H04 reused','tests_run':False,'runtime_verified':False},indent=2)+'\n')
print('NEEDLE_QUAY_MODEL_BATCH_COMPLETE',len(results),len(npcs)+1)
