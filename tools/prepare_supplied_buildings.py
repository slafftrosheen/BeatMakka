"""Fit seven supplied storefronts, repair cafe roof, export exact local meshes/UVs."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/production/needle-quay/models/supplied-buildings';OUT.mkdir(parents=True,exist_ok=True)
CONTENT=ROOT/'assets/local-demo/content/needle-quay/buildings-set-01';CONTENT.mkdir(parents=True,exist_ok=True)
jobs=json.loads((ROOT/'data/needle-quay-supplied-buildings-set-01.json').read_text())['assets']
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
  for v in o.data.vertices:v.co=transform@v.co
  o.parent=None;o.matrix_world=Matrix.Identity(4)
 repair=None
 if ident=='NQ-BLD-06':
  # The apparent hole is a black baked patch on the 0.438 roof deck. Cover it
  # with a closed, UV-independent deck; preserve vents and surrounding parapet.
  roof=bpy.data.materials.new('RepairedWarmRoof');roof.diffuse_color=(.39,.34,.28,1);roof.use_nodes=True;roof.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=roof.diffuse_color;roof.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.9
  bpy.ops.mesh.primitive_cube_add(size=1,location=(0,.055,.442))
  deck=bpy.context.object;deck.name='CafeClosedRoofDeck';deck.dimensions=(.76,.65,.008)
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  deck.data.materials.append(roof);objects.append(deck)
  repair={'method':'Closed warm roof deck covers baked black roof artifact; original preserved','source_roof_z':.438,'deck_top_z':.446,'dimensions':[.76,.65,.008]}
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
   key='supplied_building_'+ident;keys[mat.name]=key;materials[key]='rbxasset://needle-quay/buildings-set-01/'+dest.name
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
  parts.append(dict(name='Surface'+str(i),bone='',center=list(center),size=list(high-low),color=colors[key],surface_family=key if key in materials else None,triangles=len(tris),sha256=digest,uri='rbxasset://needle-quay/buildings-set-01/'+dest.name))
 blend=OUT/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
 record=dict(id=ident,kind='supplied_building',source=blend.relative_to(ROOT).as_posix(),source_sha256=sha(blend),triangles=sum(p['triangles']for p in parts),parts=parts,joints={})
 record['coordinate_basis']='blender_to_roblox_front_minus_z_v2'
 records.append(record)
 # Source front is -Y -> Roblox -Z. Keep the old street-facing frontage line.
 door={'NQ-BLD-01':0,'NQ-BLD-02':0,'NQ-BLD-03':0,'NQ-BLD-05':-.12,'NQ-BLD-06':0,'NQ-BLD-07':.28,'NQ-BLD-08':-.23}[ident]
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
for name,data in [('QuayBuildingCatalog',records),('QuayBuildingMaterials',materials),('QuayBuildingLayout',layout)]:
 (ROOT/'src/shared'/(name+'.luau')).write_text('return game:GetService("HttpService"):JSONDecode([=['+json.dumps(data,separators=(',',':'))+']=])\n',encoding='utf-8')
(OUT/'manifest.json').write_text(json.dumps(dict(assets=records,materials=materials,layout=layout,provenance=receipts,uploads=0),indent=2),encoding='utf-8')
print('SUPPLIED_BUILDINGS',[(r['id'],r['triangles'])for r in records])
