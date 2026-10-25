"""Blender adaptations of user-supplied local GLBs; originals remain untouched."""
import bpy,json,math,hashlib,numpy as np,sys
from pathlib import Path
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[1];O=R/'assets/production/needle-quay/models/user-adapted';T=R/'assets/production/needle-quay/user-model-maps';O.mkdir(parents=True,exist_ok=True);T.mkdir(parents=True,exist_ok=True)
records=[];materials={}
jobs=[('LOOPVAN-01','classic_vw_combi_van__stylized_asset.glb',None,(22,9,10),16000,'van',0),('NQ-MIDI-01','midi_controller_keyboard.glb',None,(4.7,1.7,.44),7000,'midi',0),('NQ-RADIO-01','vef_m557_radio.glb',None,(3.4,2.2,2.2),6000,'radio',-math.pi/2)]
for index,name in enumerate(['Cube_Atlas_0','Cube.002_Plate.003_Atlas_0','Cube.002_Plate.004_Atlas_0','Cube.002_Plate.005_Atlas_0','Building.013_Atlas_0','Building.001_Atlas_0','Object001_Atlas_0'],1):jobs.append((f'NQ-CITY-{index:02d}','city_game_ready_free.glb',name,(24,13,3 if index==7 else 12),4000,'city',0))
for ident,prefix,size in [('NQ-CHAIR-01','chair_', (2,2,3.2)),('NQ-TABLE-01','table1_', (3.6,3.6,2.7)),('NQ-BENCH-01','bench_', (5,1.8,2.2)),('NQ-COUNTER-01','barCounter_', (9,3,3.3)),('NQ-SHELF-01','shelf_', (4,1.4,4.6))]:jobs.append((ident,'low_poly_tavern_interior.glb',prefix,size,5000,'furniture',0))
if '--fresh' in sys.argv:
 previous=json.loads((O/'manifest.json').read_text());records=previous['assets'];materials=previous['materials']
 jobs=[('LOOPVAN-01','generic_civil_service_vehicles_pack.glb','postvan_', (22,9,10),16000,'cleanvan',0),
 ('NQ-CAKE-01','cake.glb','Whole_Cheesecake_0',(1.7,1.7,.85),1800,'cake',0),
 ('NQ-CAKE-02','cake.glb','Slice_Strawberry_Cream_0',(.8,1,.65),800,'cake_slice',0),
 ('NQ-UTILITY-01','electrical_boxes.glb','modular-box-02_', (1.4,.5,2.3),500,'utility',0),
 ('NQ-PRODUCE-01','potato_sacks.glb',None,(4,2.8,3.1),2800,'produce',0),
 ('NQ-COFFEE-01','food_collection_-_game_ready.glb','SM_Coffee_Box_01_',(.65,.4,1),500,'groceries',0),
 ('NQ-MILK-01','food_collection_-_game_ready.glb','SM_Milk_Bottle_01_',(.5,.5,1.15),700,'groceries',0),
 ('NQ-VINYL-01','vinyls_1.glb','Object_157',(2.3,2.3,.045),1600,'vinyl',0),
 ('NQ-ROCK-01','stylised_rocks_asset_pack.glb','Desert_Rock1_', (7,5,4),700,'shore_rock',0),
 ('NQ-ROCK-02','stylised_rocks_asset_pack.glb','Desert_Rock7_', (9,6,5),900,'shore_rock',0),
 ('NQ-ROCK-03','stylised_rocks_asset_pack.glb','Desert_Rock14_', (6,5,3.5),700,'shore_rock',0)]
 records=[a for a in records if a['id'] not in {j[0]for j in jobs}]
