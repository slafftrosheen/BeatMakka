"""Deterministic artbook speaker and curved foliage, preserving canonical IDs/bounds."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[1];D=R/'assets/production/needle-quay/models/refined'
def start():
 bpy.ops.wm.read_factory_settings(use_empty=True)
 mats={}
 for name,c in {'Teal':(.22,.43,.40,1),'Walnut':(.42,.26,.16,1),'Rubber':(.075,.09,.09,1),'Cone':(.28,.20,.14,1),'Brass':(.63,.47,.26,1),'Leaf':(.30,.46,.24,1),'LeafLight':(.43,.55,.29,1)}.items():
  m=bpy.data.materials.new(name);m.diffuse_color=c;mats[name]=m
 return mats
def finish(o,name,mat):o.name=name;o.data.materials.append(mats[mat]);return o
def box(name,at,size,mat,bevel=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,name,mat)
 if bevel:
  m=o.modifiers.new('Rounded cabinet edges','BEVEL');m.width=bevel;m.segments=1;o.modifiers.new('Face normals','WEIGHTED_NORMAL')
 return o
def mesh(name,vs,fs,mat):
 d=bpy.data.meshes.new(name);d.from_pydata(vs,[],fs);d.update();o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);return finish(o,name,mat)
def save(ident,bounds,budget):
 deps=bpy.context.evaluated_depsgraph_get();points=[o.matrix_world@Vector(c) for o in bpy.context.scene.objects for c in o.evaluated_get(deps).bound_box];lo=Vector(tuple(min(p[i] for p in points)for i in range(3)));hi=Vector(tuple(max(p[i] for p in points)for i in range(3)));shift=Matrix.Translation(Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z)));scale=Matrix.Diagonal(Vector((*[bounds[i]/(hi[i]-lo[i])for i in range(3)],1)))
 for o in bpy.context.scene.objects:o.matrix_world=scale@shift@o.matrix_world
 count=0
 for o in bpy.context.scene.objects:
  ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles();count+=len(me.loop_triangles);ev.to_mesh_clear()
 assert count<=budget,(ident,count,budget)
 bpy.ops.wm.save_as_mainfile(filepath=str(D/(ident+'.blend')))
 (D/(ident+'-polish.json')).write_text(json.dumps({'id':ident,'triangles':count,'budget':budget,'dimensions_wdh':bounds,'source_authority':'Approved Needle Quay board and Production Atlas','generator':'tools/polish_quay_hero_props.py','stage':'DCC_CLEAN_PENDING_ART_REVIEW','uploads':0},indent=2))
 print('POLISHED',ident,count)
mats=start()
for z,h,w,depth in [(2.65,4.9,4,3),(6.6,2.65,3.6,2.8)]:
 for s in (-1,1):box('CabinetSide',(s*(w/2-.13),0,z),(.26,depth,h),'Teal',.06)
 for s in (-1,1):box('CabinetCap',(0,0,z+s*(h/2-.13)),(w-.3,depth,.26),'Walnut',.05)
 box('CabinetBack',(0,depth/2-.1,z),(w-.3,.2,h-.3),'Walnut')
 # Brass front corner plates read as repairs instead of uniform corrosion.
 for x in (-w/2+.25,w/2-.25):
  for zz in (z-h/2+.22,z+h/2-.22):box('CornerPlate',(x,-depth/2-.025,zz),(.35,.06,.35),'Brass',.03)
vs=[]
for radius,y in [(1.35,-1.57),(1.20,-1.61),(.98,-1.36),(.43,-1.11)]:
 for i in range(32):a=math.tau*i/32;vs.append((radius*math.cos(a),y,2.65+radius*math.sin(a)))
faces=[(j*32+i,j*32+(i+1)%32,(j+1)*32+(i+1)%32,(j+1)*32+i)for j in range(3)for i in range(32)]
o=mesh('ConcentricWooferCone',vs,faces,'Cone')
for p in o.data.polygons:p.use_smooth=True
bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=(0,-1.14,2.65));o=bpy.context.object;o.scale=(.44,.24,.44);finish(o,'DustCap','Rubber')
# Rectangular baffle around the round driver, with an actual open center.
vs=[]
for outer in (True,False):
 for i in range(32):a=math.tau*i/32;x=math.cos(a);z=math.sin(a);k=min(1.72/max(abs(x),1e-6),2.12/max(abs(z),1e-6))if outer else 1.35;vs.append((x*k,-1.55,2.65+z*k))
mesh('OpenBaffle',vs,[(i,(i+1)%32,32+(i+1)%32,32+i)for i in range(32)],'Rubber')
mesh('RecessedHorn',[(-1.45,-1.42,5.7),(1.45,-1.42,5.7),(1.45,-1.42,7.5),(-1.45,-1.42,7.5),(-.35,-.5,6.3),(.35,-.5,6.3),(.35,-.5,6.9),(-.35,-.5,6.9)],[(i,(i+1)%4,4+(i+1)%4,4+i)for i in range(4)],'Cone')
box('HornThroat',(0,-.45,6.6),(.7,.05,.6),'Rubber')
for x in (-1.4,1.4):
 for y in (-.95,.95):box('IsolatingFoot',(x,y,.13),(.5,.5,.26),'Rubber',.04)
save('H02',(4,3,8),2200)
mats=start()
for i in range(9):
 angle=math.tau*i/9;z=.45+(i%3)*.55;length=1.15+(i%3)*.18;vs=[]
 for j in range(9):
  t=j/8;r=.12+t*length;up=z+1.6*t-1.12*t*t;width=.38*math.sin(math.pi*t)**.7
  for side in (-1,1):vs.append((math.cos(angle)*r-math.sin(angle)*width*side,math.sin(angle)*r+math.cos(angle)*width*side,up-.14*abs(side)*math.sin(math.pi*t)))
 fs=[(j*2,j*2+1,j*2+3,j*2+2)for j in range(8)];count=len(vs);vs+=vs.copy();fs+=list(tuple(v+count for v in reversed(f))for f in fs)
 o=mesh('CurvedBroadLeaf',vs,fs,'LeafLight' if i%3==0 else 'Leaf')
 for p in o.data.polygons:p.use_smooth=True
 a=Vector((0,0,.1));b=Vector((.12*math.cos(angle),.12*math.sin(angle),z));bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=.025,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();finish(o,'LeafStem','Leaf')
save('P12',(3,3,4),550)
