"""DCC character revisions using the preserved Tori facial/body mesh as a base.

Sana receives authored bun, jacket palette and satchel. Nell receives a dress,
apron, scarf and gray-brown hair. These remain art-review candidates.
"""
import bpy,math,json,numpy as np
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1];D=R/'assets/production/needle-quay/models/refined';M=R/'assets/production/needle-quay/character-maps'
palette=[(.88,.80,.63,1),(.27,.46,.44,1),(.87,.36,.25,1),(.26,.15,.10,1),(.67,.48,.24,1),(.30,.23,.19,1),(.43,.34,.28,1),(.12,.14,.14,1)]
for slug,height,width in [('SANA',5.9,.93),('NELL',5.7,1.06)]:
 bpy.ops.wm.open_mainfile(filepath=str(D/'NQ-NPC-TORI.blend'));rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');body=next(o for o in bpy.context.scene.objects if o.type=='MESH');ratio=height/5.8
 for v in body.data.vertices:v.co=Vector((v.co.x*ratio*width,v.co.y*ratio,v.co.z*ratio))
 bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
 for b in rig.data.edit_bones:
  b.head=Vector((b.head.x*ratio*width,b.head.y*ratio,b.head.z*ratio));b.tail=Vector((b.tail.x*ratio*width,b.tail.y*ratio,b.tail.z*ratio))
 bpy.ops.object.mode_set(mode='OBJECT')
 source=bpy.data.images.load(str(M/'tori_color.png'),check_existing=False);arr=np.array(source.pixels[:],dtype=np.float32).reshape(1024,1024,4)
 body.data.calc_loop_triangles();uv=body.data.uv_layers.active
 for t in body.data.loop_triangles:
  at=sum((body.data.vertices[v].co for v in t.vertices),Vector())/3;z=at.z/height;x=abs(at.x)/height
  category=None
  if slug=='SANA':
   if .14<z<.45 and x<.16:category='teal'
   elif .54<z<.75:category='jacket'
  else:
   if .36<z<.76 and x>.13:category='teal'
   elif z>.79 and (z>.92 or at.y>0 or x>.11):category='hair'
  if not category:continue
  pts=np.array([uv.data[i].uv[:] for i in t.loops])*1023;x0,y0=np.maximum(0,np.floor(pts.min(axis=0)).astype(int));x1,y1=np.minimum(1023,np.ceil(pts.max(axis=0)).astype(int));yy,xx=np.mgrid[y0:y1+1,x0:x1+1];a,b,c=pts;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(den)<1e-8:continue
  u=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den;v=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;mask=(u>=-.02)&(v>=-.02)&(u+v<=1.02);region=arr[y0:y1+1,x0:x1+1,:3];lum=region.mean(axis=2)
  if category=='jacket':mask &= (region[:,:,1]>region[:,:,0]*1.05) | ((x>.14)&(lum>.34)&(region[:,:,0]<region[:,:,1]*1.25));target=np.array(palette[2][:3])
  elif category=='hair':mask &= lum<.35;target=np.array(palette[6][:3])
  else:
   if slug=='NELL':mask &= region[:,:,0]<region[:,:,1]*1.25
   target=np.array(palette[1][:3])
  painted=np.clip(target[None,None,:]*(.45+lum[:,:,None]*1.5),0,1);region[mask]=painted[mask]
 source.pixels=arr.ravel();source.scale(768,768)
 images={}
 for kind in ('color','normal','rough'):
  original=source if kind=='color' else bpy.data.images.load(str(M/('tori_'+kind+'.png')),check_existing=False)
  original.scale(768,768);data=np.zeros((1024,1024,4),np.float32);data[:,:,3]=1
  data[256:1024,:768]=np.array(original.pixels[:]).reshape(768,768,4)
  for index,color in enumerate(palette):data[:128,index*128:(index+1)*128]=color if kind=='color' else (.5,.5,1,1) if kind=='normal' else (.8,.8,.8,1)
  im=bpy.data.images.new(slug+'_'+kind,1024,1024);im.pixels=data.ravel()
  if kind!='color':im.scale(512,512)
  im.filepath_raw=str(M/(slug.lower()+'_'+kind+'.png'));im.file_format='PNG';im.save();im.pack();images[kind]=im
 for loop in uv.data:loop.uv=loop.uv*.75+Vector((0,.25))
 for material in body.data.materials:
  for node in material.node_tree.nodes:
   if node.type=='TEX_IMAGE' and node.image:
    if 'base_color' in node.image.name:node.image=images['color']
    elif 'normal' in node.image.name:node.image=images['normal']
 # Shared palette UVs give deterministic cloth/leather/metal colors without generated text.
 def finish(o,name,slot,bone):
  for item in bpy.context.selected_objects:item.select_set(False)
  o.select_set(True);bpy.context.view_layer.objects.active=o
  o.name=name;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  material=bpy.data.materials.new(name);material.diffuse_color=palette[slot];o.data.materials.clear();o.data.materials.append(material)
  layer=o.data.uv_layers.active or o.data.uv_layers.new()
  for loop in layer.data:loop.uv=((slot+.5)/8,.0625)
  group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Authored skin attachment','ARMATURE');mod.object=rig;o.parent=rig
  for p in o.data.polygons:p.use_smooth=True
  return o
 def ellipsoid(name,at,size,slot,bone='Head'):
  bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=Vector(at)*height);o=bpy.context.object;o.scale=Vector(size)*height;return finish(o,name,slot,bone)
 def box(name,at,size,slot,bone='LowerTorso'):
  bpy.ops.mesh.primitive_cube_add(size=1,location=Vector(at)*height);o=bpy.context.object;o.dimensions=Vector(size)*height;finish(o,name,slot,bone);b=o.modifiers.new('Soft stitched edges','BEVEL');b.width=.012*height;b.segments=3;return o
 def curve(name,points,radius,slot,bone):
  data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=radius*height;data.bevel_resolution=2;s=data.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
  for p,at in zip(s.bezier_points,points):p.co=Vector(at)*height;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
  o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o)
  for item in bpy.context.selected_objects:item.select_set(False)
  bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');return finish(bpy.context.object,name,slot,bone)
 for sign in (-1,1):ellipsoid('GoldEarStud',(sign*.12,-.018,.84),(.017,.014,.017),4)
 if slug=='SANA':
  ellipsoid('SmoothHairCrown',(0,.018,.915),(.13,.10,.075),5)
  ellipsoid('LowHairBun',(0,.13,.845),(.082,.07,.065),5)
  for i in range(4):curve('SweptHairLock',[(-.09+i*.025,-.065,.94),(-.11+i*.018,-.09,.9),(-.10+i*.012,-.09,.855)],.015,5,'Head')
  box('MarketSatchel',(-.19,-.025,.43),(.16,.105,.18),3)
  box('SatchelFlap',(-.19,-.084,.465),(.165,.018,.09),3)
  box('SatchelBuckle',(-.19,-.099,.445),(.034,.008,.037),4)
  curve('LeatherShoulderStrap',[(.10,-.09,.72),(.02,-.104,.6),(-.10,-.11,.49),(-.19,-.07,.48)],.013,3,'UpperTorso')
 else:
  # Remove the hidden trouser/vest surface under the newly authored dress.
  import bmesh
  bm=bmesh.new();bm.from_mesh(body.data);faces=[]
  for face in bm.faces:
   at=face.calc_center_median();z=at.z/height;x=abs(at.x)/height
   if .13<z<.735 and not(x>.14 and z>.36):faces.append(face)
  bmesh.ops.delete(bm,geom=faces,context='FACES');bm.to_mesh(body.data);bm.free()
  def panel(name,rows,angles,slot,bone):
   vertices=[];faces=[]
   for z,rx,ry in rows:
    for i in range(21):
     angle=angles[0]+(angles[1]-angles[0])*i/20;fold=1+.012*math.sin(i*math.pi/2);vertices.append((math.cos(angle)*rx*height*fold,math.sin(angle)*ry*height*fold,z*height))
   for j in range(len(rows)-1):
    for i in range(20):k=j*21+i;faces.append((k,k+1,k+22,k+21))
   data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);bpy.context.view_layer.objects.active=o;o.select_set(True);finish(o,name,slot,bone)
  panel('TealWorkDress',[(.15,.245,.14),(.26,.22,.125),(.43,.16,.10),(.55,.16,.10),(.70,.145,.09)],(0,math.tau),1,'LowerTorso')
  panel('CreamApronSkirt',[(.20,.244,.145),(.31,.21,.13),(.44,.17,.11)],(math.radians(205),math.radians(335)),0,'LowerTorso')
  panel('ApronBib',[(.445,.17,.115),(.55,.168,.113),(.68,.15,.10)],(math.radians(220),math.radians(320)),0,'UpperTorso')
  box('ApronWaistTie',(0,-.115,.445),(.33,.025,.035),0)
  for sign in (-1,1):box('ApronPocket',(sign*.07,-.14,.32),(.12,.018,.10),0)
  curve('CoralNeckerchief',[(-.07,-.01,.73),(0,-.09,.71),(.07,-.015,.73)],.016,2,'UpperTorso')
  curve('ScarfTail',[(.07,-.08,.71),(.10,-.11,.65),(.085,-.12,.62)],.012,2,'UpperTorso')
  ellipsoid('SoftGrayHairCrown',(0,.018,.93),(.13,.105,.068),6)
  for i in range(3):curve('SoftGrayHairWave',[(-.07+i*.04,-.045,.96),(-.09+i*.04,-.10,.93),(-.11+i*.04,-.11,.89)],.012,6,'Head')
 bpy.ops.wm.save_as_mainfile(filepath=str(D/('NQ-NPC-'+slug+'.blend')))
 (D/('NQ-NPC-'+slug+'.json')).write_text(json.dumps({'id':'NQ-NPC-'+slug,'base':'NQ-NPC-TORI.blend','source_design':f'assets/production/needle-quay/npcs/{slug}-design.png','generator':'tools/build_quay_supporting_characters.py','height_studs':height,'provider_spend':0,'stage':'DCC_AUTHORED_CHARACTER_REVISION_PENDING_ART_REVIEW','art_approved':False},indent=2))
