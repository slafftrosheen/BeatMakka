import bpy,bmesh,json,io,contextlib
from pathlib import Path
root=Path(r'C:\Users\slavd\BeatMaka')
canon=['H01/H01_sampler_shell.glb','H02/H02_compact_speaker_stack.glb','H03/H03_vinyl_crate_shell.glb','H04/H04_maintenance_helper_robot.glb','H05/H05_curved_street_lamp_scaled.glb','P01/P01_studio_workbench.glb','P02/P02_round_workshop_stool.glb','P03/P03_listening_bench.glb','P04/P04_record_browsing_bin.glb','P05/P05_wall_shelf.glb','P06/P06_normalized_geometry_candidate.glb','P07/P07_normalized_geometry_candidate.glb','P11/P11_normalized_geometry_candidate.glb','P12/P12_solid_repair_candidate.glb','P13/P13_art_repair_candidate.glb','P14/P14_solid_repair_candidate.glb','P16/P16_normalized_geometry_candidate.glb','I01/I01_art_repair_candidate.glb','I04/I04_art_repair_candidate.glb','I05/I05_solid_repair_candidate.glb']
def metrics(meshes):
 out={'triangles':0,'boundary_edges':0,'nonmanifold_edges':0,'degenerate_faces':0,'winding_conflicts':0,'mesh_objects':len(meshes)}
 for o in meshes:
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-5);bm.normal_update()
  out['triangles']+=sum(len(f.verts)-2 for f in bm.faces);out['boundary_edges']+=sum(len(e.link_faces)==1 for e in bm.edges);out['nonmanifold_edges']+=sum(len(e.link_faces)>2 or len(e.link_faces)==0 for e in bm.edges);out['degenerate_faces']+=sum(f.calc_area()<1e-9 for f in bm.faces)
  for e in bm.edges:
   if len(e.link_faces)==2:
    ds=[(l.vert,l.link_loop_next.vert) for l in e.link_loops]
    if len(ds)==2 and ds[0][0] is ds[1][0] and ds[0][1] is ds[1][1]:out['winding_conflicts']+=1
  bm.free()
 return out
results=[]
for rel in canon:
 bpy.ops.wm.read_factory_settings(use_empty=True); src=root/'assets'/'cleaned'/rel
 with contextlib.redirect_stdout(io.StringIO()):bpy.ops.import_scene.gltf(filepath=str(src))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']; before=metrics(meshes)
 if not before['winding_conflicts']:
  results.append({'source':src.relative_to(root).as_posix(),'result':'already_consistent','metrics':before});continue
 for o in meshes:
  bm=bmesh.new();bm.from_mesh(o.data)
  bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-5)
  bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
  bm.to_mesh(o.data);o.data.update();bm.free()
 after=metrics(meshes); out=src.with_name(src.stem+'_surface_repaired.glb')
 bpy.ops.object.select_all(action='DESELECT')
 for o in meshes:o.select_set(True)
 bpy.context.view_layer.objects.active=meshes[0]
 with contextlib.redirect_stdout(io.StringIO()):bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_materials='EXPORT',export_apply=True,use_selection=True)
 results.append({'source':src.relative_to(root).as_posix(),'repaired_glb':out.relative_to(root).as_posix(),'before':before,'after':after,'result':'normals_recalculated'})
report={'blender_version':bpy.app.version_string,'method':'Recalculated consistent outward normals on production cleaned assets with winding conflicts. Original GLBs are untouched. Dimensions, pivots and boundary topology are checked separately; intentional openings are not auto-capped.','assets':results}
p=root/'docs'/'evidence'/'glb-normal-repair.json';p.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({'repaired':sum(x['result']=='normals_recalculated' for x in results),'already_consistent':sum(x['result']=='already_consistent' for x in results),'report':p.as_posix(),'assets':[x.get('repaired_glb',x['source']) for x in results if x['result']=='normals_recalculated']},indent=2))
