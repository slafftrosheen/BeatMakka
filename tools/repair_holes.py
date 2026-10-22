import bpy, bmesh, json, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:\Users\slavd\BeatMaka')
OUT=ROOT/'assets'/'cleaned'
COLORS={'teal':(47/255,92/255,88/255,1),'faded':(111/255,145/255,134/255,1),'cream':(232/255,216/255,183/255,1),'amber':(243/255,182/255,95/255,1),'walnut':(121/255,81/255,59/255,1),'graphite':(44/255,48/255,49/255,1),'leaf':(91/255,128/255,78/255,1),'leaflight':(132/255,160/255,91/255,1),'brass':(.62,.40,.16,1)}
M={}
for n,c in COLORS.items():
    m=bpy.data.materials.new('FZ Solid '+n.title()); m.diffuse_color=c; m.use_nodes=True; m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=c; M[n]=m

def reset():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def assign(o,mat): o.data.materials.clear(); o.data.materials.append(mat); return o
def bevel(o,w):
    mod=o.modifiers.new('Softened production edges','BEVEL'); mod.width=w; mod.segments=1
    bpy.context.view_layer.objects.active=o; bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.ops.object.modifier_apply(modifier=mod.name); o.select_set(False)
def box(name,dims,loc,mat,bw=.03):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=name; o.dimensions=dims; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); assign(o,mat)
    if bw: bevel(o,bw)
    return o
def cyl(name,r,depth,loc,mat,axis='Y',verts=12):
    rot=(math.pi/2,0,0) if axis=='Y' else ((0,math.pi/2,0) if axis=='X' else (0,0,0))
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=loc,rotation=rot); o=bpy.context.object; o.name=name; return assign(o,mat)
def orient_pivot(meshes,pivot,target):
    for o in meshes:
        bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    mn=[min(p[i] for p in pts) for i in range(3)]; mx=[max(p[i] for p in pts) for i in range(3)]
    off=Vector(((mn[0]+mx[0])/2,(mn[1]+mx[1])/2,mn[2] if pivot=='floor' else (mx[1] if pivot=='wall' else mx[2])))
    for o in meshes:
        for v in o.data.vertices:v.co-=off
        o.data.update()
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    mn=[min(p[i] for p in pts) for i in range(3)]; mx=[max(p[i] for p in pts) for i in range(3)]; d=[mx[i]-mn[i] for i in range(3)]
    ratio=[target[i]/d[i] for i in range(3)]
    for o in meshes:
        for v in o.data.vertices:v.co=Vector((v.co.x*ratio[0],v.co.y*ratio[1],v.co.z*ratio[2]))
        o.data.update()
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    mn=[min(p[i] for p in pts) for i in range(3)]; mx=[max(p[i] for p in pts) for i in range(3)]
    shift=Vector(((mn[0]+mx[0])/2,(mn[1]+mx[1])/2,mn[2] if pivot=='floor' else (mx[1] if pivot=='wall' else mx[2])))
    for o in meshes:
        for v in o.data.vertices:v.co-=shift
        o.location=(0,0,0); o.rotation_euler=(0,0,0); o.scale=(1,1,1); o.data.update()
def prep_mesh(o):
    bpy.context.view_layer.objects.active=o; bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.mesh.normals_make_consistent(inside=False); bpy.ops.object.mode_set(mode='OBJECT'); o.select_set(False)
    if not o.data.uv_layers:
        bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
        try:bpy.ops.uv.smart_project(island_margin=.02)
        except Exception:pass
        bpy.ops.object.mode_set(mode='OBJECT'); o.select_set(False)
def emit(aid,pivot,target,notes):
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    orient_pivot(meshes,pivot,target)
    for o in meshes: prep_mesh(o); o['asset_id']=aid; o['stage']='DCC solid-geometry repair; Studio review pending'
    d=OUT/aid; stem=f'{aid}_solid_repair_candidate'; glb=d/(stem+'.glb'); blend=d/(stem+'.blend'); png=d/(stem+'_preview.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',export_materials='EXPORT',export_yup=True,export_apply=True,use_selection=True)
    tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    scene=bpy.context.scene; scene.render.engine='BLENDER_WORKBENCH'; scene.render.resolution_x=768; scene.render.resolution_y=768; scene.render.resolution_percentage=100; scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=True; scene.display.shading.light='STUDIO'; scene.display.shading.show_shadows=True; scene.display.shading.show_cavity=True; scene.display.shading.cavity_type='BOTH'; scene.display.shading.color_type='MATERIAL'
    camd=bpy.data.cameras.new('RepairPreviewCamera'); cam=bpy.data.objects.new('RepairPreviewCamera',camd); scene.collection.objects.link(cam); center=Vector((0,0,target[2]*.5 if pivot=='floor' else 0)); cam.location=(max(target)*.75,-max(target)*2.8,center.z+max(target)*.5); cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler(); camd.type='ORTHO'; camd.ortho_scale=max(target)*1.55; scene.camera=cam; scene.render.filepath=str(png); bpy.ops.render.render(write_still=True)
    return {'asset_id':aid,'glb':glb.relative_to(ROOT).as_posix(),'editable_blend':blend.relative_to(ROOT).as_posix(),'preview':png.relative_to(ROOT).as_posix(),'dimensions_blender_xyz':target,'triangles':tris,'mesh_objects':len(meshes),'repair_notes':notes,'stage':'DCC solid-geometry repair; Studio import and visual acceptance pending'}