for ident,filename,selection,size,budget,role,rotation in jobs:
 bpy.ops.wm.read_factory_settings(use_empty=True);source=R/'assets'/filename;bpy.ops.import_scene.gltf(filepath=str(source));objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 if selection:
  for o in list(objects):
   if not(o.name==selection or o.name.startswith(selection)):bpy.data.objects.remove(o,do_unlink=True);objects.remove(o)
 if role=='cleanvan':
  for o in list(objects):
   if 'decal' in o.name.lower():bpy.data.objects.remove(o,do_unlink=True);objects.remove(o)
  bounds=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
  span=[max(p[i]for p in bounds)-min(p[i]for p in bounds)for i in range(3)]
  if span[1]>span[0]:rotation=math.pi/2
 assert objects,(ident,selection)
 rotate=Matrix.Rotation(rotation,4,'Z');points=[rotate@o.matrix_world@v.co for o in objects for v in o.data.vertices];lo=Vector(tuple(min(p[i] for p in points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in points) for i in range(3)));offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));scale=Vector(size)/(hi-lo) if False else Vector(tuple(size[i]/(hi[i]-lo[i]) for i in range(3)))
 total=sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
 for o in objects:
  transform=rotate@o.matrix_world
  for v in o.data.vertices:
   at=transform@v.co-offset;v.co=Vector((at.x*scale.x,at.y*scale.y,at.z*scale.z))
  o.parent=None;o.matrix_world=Matrix.Identity(4)
  if total>budget:
   modifier=o.modifiers.new('Local game geometry budget','DECIMATE');modifier.ratio=budget/total;modifier.use_collapse_triangulate=True;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=modifier.name)
 material_keys={}
 if role=='cleanvan':
  palette=[]
  for name,color in [('Teal',(.24,.49,.46,1)),('Cream',(.86,.81,.68,1)),('Rubber',(.07,.10,.11,1)),('Lamp',(.94,.72,.39,1)),('Brass',(.60,.51,.35,1)),('Glass',(.15,.26,.28,1))]:
   m=bpy.data.materials.new(name);m.diffuse_color=color;palette.append(m)
  for o in objects:
   labels=[];uv=o.data.uv_layers.active;paint=None
   for old in o.data.materials:
    if old.use_nodes:
     shader=next((n for n in old.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
     if shader and shader.inputs['Base Color'].links:
      tex=shader.inputs['Base Color'].links[0].from_node
      if tex.type=='TEX_IMAGE' and tex.image:paint=np.array(tex.image.pixels[:]).reshape(tex.image.size[1],tex.image.size[0],4)
   for face in o.data.polygons:
    z=face.center.z;label=5 if 'glass' in o.name.lower() else 3 if 'optics' in o.name.lower() else 1 if z>7.5 else 2 if z<2.1 else 0
    if label==2 and paint is not None and uv:
     at=sum((uv.data[i].uv for i in face.loop_indices),Vector((0,0)))/len(face.loop_indices)
     rgb=paint[int(at.y*(paint.shape[0]-1))%paint.shape[0],int(at.x*(paint.shape[1]-1))%paint.shape[1],:3]
     if rgb.mean()>.24:label=4
    labels.append(label)
   o.data.materials.clear()
   for m in palette:o.data.materials.append(m)
   for p,label in zip(o.data.polygons,labels):p.material_index=label
 for index,material in enumerate(sorted({m for o in objects for m in o.data.materials},key=lambda m:m.name)):
  if role=='cleanvan':continue
  shader=next((n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if material.use_nodes else None
  if not shader:continue
  material.diffuse_color=shader.inputs['Base Color'].default_value[:]
  links=shader.inputs['Base Color'].links
  texture=links[0].from_node if links else None
  if not texture or texture.type!='TEX_IMAGE' or not texture.image:continue
  key='supplied_'+role+'_'+str(index);image=texture.image;image.scale(1024 if role=='van' else 512,1024 if role=='van' else 512)
  # Re-author the model's paint layer; retain its source wear, UVs and soft shading.
  if role in ('van','city'):
   pixels=np.array(image.pixels[:],dtype=np.float32).reshape(-1,4);rgb=pixels[:,:3];r,g,b=rgb.T.copy();value=np.maximum.reduce([r,g,b])
   mask=(r>g*1.2)&(g>b*1.35)&(r>.35)&(g>.16) if role=='van' else (b>r*1.2)&(b>g*1.05)
   rgb[mask]=value[mask,None]*np.array([.43,.76,.71]);image.pixels=pixels.ravel()
  dest=T/(key+'_color.png');image.filepath_raw=str(dest);image.file_format='PNG';image.save();image.pack();material_keys[material.name]=key;materials[key]={'color':dest.relative_to(R).as_posix()}
  material.diffuse_color=(1,1,1,1)
 if role=='cleanvan':
  def trim(name,at,dimensions,slot):
   bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.dimensions=dimensions;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(palette[slot]);bevel=o.modifiers.new('Rounded manufactured trim','BEVEL');bevel.width=.045;bevel.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=bevel.name);objects.append(o)
  side_width=max(abs(v.co.y)for o in objects for v in o.data.vertices if -4<v.co.x<3 and 4<v.co.z<7)
  for side in (-1,1):
   y=side*(side_width+.025)
   trim('StudioWindowFrame',(-1.8,y,6.2),(4.6,.12,2.1),1)
   trim('StudioWindow',(-1.8,y+side*.07,6.2),(4.28,.08,1.8),5)
   trim('WindowDivider',(-1.8,y+side*.13,6.2),(.09,.07,1.85),1)
   trim('BeltlineTrim',(-2,y,3.4),(13,.1,.13),4)
   trim('StudioDoorPull',(-6,y+side*.08,4.3),(.65,.16,.12),4)
   trim('RoofRackRail',(-1.5,side*2.8,10.2),(12,.14,.18),4)
  for x in (-7,-2,4):trim('RoofRackCrossbar',(x,0,10.12),(.14,5.7,.14),4)
  points=[o.matrix_world@v.co for o in objects for v in o.data.vertices];lo=Vector(tuple(min(p[i]for p in points)for i in range(3)));hi=Vector(tuple(max(p[i]for p in points)for i in range(3)));offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
  for o in objects:
   transform=o.matrix_world.copy()
   for v in o.data.vertices:
    at=transform@v.co-offset;v.co=Vector(tuple(at[i]*size[i]/(hi[i]-lo[i])for i in range(3)))
   o.matrix_world=Matrix.Identity(4)
 # Static templates have no dependency on original animation controllers/empties.
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
 output=O/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(output))
 records.append({'id':ident,'source':output.relative_to(R).as_posix(),'original':'assets/'+filename,'original_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'dimensions_wdh':[size[0],size[1],size[2]],'source_triangles':total,'triangles':sum(len(p.vertices)-2 for o in objects for p in o.data.polygons),'material_keys':material_keys,'kind':'vehicle' if ident=='LOOPVAN-01' else 'supplied','selection':selection,'stage':'DCC_ADAPTED_PENDING_LOCAL_VISUAL_REVIEW'})
used_keys={key for a in records for key in a['material_keys'].values()}
materials={key:maps for key,maps in materials.items() if key in used_keys}
(O/'manifest.json').write_text(json.dumps({'assets':records,'materials':materials,'source_authority':'User supplied these repository-root GLBs and authorized local adaptation; originals retained.','uploads':0},indent=2));print('ADAPTED_USER_ASSETS',len(records))
