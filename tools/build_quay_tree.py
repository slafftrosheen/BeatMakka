"""Editable, seeded dockside foliage; no provider or external model dependency."""
import bpy,math,random,json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1];O=R/'assets/production/needle-quay/models/refined';rng=random.Random(1948)
bpy.ops.wm.read_factory_settings(use_empty=True)
colors={'Bark':(.33,.23,.16,1),'LeavesShade':(.27,.39,.21,1),'LeavesMiddle':(.36,.48,.24,1),'LeavesLight':(.45,.57,.30,1),'LeavesTips':(.55,.62,.34,1)}
mats={}
for name,color in colors.items():
 m=bpy.data.materials.new(name);m.diffuse_color=color;mats[name]=m
def branch(a,b,r1,r2):
 a,b=Vector(a),Vector(b);d=b-a;bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r1,radius2=r2,depth=d.length,location=(a+b)/2)
 o=bpy.context.object;o.name='BarkBranch';o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(mats['Bark'])
 for p in o.data.polygons:p.use_smooth=True
branch((0,0,0),(.35,.1,5),.55,.4);branch((.35,.1,5),(1,0,10),.4,.23)
centres=[]
for i in range(8):
 angle=i*math.tau/8;end=(math.cos(angle)*3.4,math.sin(angle)*3,10.5+(i%3)*1.1)
 branch((.45,0,5.5+i*.35),end,.24,.055);centres.append(Vector(end))
for i in range(192):
 c=centres[i%8];v=Vector((rng.uniform(-2.3,2.3),rng.uniform(-2,2),rng.uniform(-1,2.4)))
 bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=1,location=c+v)
 o=bpy.context.object;o.name='Leaves';o.scale=(rng.uniform(.8,1.3),rng.uniform(.4,.75),rng.uniform(.45,.75));o.rotation_euler=(rng.uniform(-.4,.4),rng.uniform(-.4,.4),rng.uniform(0,math.tau));o.data.materials.append(mats[list(colors)[1+i%4]])
 for p in o.data.polygons:p.use_smooth=True
for i in range(5):
 t=i*math.tau/5;branch((0,0,.8),(math.cos(t)*1.1,math.sin(t)*1.1,.1),.22,.06)
O.mkdir(parents=True,exist_ok=True);bpy.ops.wm.save_as_mainfile(filepath=str(O/'NQ-SCENERY-TREE.blend'))
(O/'NQ-SCENERY-TREE.json').write_text(json.dumps({'id':'NQ-SCENERY-TREE','source':'tools/build_quay_tree.py','seed':1948,'stage':'DCC_AUTHORED_ARTBOOK_REVISION_IN_REVIEW','canonical_register_asset':False,'external_assets':[]},indent=2))
