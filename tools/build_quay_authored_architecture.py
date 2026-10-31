"""Author reference-specific architecture with exact joins, UVs and local mesh export.

Original models are retained. These are reviewed design revisions, not automatic
art approval. All units are studs; Blender Z-up maps to Roblox Y-up at export.
"""
import bpy, math, json, hashlib
from pathlib import Path
from collections import defaultdict
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/production/needle-quay/architecture-artbook'
CONTENT = ROOT / 'assets/local-demo/content/needle-quay/architecture-artbook'
OUT.mkdir(parents=True, exist_ok=True); CONTENT.mkdir(parents=True, exist_ok=True)
PALETTE = {
 'brick': ((202,116,83),'brick'), 'teal': ((47,92,88),'plaster'),
 'faded': ((111,145,134),'plaster'), 'cream': ((232,216,183),'plaster'),
 'coral': ((202,116,83),'plaster'), 'wood': ((121,81,59),'wood'),
 'stone': ((232,216,183),'stone'), 'iron': ((44,48,49),'plaster'),
 'brass': ((190,144,75),'plaster'), 'glass': ((103,140,132),'plaster'),
 'amber': ((166,107,55),'light'), 'leaf': ((81,115,64),'plaster'),
}
JOBS = [
 ('NQ-BLD-09','cold_store',(34,20,16),'NQ-BLD-09-cinder-cold-storage-v1.png'),
 ('NQ-BLD-10','flats',(38,16,26),'NQ-BLD-10-quayside-flats-v1.png'),
 ('NQ-BLD-11','laundry',(18,16,14),'NQ-BLD-11-tidewash-laundry-v1.png'),
 ('NQ-BLD-12','relay',(12,12,11),'NQ-BLD-12-relay-substation-v1.png'),
 ('NQ-BLD-13','depot',(30,22,20),'NQ-BLD-13-dockline-depot-v1.png'),
 ('NQ-FACADE-01','flats',(26,18,27),'NQ-BLD-10-quayside-flats-v1.png'),
 ('NQ-FACADE-02','flats',(26,18,23),'NQ-BLD-10-quayside-flats-v1.png'),
 ('NQ-FACADE-03','laundry',(26,18,18),'NQ-BLD-11-tidewash-laundry-v1.png'),
]
records, receipts = [], []
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def mapped(p): return Vector((-p.x,p.z,p.y))
def nums(v): return ','.join(format(float(c),'.7g') for c in v)

