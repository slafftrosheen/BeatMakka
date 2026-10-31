"""Extract selected supplied props with grounded pivots; retain originals and provenance."""
import bpy, json, hashlib, math
from pathlib import Path
from mathutils import Vector, Matrix
R=Path(__file__).resolve().parents[1]
O=R/'assets/production/needle-quay/dressing';O.mkdir(parents=True,exist_ok=True)
C=R/'assets/local-demo/content/needle-quay/dressing';C.mkdir(parents=True,exist_ok=True)
jobs=[
 ('NQ-MARKET-CRATE','market_-_stylized_modular_low_poly_asset_pack.glb','FruitBox_M_SUpermarket_0',(3,2,.8),0),
 ('NQ-MARKET-TOMATO','market_-_stylized_modular_low_poly_asset_pack.glb','FruitBox_Tomato_M_SUpermarket_0',(3,2,.9),0),
 ('NQ-MARKET-ORANGE','market_-_stylized_modular_low_poly_asset_pack.glb','FruitBox_Orange_M_SUpermarket_0',(3,2,.9),0),
 ('NQ-MARKET-DISPLAY','market_-_stylized_modular_low_poly_asset_pack.glb','Grocery_Stagger_M_SUpermarket_0',(7,3,3.2),0),
 ('NQ-MARKET-CART','market_-_stylized_modular_low_poly_asset_pack.glb','ShoppingCart_M_SUpermarket_0',(2.5,4,3.2),0),
 ('NQ-POWER-CABINET','electrical_boxes.glb','modular-box-02_electrical boxes_0',(1.7,.5,2.6),math.pi/2),
 ('NQ-REPAIR-LAPTOP','old_low-poly_laptop__psx_retro_prop.glb',None,(2.6,1.9,1.8),0),
]
records=[];materials={};receipts=[]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def mapped(v):return Vector((-v.x,v.z,v.y))
def numbers(v):return ','.join(format(float(x),'.7g')for x in v)
for ident,filename,selected,size,angle in jobs:
 bpy.ops.wm.read_factory_settings(use_empty=True);source=R/'assets'/filename
 bpy.ops.import_scene.gltf(filepath=str(source))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and (not selected or o.name==selected)]
 assert objects,(ident,selected)
 for obj in list(bpy.context.scene.objects):
  if obj not in objects:bpy.data.objects.remove(obj,do_unlink=True)
 rotate=Matrix.Rotation(angle,4,'Z')
 pts=[rotate@o.matrix_world@v.co for o in objects for v in o.data.vertices]
 lo=Vector(tuple(min(p[i]for p in pts)for i in range(3)));hi=Vector(tuple(max(p[i]for p in pts)for i in range(3)))
 base=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 factor=min(size[i]/max((hi-lo)[i],.0001)for i in range(3))
 for obj in objects:
  transform=rotate@obj.matrix_world
  for v in obj.data.vertices:v.co=(transform@v.co-base)*factor
  obj.parent=None;obj.matrix_world=Matrix.Identity(4)
 # Shared source images are content-addressed, so market props reuse one atlas.
 keys={}
 for material in {m for o in objects for m in o.data.materials if m}:
  shader=next((n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if material.use_nodes else None
  if not shader:continue
  links=shader.inputs['Base Color'].links
  if not links or links[0].from_node.type!='TEX_IMAGE':continue
  image=links[0].from_node.image
  if max(image.size)>1024:image.scale(1024,1024)
  temp=C/'atlas.tmp.png';image.filepath_raw=str(temp);image.file_format='PNG';image.save()
  digest=sha(temp);dest=C/('color_'+digest[:12]+'.png');dest.write_bytes(temp.read_bytes())
  key='supplied_dressing_'+digest[:12];keys[material.name]=key
  materials[key]='rbxasset://needle-quay/dressing/'+dest.name
  image.pack();material.diffuse_color=(1,1,1,1)
 groups={};colors={}
 for obj in objects:
  mesh=obj.data;mesh.calc_loop_triangles();uv=mesh.uv_layers.active
  for tri in mesh.loop_triangles:
   material=mesh.materials[tri.material_index] if mesh.materials else None
   key=keys.get(material.name,'') if material else ''
   colors[key]=[1,1,1] if key else list(material.diffuse_color[:3]) if material else [.6,.5,.4]
   row=[]
   for i in (0,1,2):
    loop=tri.loops[i];v=mesh.vertices[tri.vertices[i]]
    row.append((mapped(v.co),mapped(mesh.corner_normals[loop].vector),uv.data[loop].uv.copy() if uv else Vector((0,0))))
   groups.setdefault(key,[]).append(row)
 parts=[]
 for index,(key,triangles) in enumerate(groups.items()):
  pts=[p for tri in triangles for p,n,uv in tri]
  low=Vector(tuple(min(p[i]for p in pts)for i in range(3)));high=Vector(tuple(max(p[i]for p in pts)for i in range(3)));center=(low+high)/2
  lines=['version 1.01',str(len(triangles))]
  for tri in triangles:lines.append(''.join('['+numbers(p-center)+']['+numbers(n)+']['+numbers((uv.x,uv.y,0))+']' for p,n,uv in tri))
  payload=('\n'.join(lines)+'\n').encode('ascii');digest=hashlib.sha256(payload).hexdigest()
  dest=C/(ident+'_'+str(index)+'_'+digest[:12]+'.mesh');dest.write_bytes(payload)
  parts.append({'name':'Surface'+str(index),'bone':'','center':list(center),'size':list(high-low),'color':colors[key],'surface_family':key or None,'triangles':len(triangles),'sha256':digest,'uri':'rbxasset://needle-quay/dressing/'+dest.name})
 blend=O/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
 records.append({'id':ident,'kind':'supplied_dressing','source':blend.relative_to(R).as_posix(),'source_sha256':sha(blend),'triangles':sum(p['triangles']for p in parts),'parts':parts,'joints':{},'dimensions':[abs(v) for v in mapped((hi-lo)*factor)],'coordinate_basis':'blender_to_roblox_front_minus_z_v2'})
 receipts.append({'id':ident,'original':source.relative_to(R).as_posix(),'original_sha256':sha(source),'selected_object':selected,'uniform_scale':factor,'grounded_pivot':True,'stage':'LOCAL_ADAPTATION_PENDING_ACCEPTANCE'})
for name,payload in [('QuayDressingCatalog',records),('QuayDressingMaterials',materials)]:
 (R/'src/shared'/(name+'.luau')).write_text('return game:GetService("HttpService"):JSONDecode([=['+json.dumps(payload,separators=(',',':'))+']=])\n')
(O/'manifest.json').write_text(json.dumps({'assets':records,'materials':materials,'provenance':receipts,'uploads':0},indent=2)+'\n')
print('DRESSING',[(r['id'],r['triangles'],r['dimensions'])for r in records])
