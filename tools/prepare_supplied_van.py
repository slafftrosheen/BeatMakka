"""Adapt supplied vintage van to the Roamer envelope, retaining original UVs."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/production/needle-quay/models/supplied-van';OUT.mkdir(parents=True,exist_ok=True)
CONTENT=ROOT/'assets/local-demo/content/needle-quay/vintage-van';CONTENT.mkdir(parents=True,exist_ok=True)
jobs=[{'duplicate_of': None, 'building_id': 'LOOPVAN-01', 'source': 'assets/supplied/vehicles/vintage-van.glb', 'sha256': '891398a6fe602426d453ef25252c1fc1e163270b2fbf13179e4f8a757a9dfda2', 'target_blockout_wdh': [22, 9.4, 9.1]}]
records=[];materials={};layout={};receipts=[]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def mapped(v):return Vector((-v.x,v.z,v.y))
def nums(v):return ','.join(format(float(x),'.7g') for x in v)
for job in jobs:
 if job['duplicate_of']:continue
 ident=job['building_id'];bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/job['source']))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in objects:
  transform=o.matrix_world.copy()
  for v in o.data.vertices:v.co=Matrix.Rotation(3.141592653589793,4,"Z") @ transform @ v.co
  o.parent=None;o.matrix_world=Matrix.Identity(4)
 repair=None
 pts=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
 lo=Vector(tuple(min(v[i] for v in pts)for i in range(3)));hi=Vector(tuple(max(v[i]for v in pts)for i in range(3)))
 w,d,h=job['target_blockout_wdh'];factor=min(w/(hi.x-lo.x),d/(hi.y-lo.y),h/(hi.z-lo.z))
 origin=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 for o in objects:
  transform=o.matrix_world.copy()
  for v in o.data.vertices:v.co=(transform@v.co-origin)*factor
  o.matrix_world=Matrix.Identity(4)
 size=(hi-lo)*factor
 keys={}
 for mat in {m for o in objects for m in o.data.materials if m}:
  shader=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if mat.use_nodes else None
  links=shader.inputs['Base Color'].links if shader else []
  if links and links[0].from_node.type=='TEX_IMAGE':
   image=links[0].from_node.image;dest=CONTENT/(ident+'_color.png')
   image.filepath_raw=str(dest);image.file_format='PNG';image.save();image.pack()
   key='supplied_van_'+ident;keys[mat.name]=key;materials[key]='rbxasset://needle-quay/vintage-van/'+dest.name
   mat.diffuse_color=(1,1,1,1)
 groups={};colors={}
 for o in objects:
  m=o.data;m.calc_loop_triangles();uv=m.uv_layers.active
  for tri in m.loop_triangles:
   mat=m.materials[tri.material_index] if m.materials else None
   key=keys.get(mat.name,mat.name) if mat else 'Plain';colors[key]=[1,1,1] if mat and mat.name in keys else list(mat.diffuse_color[:3]) if mat else [.5,.5,.5]
   row=[]
   for i in (0,1,2):
    loop=tri.loops[i];row.append((mapped(m.vertices[tri.vertices[i]].co),mapped(m.corner_normals[loop].vector),uv.data[loop].uv.copy() if uv else Vector((0,0))))
   groups.setdefault(key,[]).append(row)
 parts=[]
 for i,(key,tris) in enumerate(groups.items()):
  pts=[p for t in tris for p,n,u in t];low=Vector(tuple(min(p[k]for p in pts)for k in range(3)));high=Vector(tuple(max(p[k]for p in pts)for k in range(3)));center=(low+high)/2
  lines=['version 1.01',str(len(tris))]+[''.join('['+nums(p-center)+']['+nums(n)+']['+nums((u.x,u.y,0))+']'for p,n,u in t)for t in tris]
  payload=('\n'.join(lines)+'\n').encode('ascii');digest=hashlib.sha256(payload).hexdigest();dest=CONTENT/f'{ident}_{i}_{digest[:12]}.mesh';dest.write_bytes(payload)
  parts.append(dict(name='Surface'+str(i),bone='',center=list(center),size=list(high-low),color=colors[key],surface_family=key if key in materials else None,triangles=len(tris),sha256=digest,uri='rbxasset://needle-quay/vintage-van/'+dest.name))
 blend=OUT/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
 record=dict(id=ident,kind='supplied_van',source=blend.relative_to(ROOT).as_posix(),source_sha256=sha(blend),triangles=sum(p['triangles']for p in parts),parts=parts,joints={})
 record['coordinate_basis']='blender_to_roblox_front_minus_z_v2'
 records.append(record)
 # Source front is -Y -> Roblox -Z. Keep the old street-facing frontage line.
 door=0
 layout[ident]=dict(size_wdh=list(size),center_offset_z=(size.y-d)/2,door_x=-door*size.x,entrance_z=-d/2-2.5,source=record['source'],sha256=record['source_sha256'],coordinate_basis='blender_to_roblox_front_minus_z_v2')
 receipts.append(dict(id=ident,original=job['source'],original_sha256=job['sha256'],uniform_scale=factor,size_wdh=list(size),repair=repair,stage='LOCAL_ADAPTATION_PENDING_ACCEPTANCE',art_approved=False,studio_imported=False,runtime_verified=False))
 # Neutral material preview after adaptation.
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
 scene.render.resolution_x=600;scene.render.resolution_y=600;scene.render.resolution_percentage=100
 scene.world=bpy.data.worlds.new('Review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
 center=Vector((0,0,size.z/2));span=max(size)
 bpy.ops.object.light_add(type='AREA',location=center+Vector((span,-span,span*1.8)));light=bpy.context.object;light.data.energy=160*span*span;light.data.size=span*1.5;light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
 bpy.ops.object.camera_add(location=center+Vector((span*.85,-span*1.8,span*.85)));cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=span*1.5;scene.camera=cam
 scene.render.filepath=str(OUT/(ident+'.png'));bpy.ops.render.render(write_still=True)
for name,data in [('QuayVanCatalog',records),('QuayVanMaterials',materials),('QuayVanLayout',layout)]:
 (ROOT/'src/shared'/(name+'.luau')).write_text('return game:GetService("HttpService"):JSONDecode([=['+json.dumps(data,separators=(',',':'))+']=])\n',encoding='utf-8')
(OUT/'manifest.json').write_text(json.dumps(dict(assets=records,materials=materials,layout=layout,provenance=receipts,uploads=0),indent=2),encoding='utf-8')
print('SUPPLIED_VAN',[(r['id'],r['triangles'])for r in records])