for ident, style, dimensions, reference in JOBS:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 w,d,h = dimensions; fy=-d/2+.65; wall_h=h-2.4
 mats={}; lights=[]; sign=None
 for name,(rgb,family) in PALETTE.items():
  mat=bpy.data.materials.new(name);mat.diffuse_color=(*(c/255 for c in rgb),1)
  mat['family']=family;mat.use_nodes=True
  bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=tuple((c/255)**2.2 for c in rgb)+(1,)
  bs.inputs['Roughness'].default_value=.75 if name not in ('brass','glass') else .32
  bs.inputs['Metallic'].default_value=.7 if name in ('iron','brass') else 0
  mats[name]=mat
 def cube(name,size,at,role,bevel=.055):
  bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.dimensions=size
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[role])
  if bevel:
   mod=o.modifiers.new('Authored softened edge','BEVEL');mod.width=min(bevel,min(size)/4);mod.segments=2
   o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
  return o
 def cylinder(name,radius,depth,at,role,axis='Z',vertices=12):
  bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=at)
  o=bpy.context.object;o.name=name;o.data.materials.append(mats[role])
  if axis=='Y':o.rotation_euler[0]=math.pi/2
  if axis=='X':o.rotation_euler[1]=math.pi/2
  return o
 def beam(name,a,b,width,role):
  a,b=Vector(a),Vector(b);o=cube(name,(width,width,(b-a).length),(a+b)/2,role,width*.2)
  o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
 def vent(x,y,z,width=3.2,height=2.3):
  cube('Vent frame',(width,.28,height),(x,y,z),'cream')
  cube('Vent recess',(width-.35,.3,height-.35),(x,y-.16,z),'iron')
  for i in range(5):cube('Vent louvre',(width-.55,.16,.12),(x,y-.34,z-height*.32+i*height*.16),'iron',.025)
 def lamp(x,z,y=fy-.25):
  lights.append(Vector((x,y-.8,z+.05)))
  cube('Lamp backplate',(.6,.18,1.15),(x,y,z),'iron')
  beam('Lamp bracket',(x,y,z+.45),(x,y-.5,z+.65),.12,'iron')
  cube('Lamp warm lens',(.44,.38,.7),(x,y-.52,z+.05),'amber',.09)
  cube('Lamp cap',(.72,.64,.18),(x,y-.52,z+.48),'iron')
  cube('Lamp foot',(.6,.52,.12),(x,y-.52,z-.34),'brass')
 def planter(x,z,y=fy-.45,width=3):
  cube('Window planter',(width,.8,.6),(x,y,z),'wood')
  cube('Planter soil',(width-.2,.6,.12),(x,y,z+.33),'iron')
  for i in range(4):
   bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.4,location=(x-width*.33+i*width*.22,y,z+.6+(i%2)*.15))
   o=bpy.context.object;o.name='Planter leaves';o.scale=(1,.75,.8);o.data.materials.append(mats['leaf'])
 def window(x,z,width=3.8,height=4.7,lit=False,shutters=False,y=fy-.1):
  direction=-1 if y<0 else 1
  def offset(value):return y+direction*value
  cube('Window deep reveal',(width+.6,.4,height+.6),(x,y,z),'cream')
  cube('Window shadow',(width,.43,height),(x,offset(.21),z),'iron')
  cube('Window glass',(width-.45,.08,height-.45),(x,offset(.44),z),'amber' if lit else 'glass',.02)
  cube('Window mullion',(.15,.17,height-.35),(x,offset(.54),z),'wood',.025)
  cube('Window transom',(width-.3,.17,.15),(x,offset(.54),z+.1),'wood',.025)
  cube('Window projecting sill',(width+.9,.85,.28),(x,offset(.23),z-height/2-.38),'cream')
  for side in (-1,1) if shutters else ():
   sx=x+side*(width/2+.78);cube('Walnut shutter',(1.05,.22,height),(sx,offset(.15),z),'wood')
   for slat in range(7):cube('Shutter slat',(.85,.15,.1),(sx,offset(.32),z-height*.39+slat*height*.13),'cream',.02)
 def door(x,width=3.2,height=7,role='teal'):
  cube('Door stone architrave',(width+.7,.5,height+.45),(x,fy-.1,height/2+.3),'cream')
  cube('Door recess',(width+.12,.5,height),(x,fy-.39,height/2+.3),'iron')
  cube('Door panel',(width-.25,.22,height-.2),(x,fy-.65,height/2+.3),role)
  cube('Door upper glazing',(width-.8,.1,height*.32),(x,fy-.79,height*.73),'glass')
  cube('Door brass handle',(.12,.18,.7),(x+width*.28,fy-.92,height*.42),'brass',.04)
  cube('Door threshold',(width+1,1.4,.2),(x,fy-.48,.14),'stone')
 def awning(x,z,width):
  for i in range(8):
   step=width/8;xx=x-width/2+(i+.5)*step
   o=cube('Canvas slope',(step-.012,1.7,.14),(xx,fy-.82,z),'coral' if i%2 else 'cream',.035);o.rotation_euler[0]=.2
   cube('Canvas valance',(step-.02,.16,.38),(xx,fy-1.62,z-.3),'coral' if i%2 else 'cream',.11)
 def crate(x,y,z=.9):
  cube('Crate body',(1.7,1.5,1.7),(x,y,z),'wood')
  for a in (-.6,.6):cube('Crate binding',(.16,1.6,1.8),(x+a,y,z),'iron',.02)
  for a in (-.5,0,.5):cube('Crate plank',(1.65,.1,.08),(x,y-.78,z+a),'cream',.02)

 # A fixed masonry envelope, articulated by brick bays, pilasters and parapets.
 cube('Stone plinth',(w,d,.55),(0,0,.275),'stone',.1)
 shell_role='teal' if style=='relay' else 'brick'
 cube('Masonry shell',(w-1.2,d-1.2,wall_h),(0,0,wall_h/2+.5),shell_role,.09)
 cube('Roof deck',(w-1.4,d-1.4,.35),(0,0,wall_h+.6),'iron')
 for x in (-w/2+.55,w/2-.55):
  cube('Corner dressed pier',(1.15,d-1.1,1.1),(x,0,.85),'cream')
  for yy in (-d/2+.55,d/2-.55):
   cube('Corner pilaster',(1.05,1.05,wall_h),(x,yy,wall_h/2+.6),'cream',.1)
   cube('Coping corner',(1.5,1.5,.45),(x,yy,wall_h+1.4),'cream',.1)
 for y in (-d/2+.48,d/2-.48):
  cube('Roof parapet',(w-1,.6,.9),(0,y,wall_h+1),'brick')
  cube('Coping stone',(w-.5,.95,.32),(0,y,wall_h+1.55),'cream',.08)
 for x in (-w/2+.48,w/2-.48):
  cube('Parapet return',(.6,d-1,.9),(x,0,wall_h+1),'brick')
  cube('Coping return',(.95,d-.5,.32),(x,0,wall_h+1.55),'cream',.08)
 # Roof equipment and orderly conduits have actual volume and bevelled corners.
 cube('Roof ventilation housing',(3,2.4,1.2),(-w*.26,d*.2,wall_h+1.35),'cream')
 for i in range(7):cube('Roof vent fin',(2.45,.12,.1),(-w*.26,d*.2-.85+i*.28,wall_h+2),'iron',.02)
 cylinder('Rainwater pipe',.14,wall_h,(w/2-.82,fy-.2,wall_h/2+.5),'iron')
 for z in (2,6,wall_h-1):cube('Pipe strap',(.5,.48,.14),(w/2-.82,fy-.2,z),'brass',.025)
 for side in (-1,1):
  cube('Side repair plate',(.16,2,2.2),(side*(w/2-.52),d*.2,wall_h*.5),'teal')

 if style=='cold_store':
  width=14;cube('Loading door surround',(width+1,.6,11),(0,fy-.2,5.9),'cream')
  cube('Loading door recess',(width+.2,.4,10.4),(0,fy-.56,5.8),'iron')
  for side in (-1,1):
   xx=side*3.5;cube('Insulated loading door',(6.7,.3,10),(xx,fy-.86,5.7),'teal')
   vent(xx,fy-1.06,8.4,2.5,1.6)
   cube('Door pull',(.18,.28,1.7),(side*.55,fy-1.14,5),'brass')
  cube('Cold store fascia',(17,.35,2),(0,fy-.3,12.7),'teal')
  sign=((0,fy-.50,12.7),(15,1.3),'CINDER COLD STORAGE')
  for side in (-1,1):
   cube('Teal service strip',(2.2,.15,10.5),(side*(w/2-2.25),fy-.15,6.2),'teal')
   for z in (1.5,3.8,6.1,8.4,10.7):
    cube('Corner quoins',(1.55,.35,.65),(side*(w/2-.7),fy-.17,z),'cream')
   for z in (2,5,8):
    cube('Loading door hinge',(.4,.24,.65),(side*6.3,fy-1.1,z),'brass')
   cube('Door lower reinforcement',(6.4,.12,.7),(side*3.5,fy-1.08,1.6),'iron')
  for xx in (-8.4,8.4):lamp(xx,10.1)
  door(w*.36,3,6.8);crate(-w*.38,fy-.5);crate(-w*.38,fy-.5,2.7)
  # Side condenser, insulated return pipe and two glazed roof hatches.
  cube('Condenser',(1.1,5.8,5.7),(w/2-.3,1,7),'cream')
  for z in range(5):cube('Condenser grille',(.18,5.2,.18),(w/2+.32,1,5.3+z*.8),'iron')
  for yy in (-3,4):cylinder('Insulated refrigerant riser',.32,8,(w/2-.1,yy,5.5),'cream')
  for xx in (-6,6):
   cube('Roof hatch frame',(6,4,.35),(xx,0,wall_h+.95),'cream')
   cube('Roof hatch glass',(5.3,3.3,.15),(xx,0,wall_h+1.2),'glass')
 elif style=='flats':
  cube('Entry sign fascia',(6.5,.3,1.4),(0,fy-.5,9.5),'teal')
  sign=((0,fy-.68,9.5),(5.9,1.05),'QUAYSIDE FLATS')
  # Individual cream/teal bays, deep shutters and occupied warm windows.
  bays=(-w*.32,0,w*.32)
  for i,x in enumerate(bays):
   cube('Painted upper bay',(w/3-.45,.15,wall_h*.55),(x,fy-.06,wall_h*.69),('teal','cream','coral')[i])
   window(x,wall_h*.71,3.8,5.3,i!=1,True)
   planter(x,wall_h*.71-3.2,width=3.8)
  door(0,3.4,7.7)
  for xx in (-w*.31,w*.31):
   cube('Shopfront reveal',(w*.26,.35,7.6),(xx,fy-.3,4.35),'cream')
   cube('Shop glazing',(w*.26-.55,.16,6.8),(xx,fy-.52,4.4),'glass')
   for z in range(3,8):cube('Shutter seam',(w*.26-.6,.1,.08),(xx,fy-.65,z),'teal',.02)
   awning(xx,8.8,w*.3);lamp(xx+w*.13,7.7)
  for xx in (-w*.22,w*.22):
   beam('Balcony rail',(xx-2,fy-.75,wall_h*.59),(xx+2,fy-.75,wall_h*.59),.13,'iron')
   for i in range(5):beam('Balcony upright',(xx-2+i,fy-.75,wall_h*.51),(xx-2+i,fy-.75,wall_h*.59),.1,'iron')
  beam('Laundry line',(-w*.3,d*.25,wall_h+2),(w*.3,d*.25,wall_h+2),.055,'iron')
  for i in range(4):cube('Laundry cloth',(1.3,.05,1.1),(-2.7+i*1.8,d*.25,wall_h+1.4),('cream','coral','teal','cream')[i],.025)
 elif style=='laundry':
  cube('Coral sign fascia',(w-2,.4,2.4),(0,fy-.35,wall_h-.9),'coral')
  sign=((0,fy-.58,wall_h-.9),(w-3,1.5),'TIDEWASH LAUNDRY')
  x0=-w*.16;ww=w*.59
  cube('Laundry display frame',(ww+.5,.6,6.6),(x0,fy-.3,4.7),'cream')
  cube('Laundry display interior',(ww,.15,6),(x0,fy-.65,4.7),'iron')
  for i in range(3):
   x=x0+(i-1)*ww*.3
   cube('Washer body',(ww*.28,.45,4.5),(x,fy-.83,4.2),'cream')
   cylinder('Washer brass rim',ww*.12,.16,(x,fy-1.1,4.2),'brass','Y',20)
   cylinder('Washer drum',ww*.095,.19,(x,fy-1.2,4.2),'iron','Y',20)
   cylinder('Washer reflection',ww*.071,.03,(x,fy-1.31,4.2),'glass','Y',20)
   cube('Washer controls',(.65,.1,.22),(x,fy-1.12,5.9),'teal')
  door(w*.34,2.8,7.4);lamp(w*.39,8.4);lamp(-w*.42,8.4)
  planter(-w*.4,.7,width=2);planter(w*.42,.7,width=1.7)
 elif style=='relay':
  cube('Relay name fascia',(7.6,.25,.9),(0,fy-.4,wall_h-.35),'iron')
  sign=((0,fy-.55,wall_h-.35),(7.2,.65),'QUAY RELAY')
  door(-w*.19,3.2,6.5);vent(w*.25,fy-.2,6,3.2,2.1)
  cube('Electrical service cabinet',(3.3,.65,3.1),(w*.24,fy-.4,2.2),'cream')
  cube('Status recess',(.8,.16,.9),(w*.24,fy-.8,2.7),'iron')
  cube('Status lens',(.4,.12,.5),(w*.24,fy-.92,2.7),'amber')
  for x in (-2.3,2.3):
   cylinder('Ceramic terminal foot',.55,.22,(x,1,wall_h+.95),'cream')
   for z in (1.12,1.37,1.62):cylinder('Ceramic insulator',.42,.14,(x,1,wall_h+z),'wood')
   cylinder('Insulator pin',.12,.4,(x,1,wall_h+1.86),'iron')
  beam('Relay cable',(-2.3,1,wall_h+2.04),(2.3,1,wall_h+2.04),.1,'iron');lamp(-w*.24,7.8)
 elif style=='depot':
  cube('Depot name fascia',(11,.3,1.5),(0,fy-.4,12),'teal')
  sign=((0,fy-.58,12),(10.4,1.1),'DOCKLINE DEPOT')
  # Raised center roof, corrugated upper walls, timber doors and dock hoist.
  for x in range(-int(w/2)+2,int(w/2)-1):cube('Teal corrugation',(.35,d-1.1,wall_h*.43),(x,0,wall_h*.75),'teal',.02)
  for side in (-1,1):
   o=cube('Sloped roof',(w/2-.1,d-1,.25),(side*w*.235,0,h-1.1),'iron');o.rotation_euler[1]=side*.13
  width=w*.52;cube('Timber loading surround',(width+1,.5,10),(0,fy-.3,5.5),'cream')
  for i in range(12):cube('Loading door plank',(width/12-.045,.28,9.1),(-width/2+(i+.5)*width/12,fy-.65,5.4),'wood',.025)
  for side in (-1,1):
   beam('Door diagonal brace',(side*.25,fy-.86,1.1),(side*(width/2-.3),fy-.86,9.5),.24,'cream')
   lamp(side*(width/2+.6),10.4)
  door(w*.37,3,7);vent(0,fy-.2,wall_h-1.6,4,1.8)
  beam('Hoist post',(-w*.37,fy,1),(-w*.37,fy,wall_h),.55,'wood')
  beam('Hoist boom',(-w*.37,fy,wall_h),(-w*.37-2,fy-1.2,wall_h),.4,'wood')
  beam('Hoist suspension',(-w*.37-2,fy-1.2,wall_h),(-w*.37-2,fy-1.2,wall_h-4),.07,'iron')
  crate(-w*.37-2,fy-1.2,wall_h-4.8)
  crate(w*.4,fy-.3);crate(-w*.43,fy-.15)
 # Side/rear detail: ordinary windows, pipe collars and repairs, not blank cubes.
 for x in (-w*.28,w*.28):window(x,wall_h*.64,3.2,3.7,False,False,y=d/2-.52)
 # Deliberate metal fasteners and repaired paint chips break up broad panels.
 # Authored geometry only; no text is baked into the material.
 for obj in list(bpy.context.scene.objects):
  if obj.type!='MESH' or not obj.data.materials:continue
  if obj.data.materials[0].name not in ('teal','coral') or obj.dimensions.y>.5 or obj.dimensions.x<2:continue
  sx,sy,sz=obj.dimensions;cx,cy,cz=obj.location
  for side in (-1,1):
   for zz in (-1,1):
    cylinder('Panel fixing',.07,.045,(cx+side*(sx/2-.18),cy-sy/2-.025,cz+zz*(sz/2-.18)),'brass','Y',8)
   cube('Paint edge wear',(.36,.018,.075),(cx+side*(sx/2-.35),cy-sy/2-.035,cz-sz*.35),'wood',.01)
 # Fit all details into the registered overall envelope without moving its pivot.
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 low=Vector(tuple(min(p[k] for p in pts) for k in range(3)));high=Vector(tuple(max(p[k] for p in pts) for k in range(3)))
 scale=min(w/(high.x-low.x),d/(high.y-low.y),h/(high.z-low.z))
 origin=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
 for o in meshes:o.location=(o.location-origin)*scale;o.scale*=scale
 bpy.context.view_layer.update()
 blend=OUT/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
 deps=bpy.context.evaluated_depsgraph_get();groups=defaultdict(list)
 for o in meshes:
  evaluated=o.evaluated_get(deps);mesh=evaluated.to_mesh();mesh.calc_loop_triangles();mat=o.data.materials[0];role=mat.name
  for tri in mesh.loop_triangles:
   row=[];normal=(o.matrix_world.to_3x3().inverted().transposed()@tri.normal).normalized();dominant=max(range(3),key=lambda k:abs(normal[k]))
   axes=[k for k in range(3) if k!=dominant]
   for i in (0,1,2):
    p=o.matrix_world@mesh.vertices[tri.vertices[i]].co;n=o.matrix_world.to_3x3().inverted().transposed()@mesh.corner_normals[tri.loops[i]].vector;n.normalize()
    uv=(p[axes[0]]/5,p[axes[1]]/5,0)
    row.append((mapped(p),mapped(n),uv))
   groups[role].append(row)
  evaluated.to_mesh_clear()
 parts=[]
 for role,tris in groups.items():
  points=[p for t in tris for p,n,u in t];lo=Vector(tuple(min(p[k] for p in points) for k in range(3)));hi=Vector(tuple(max(p[k] for p in points) for k in range(3)));center=(lo+hi)/2
  payload=('version 1.01\n'+str(len(tris))+'\n'+'\n'.join(''.join('['+nums(p-center)+']['+nums(n)+']['+nums(u)+']' for p,n,u in t) for t in tris)+'\n').encode('ascii')
  sha=hashlib.sha256(payload).hexdigest();name=ident+'_'+role+'_'+sha[:12]+'.mesh';(CONTENT/name).write_bytes(payload)
  rgb,family=PALETTE[role]
  parts.append(dict(name=role,bone='',center=list(center),size=list(hi-lo),color=[c/255 for c in rgb] if role not in ('brick','wood') else [1,1,1],surface_family='light' if role=='amber' else 'authored_'+role,triangles=len(tris),sha256=sha,uri='rbxasset://needle-quay/architecture-artbook/'+name))
 record=dict(id=ident,kind='authored_architecture',source=blend.relative_to(ROOT).as_posix(),source_sha256=digest(blend),triangles=sum(p['triangles'] for p in parts),parts=parts,joints={},dimensions=list(dimensions))
 record['coordinate_basis']='blender_to_roblox_front_minus_z_v2'
 record['lights']=[list(mapped((point-origin)*scale)) for point in lights]
 if sign:
  at,size,title=sign
  record['sign']={'position':list(mapped((Vector(at)-origin)*scale)),'size':[value*scale for value in size],'text':title if ident.startswith('NQ-BLD') else ('HARBOR STUDIOS' if style=='flats' else 'WASH & FOLD')}
 records.append(record);receipts.append(dict(id=ident,reference='assets/concepts/needle-quay/'+reference,reference_sha256=digest(ROOT/'assets/concepts/needle-quay'/reference),source=record['source'],sha256=record['source_sha256'],triangles=record['triangles'],stage='DCC_CLEAN_PENDING_ART_APPROVAL',envelope=dimensions,fit_scale=scale,uploads=0))
 print('AUTHORED',ident,record['triangles'],flush=True)
catalog=ROOT/'src/shared/QuayArchitectureCatalog.luau'
catalog.write_text('return game:GetService("HttpService"):JSONDecode([=['+json.dumps(records,separators=(',',':'))+']=])\n')
(OUT/'manifest.json').write_text(json.dumps(dict(assets=records,provenance=receipts,materials=PALETTE,uploads=0),indent=2))
