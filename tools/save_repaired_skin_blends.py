"""Save repaired weight-only Blender derivatives; never overwrite supplied rigs."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.kdtree import KDTree
R=Path(__file__).resolve().parents[1];out=R/'assets/production/needle-quay/skin-repair'
manifest=json.loads((R/'assets/local-demo/mesh-manifest.json').read_text())['assets']
companions=json.loads((R/'assets/production/needle-quay/companions/supplied/manifest.json').read_text())['characters']
sources=[(a['id'],a['source'],None)for a in manifest if a.get('skin')]+[(a['id'],a['blend'],a['height_studs'])for a in companions]
receipts=[]
for ident,source,height in sources:
 weightfile=out/(ident+'-weights.json')
 if not weightfile.exists():continue
 rows=json.loads(weightfile.read_text());tree=KDTree(len(rows))
 for i,(pos,_) in enumerate(rows):tree.insert(Vector(pos),i)
 tree.balance();bpy.ops.wm.open_mainfile(filepath=str(R/source))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 if height is None:
  deps=bpy.context.evaluated_depsgraph_get()
  baked=[(o,bpy.data.meshes.new_from_object(o.evaluated_get(deps),preserve_all_data_layers=True,depsgraph=deps))for o in bpy.context.scene.objects if o.type=='MESH']
  for o,mesh in baked:
   o.data=mesh;o.modifiers.clear();modifier=o.modifiers.new('Repaired skin','ARMATURE');modifier.object=rig
 rig.data.pose_position='REST' 
 if rig.animation_data:
  rig.animation_data.action=None
  for track in rig.animation_data.nla_tracks:track.mute=True
 bpy.context.view_layer.update();objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
 points=[o.matrix_world@v.co for o in objects for v in o.data.vertices];low=Vector(tuple(min(p[i] for p in points)for i in range(3)));high=Vector(tuple(max(p[i] for p in points)for i in range(3)))
 scale=height/(high.z-low.z) if height else 1;origin=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z)) if height else Vector((0,0,0));maximum=0
 for o in objects:
  o.vertex_groups.clear();groups={n:o.vertex_groups.new(name=n) for n in rig.data.bones.keys()}
  for v in o.data.vertices:
   p=(o.matrix_world@v.co-origin)*scale;p=Vector((p.x,p.z,p.y));_,index,distance=tree.find(p);maximum=max(maximum,distance)
   assert distance<.001,(ident,distance)
   for n,w in rows[index][1]:groups[n].add([v.index],w,'REPLACE')
 bpy.context.scene['skin_repair']='anatomical weights and source-pose strain review; local only'
 dest=out/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(dest))
 receipts.append({'id':ident,'source':source,'source_sha256':hashlib.sha256((R/source).read_bytes()).hexdigest(),'output':dest.relative_to(R).as_posix(),'output_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'max_vertex_match_error':maximum,'geometry_changed':False,'art_approved':False})
(out/'dcc-provenance.json').write_text(json.dumps(receipts,indent=2))
