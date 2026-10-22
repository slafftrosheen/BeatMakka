import bpy,bmesh,json,io,contextlib
from pathlib import Path
root=Path(r'C:\Users\slavd\BeatMaka')
paths=sorted((root/'assets').rglob('*.glb'))
out=[]
for path in paths:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 with contextlib.redirect_stdout(io.StringIO()): bpy.ops.import_scene.gltf(filepath=str(path))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']; rec={'path':path.relative_to(root).as_posix(),'mesh_objects':len(meshes),'triangles':0,'boundary_edges':0,'nonmanifold_edges':0,'degenerate_faces':0,'orientation_conflicts':0,'parts':[]}
 for o in meshes:
  bm=bmesh.new(); bm.from_mesh(o.data); bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-5); bm.normal_update()
  boundary=sum(1 for e in bm.edges if len(e.link_faces)==1)
  nonmanifold=sum(1 for e in bm.edges if len(e.link_faces)>2 or len(e.link_faces)==0)
  deg=sum(1 for f in bm.faces if f.calc_area()<1e-9)
  conflict=0
  for e in bm.edges:
   if len(e.link_faces)==2:
    dirs=[(l.vert,l.link_loop_next.vert) for l in e.link_loops]
    if len(dirs)==2 and dirs[0][0] is dirs[1][0] and dirs[0][1] is dirs[1][1]: conflict+=1
  tri=sum(len(f.verts)-2 for f in bm.faces)
  rec['triangles']+=tri; rec['boundary_edges']+=boundary; rec['nonmanifold_edges']+=nonmanifold; rec['degenerate_faces']+=deg; rec['orientation_conflicts']+=conflict
  if boundary or nonmanifold or deg or conflict: rec['parts'].append({'name':o.name,'triangles':tri,'boundary_edges':boundary,'nonmanifold_edges':nonmanifold,'degenerate_faces':deg,'orientation_conflicts':conflict})
  bm.free()
 rec['topology_flag']=bool(rec['boundary_edges'] or rec['nonmanifold_edges'] or rec['degenerate_faces'] or rec['orientation_conflicts'])
 out.append(rec)
report=root/'docs'/'evidence'/'glb-surface-audit.json'
report.write_text(json.dumps({'blender_version':bpy.app.version_string,'glb_count':len(out),'method':'Import every GLB with Blender 5.2.2; weld coincident export seam vertices in-memory at 1e-5; count boundary edges, non-manifold edges, degenerate faces and adjacent face winding conflicts. Boundary edges can be intentional (open mouths/sheets); inspect each flagged part before repair.','assets':out},indent=2)+'\n',encoding='utf-8')
print('REPORT',report); print('TOTAL',len(out),'FLAGGED',sum(x['topology_flag'] for x in out))
for x in out:
 if x['topology_flag']: print(json.dumps({k:x[k] for k in ('path','mesh_objects','triangles','boundary_edges','nonmanifold_edges','degenerate_faces','orientation_conflicts')}))
