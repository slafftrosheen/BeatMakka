"""Blender adaptations of user-supplied local GLBs; originals remain untouched."""
import bpy,json,math,hashlib,numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[1];O=R/'assets/production/needle-quay/models/user-adapted';T=R/'assets/production/needle-quay/user-model-maps';O.mkdir(parents=True,exist_ok=True);T.mkdir(parents=True,exist_ok=True)
records=[];materials={}
jobs=[('LOOPVAN-01','classic_vw_combi_van__stylized_asset.glb',None,(22,9,10),16000,'van',0),('NQ-MIDI-01','midi_controller_keyboard.glb',None,(4.7,1.7,.44),7000,'midi',0),('NQ-RADIO-01','vef_m557_radio.glb',None,(3.4,2.2,2.2),6000,'radio',-math.pi/2)]
for index,name in enumerate(['Cube_Atlas_0','Cube.002_Plate.003_Atlas_0','Cube.002_Plate.004_Atlas_0','Cube.002_Plate.005_Atlas_0','Building.013_Atlas_0','Building.001_Atlas_0','Object001_Atlas_0'],1):jobs.append((f'NQ-CITY-{index:02d}','city_game_ready_free.glb',name,(24,13,3 if index==7 else 12),4000,'city',0))
for ident,prefix,size in [('NQ-CHAIR-01','chair_', (2,2,3.2)),('NQ-TABLE-01','table1_', (3.6,3.6,2.7)),('NQ-BENCH-01','bench_', (5,1.8,2.2)),('NQ-COUNTER-01','barCounter_', (9,3,3.3)),('NQ-SHELF-01','shelf_', (4,1.4,4.6))]:jobs.append((ident,'low_poly_tavern_interior.glb',prefix,size,5000,'furniture',0))
for ident,filename,selection,size,budget,role,rotation in jobs:
 bpy.ops.wm.read_factory_settings(use_empty=True);source=R/'assets'/filename;bpy.ops.import_scene.gltf(filepath=str(source));objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 if selection:
  for o in list(objects):
   if not(o.name==selection or o.name.startswith(selection)):bpy.data.objects.remove(o,do_unlink=True);objects.remove(o)
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
 for index,material in enumerate(sorted({m for o in objects for m in o.data.materials},key=lambda m:m.name)):
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
 # Static templates have no dependency on original animation controllers/empties.
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
 output=O/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(output))
 records.append({'id':ident,'source':output.relative_to(R).as_posix(),'original':'assets/'+filename,'original_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'dimensions_wdh':[size[0],size[1],size[2]],'source_triangles':total,'triangles':sum(len(p.vertices)-2 for o in objects for p in o.data.polygons),'material_keys':material_keys,'kind':'vehicle' if ident=='LOOPVAN-01' else 'supplied','selection':selection,'stage':'DCC_ADAPTED_PENDING_LOCAL_VISUAL_REVIEW'})
(O/'manifest.json').write_text(json.dumps({'assets':records,'materials':materials,'source_authority':'User supplied these repository-root GLBs and authorized local adaptation; originals retained.','uploads':0},indent=2));print('ADAPTED_USER_ASSETS',len(records))
