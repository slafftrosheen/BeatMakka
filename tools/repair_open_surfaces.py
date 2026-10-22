import bpy,bmesh,json,io,contextlib
from pathlib import Path
root=Path(r'C:\Users\slavd\BeatMaka')
files=['H01/H01_sampler_shell.glb','H02/H02_compact_speaker_stack.glb','H05/H05_curved_street_lamp_scaled.glb','P01/P01_studio_workbench.glb','P02/P02_round_workshop_stool.glb','P03/P03_listening_bench.glb']
def metrics(meshes):
 r={'triangles':0,'boundary_edges':0,'nonmanifold_edges':0,'degenerate_faces':0,'winding_conflicts':0}
 for o in meshes:
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-5);bm.normal_update()
  r['triangles']+=sum(len(f.verts)-2 for f in bm.faces);r['boundary_edges']+=sum(len(e.link_faces)==1 for e in bm.edges);r['nonmanifold_edges']+=sum(len(e.link_faces)>2 or not e.link_faces for e in bm.edges);r['degenerate_faces']+=sum(f.calc_area()<1e-9 for f in bm.faces)
  for e in bm.edges:
   if len(e.link_faces)==2:
    ds=[(l.vert,l.link_loop_next.vert) for l in e.link_loops]
    if len(ds)==2 and ds[0][0] is ds[1][0] and ds[0][1] is ds[1][1]:r['winding_conflicts']+=1
  bm.free()
 return r
def fill_cycles(bm):
 edges={e for e in bm.edges if len(e.link_faces)==1};adj={v:[] for e in edges for v in e.verts}
 for e in edges:
  for v in e.verts:adj[v].append(e)
 seen=set();count=0
 for seed in list(edges):
  if seed in seen:continue
  comp=set();todo=[seed];seen.add(seed)
  while todo:
   e=todo.pop();comp.add(e)
   for v in e.verts:
    for x in adj[v]:
     if x not in seen:seen.add(x);todo.append(x)
  verts={v for e in comp for v in e.verts}
  if not verts or any(sum(e in comp for e in adj[v])!=2 for v in verts):continue
  start=next(iter(verts));ordered=[start];previous=None;current=start
  while len(ordered)<=len(verts):
   choices=[e.other_vert(current) for e in adj[current] if e in comp and e.other_vert(current) is not previous]
   if not choices:break
   nxt=choices[0]
   if nxt is start:break
   ordered.append(nxt);previous,current=current,nxt
  if len(ordered)!=len(verts):continue
  try:bm.faces.new(ordered);count+=1
  except ValueError:pass
 return count
results=[]
for rel in files:
 src=root/'assets'/'cleaned'/rel;bpy.ops.wm.read_factory_settings(use_empty=True)
 with contextlib.redirect_stdout(io.StringIO()):bpy.ops.import_scene.gltf(filepath=str(src))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];before=metrics(meshes);filled=0
 for o in meshes:
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-5);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);filled+=fill_cycles(bm);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(o.data);o.data.update();bm.free()
 after=metrics(meshes);dest=src.with_name(src.stem+'_surface_repaired.glb');bpy.ops.object.select_all(action='DESELECT')
 for o in meshes:o.select_set(True)
 bpy.context.view_layer.objects.active=meshes[0]
 with contextlib.redirect_stdout(io.StringIO()):bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_materials='EXPORT',export_apply=True,use_selection=True)
 results.append({'asset_id':rel.split('/')[0],'source':src.relative_to(root).as_posix(),'repaired_glb':dest.relative_to(root).as_posix(),'filled_faces':filled,'before':before,'after':after})
report=root/'docs'/'evidence'/'open-surface-repair.json';report.write_text(json.dumps({'blender_version':bpy.app.version_string,'method':'Welded coincident GLB seam vertices in memory, recalculated consistent normals, and capped each simple closed boundary loop for the six named active shell assets. Original GLBs remain preserved.','assets':results},indent=2)+'\n',encoding='utf-8');print(json.dumps(results,indent=2))