def leaf(name,base,tip,width,mat):
    direction=(tip-base).normalized(); side=direction.cross(Vector((0,0,1)))
    if side.length<.05:side=direction.cross(Vector((0,1,0)))
    side.normalize(); verts=[]; faces=[]; rows=3
    for i in range(rows):
        t=i/(rows-1); center=base.lerp(tip,t)+Vector((0,0,.06*math.sin(math.pi*t))); half=width*max(.06,math.sin(math.pi*t)**.72)
        for u in (-1,0,1):verts.append(center+side*(half*u)+Vector((0,0,.07*(1-abs(u))*math.sin(math.pi*t))))
    for i in range(rows-1):
        a=i*3; faces += [(a,a+3,a+1),(a+1,a+3,a+4),(a+1,a+4,a+2),(a+2,a+4,a+5)]
    me=bpy.data.meshes.new(name+'Mesh'); me.from_pydata(verts,[],faces); me.materials.append(mat); me.update(); o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o)
    sol=o.modifiers.new('Closed leaf thickness','SOLIDIFY'); sol.thickness=.035; sol.offset=0; bpy.context.view_layer.objects.active=o; bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.ops.object.modifier_apply(modifier=sol.name); o.select_set(False)
    return o

def p12():
    reset(); bases=[(-.26,-.12),(.18,-.14),(.02,.18),(-.08,.02),(.28,.12)]; hs=[3.25,3.8,3.55,3.0,3.45]
    for i,((x,y),h) in enumerate(zip(bases,hs)):
        base=Vector((x,y,.06)); top=Vector((x*.25,y*.25,h*.88)); vec=top-base
        bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=.065,radius2=.035,depth=vec.length,location=(base+top)/2); o=bpy.context.object; o.name=f'P12_Stem_{i+1}'; o.rotation_euler=vec.to_track_quat('Z','Y').to_euler(); assign(o,M['leaf'])
        radial=Vector((math.cos(2*math.pi*i/5+.22),math.sin(2*math.pi*i/5+.22),0)); mid=base.lerp(top,.5)
        leaf(f'P12_BroadLeaf_{i+1}',mid+radial*.03,Vector((x+radial.x*(.45+.08*(i%2)),y+radial.y*(.45+.08*(i%2)),h)),.42,M['leaflight'] if i%2==0 else M['leaf'])
        leaf(f'P12_LowerLeaf_{i+1}',base.lerp(top,.34),Vector((x-radial.x*.46,y-radial.y*.46,h*.48)),.34,M['leaf'] if i%2==0 else M['leaflight'])
    return emit('P12','floor',(3,3,4),'Rebuilt the ten leaves as thin closed volumes with no zero-area tip faces; kept five stems and palette, preserving the 550-triangle budget.')

def p14():
    reset()
    box('P14_Walnut_Wall_Backplate',(1.95,.12,2.85),(0,.40,0),M['walnut'],.08)
    box('P14_Teal_Cabinet',(1.78,.78,2.68),(0,-.015,0),M['teal'],.10)
    box('P14_Cream_Front_Rim',(1.58,.06,2.40),(0,-.422,0),M['cream'],.05)
    box('P14_Teal_Face',(1.47,.05,2.28),(0,-.468,0),M['teal'],.04)
    cyl('P14_Socket_Rim',.39,.07,(-.38,-.518,.12),M['brass'],verts=12)
    cyl('P14_Socket_Recess',.30,.045,(-.38,-.555,.12),M['graphite'],verts=12)
    cyl('P14_Status_Bezel',.17,.06,(.48,-.518,.18),M['walnut'],verts=12)
    cyl('P14_Status_Insert',.11,.05,(.48,-.558,.18),M['amber'],verts=12)
    return emit('P14','wall',(2,1,3),'Replaced irregular Tripo shell with closed, beveled cabinet and backplate; rebuilt socket and status details as separate closed solids.')

def i05():
    reset()
    box('I05_Base_Plinth',(2.78,1.82,.45),(0,0,.225),M['walnut'],.08)
    box('I05_Podium_Body',(2.05,1.28,3.12),(0,.08,2.01),M['teal'],.10)
    box('I05_Front_Faceplate',(1.68,.05,2.38),(0,-.585,2.05),M['faded'],.06)
    box('I05_Front_Status_Plate',(.78,.07,.25),(0,-.632,2.60),M['walnut'],.03)
    box('I05_Front_Status_Lens',(.43,.035,.10),(0,-.682,2.60),M['amber'],.018)
    box('I05_Top_Control_Deck',(3,2,.60),(0,0,3.70),M['cream'],.12)
    cyl('I05_Dial_Base',.43,.09,(-.62,-.18,3.985),M['graphite'],axis='Z',verts=16)
    cyl('I05_Dial_Ring',.34,.07,(-.62,-.18,4.025),M['brass'],axis='Z',verts=16)
    cyl('I05_Dial_Knob',.24,.10,(-.62,-.18,4.065),M['teal'],axis='Z',verts=12)
    cyl('I05_Status_Bezel',.19,.075,(.64,-.12,3.99),M['walnut'],axis='Z',verts=12)
    cyl('I05_Status_Insert',.12,.06,(.64,-.12,4.035),M['amber'],axis='Z',verts=12)
    return emit('I05','floor',(3,2,4),'Replaced irregular Tripo podium mesh with a closed plinth, cabinet, faceplate and control deck; all knobs and status details are separate closed solids.')

results=[p12(),p14(),i05()]
path=ROOT/'docs'/'evidence'/'dcc-normalization'/'solid-repair-candidates.json'; path.write_text(json.dumps({'blender_version':bpy.app.version_string,'assets':results},indent=2)+'\n',encoding='utf-8'); print(json.dumps(results,indent=2))
