"""Create deterministic DCC art-repair candidates from preserved B11-B20 sources."""
import bpy, bmesh, json, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUTS=ROOT/'assets/cleaned'
PALETTE={'teal':(47/255,92/255,88/255,1),'faded_teal':(111/255,145/255,134/255,1),'cream':(232/255,216/255,183/255,1),'coral':(202/255,116/255,83/255,1),'amber':(243/255,182/255,95/255,1),'walnut':(121/255,81/255,59/255,1),'graphite':(44/255,48/255,49/255,1),'leaf_dark':(67/255,104/255,69/255,1),'leaf_light':(111/255,145/255,83/255,1)}
CAPS={'P12':550,'P13':500,'P14':400,'I01':300,'I04':650,'I05':800}

def material(name,color,metallic=0.0,roughness=0.72,emission=0.0):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color=color; m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=color; bs.inputs['Metallic'].default_value=metallic; bs.inputs['Roughness'].default_value=roughness
    if emission:
        bs.inputs['Emission Color'].default_value=color; bs.inputs['Emission Strength'].default_value=emission
    return m
M={
 'teal':material('FZ Workshop Teal',PALETTE['teal'],.12),
 'faded_teal':material('FZ Faded Teal',PALETTE['faded_teal'],.08),
 'cream':material('FZ Warm Cream',PALETTE['cream'],.03),
 'coral':material('FZ Dusty Coral',PALETTE['coral'],.08),
 'amber':material('FZ Amber Indicator',PALETTE['amber'],.1,.45,.15),
 'walnut':material('FZ Walnut',PALETTE['walnut'],.02),
 'graphite':material('FZ Graphite',PALETTE['graphite'],.15,.55),
 'leaf_dark':material('FZ Leaf Sage',PALETTE['leaf_dark'],.0,.9),
 'leaf_light':material('FZ Leaf Light',PALETTE['leaf_light'],.0,.9),
 'brass':material('FZ Warm Brass',(0.62,.40,.16,1),.62,.38),
 'indicator_teal':material('FZ Teal Indicator',(0.15,.62,.52,1),.1,.4,.18),
}
def assign(obj,mat):
    obj.data.materials.clear(); obj.data.materials.append(mat); return obj
def bevel(obj,width=.04):
    mod=obj.modifiers.new('Softened production edges','BEVEL'); mod.width=width; mod.segments=1
    bpy.context.view_layer.objects.active=obj; obj.select_set(True); bpy.ops.object.modifier_apply(modifier=mod.name); obj.select_set(False)
def box(name,dims,loc,mat,bevel_width=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=name; o.dimensions=dims; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); assign(o,mat)
    if bevel_width: bevel(o,bevel_width)
    return o
def cyl(name,radius,depth,loc,mat,axis='Y',vertices=16):
    rotation=(math.pi/2,0,0) if axis=='Y' else ((0,math.pi/2,0) if axis=='X' else (0,0,0))
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc,rotation=rotation); o=bpy.context.object; o.name=name; assign(o,mat); return o
def uv(obj):
    if obj.type!='MESH': return
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    try: bpy.ops.uv.smart_project(island_margin=.02)
    except Exception: pass
    bpy.ops.object.mode_set(mode='OBJECT'); obj.select_set(False)
def open_scene():
    # Keep the palette datablocks alive across assets. Factory reset invalidates
    # the cached Material references in M, so clear scene objects in place.
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
def import_model(rel):
    bpy.ops.import_scene.gltf(filepath=str(ROOT/rel)); return [o for o in bpy.context.scene.objects if o.type=='MESH']
def set_base_material(meshes,mat):
    for o in meshes: assign(o,mat)
def extrude_leaf(name,base,tip,width,mat):
    # Broad low-poly leaf with a raised centre ridge; rows follow a gently bowed stem.
    direction=tip-base; length=direction.length; direction.normalize(); side=direction.cross(Vector((0,0,1)))
    if side.length<.05: side=direction.cross(Vector((0,1,0)))
    side.normalize(); verts=[]; faces=[]; rows=7
    for i in range(rows):
        t=i/(rows-1); center=base.lerp(tip,t)+Vector((0,0,.06*math.sin(math.pi*t)))
        half=width*(math.sin(math.pi*t)**.72)
        for u in (-1,0,1): verts.append(center+side*(half*u)+Vector((0,0,.07*(1-abs(u))*math.sin(math.pi*t))))
    for i in range(rows-1):
        a=i*3
        faces += [(a,a+3,a+1),(a+1,a+3,a+4),(a+1,a+4,a+2),(a+2,a+4,a+5)]
    mesh=bpy.data.meshes.new(name+'Mesh'); mesh.from_pydata(verts,[],faces); mesh.materials.append(mat); mesh.update(); o=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(o)
    # add lightweight planar UVs for the unwrapped flat geometry
    layer=mesh.uv_layers.new(name='UVMap')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            vi=mesh.loops[li].vertex_index; layer.data[li].uv=(vi//3/(rows-1),(vi%3)/2)
    return o
def orient_and_pivot(meshes,pivot,expected):
    # Bake each object's placement into its vertices before applying shared
    # bounds scaling. Multi-part scenes include primitives whose geometry is
    # local to an object origin; clearing transforms without baking them moves
    # every part and corrupts exported dimensions and pivots.
    for o in meshes:
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True); bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.select_all(action='DESELECT')
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    mins=[min(p[i] for p in pts) for i in range(3)]; maxs=[max(p[i] for p in pts) for i in range(3)]
    offset=Vector(((mins[0]+maxs[0])/2,(mins[1]+maxs[1])/2,mins[2] if pivot=='floor-center' else ((mins[2]+maxs[2])/2 if pivot=='rear-center' else maxs[2])))
    for o in meshes:
        for v in o.data.vertices: v.co-=offset
        o.data.update()
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    mins=[min(p[i] for p in pts) for i in range(3)]; maxs=[max(p[i] for p in pts) for i in range(3)]
    dims=[maxs[i]-mins[i] for i in range(3)]
    ratios=[expected[i]/dims[i] for i in range(3)]
    # scale meshes about the established pivot and then re-anchor the requested pivot surfaces
    for o in meshes:
        for v in o.data.vertices: v.co=Vector((v.co.x*ratios[0],v.co.y*ratios[1],v.co.z*ratios[2]))
        o.data.update()
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    mins=[min(p[i] for p in pts) for i in range(3)]; maxs=[max(p[i] for p in pts) for i in range(3)]
    if pivot=='floor-center': shift=Vector(((mins[0]+maxs[0])/2,(mins[1]+maxs[1])/2,mins[2]))
    elif pivot=='rear-center': shift=Vector(((mins[0]+maxs[0])/2,maxs[1],(mins[2]+maxs[2])/2))
    else: shift=Vector(((mins[0]+maxs[0])/2,maxs[1],maxs[2]))
    for o in meshes:
        for v in o.data.vertices: v.co-=shift
        o.location=(0,0,0); o.rotation_euler=(0,0,0); o.scale=(1,1,1); o.data.update()
def save_candidate(aid,source,pivot,target,notes):
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    if not meshes: raise RuntimeError(f'{aid}: no mesh output')
    orient_and_pivot(meshes,pivot,target)
    for o in meshes:
        o['asset_id']=aid; o['stage']='DCC repaired geometry and art-detail candidate'; uv(o)
    outdir=OUTS/aid; outdir.mkdir(parents=True,exist_ok=True); stem=f'{aid}_art_repair_candidate'
    glb=outdir/f'{stem}.glb'; blend=outdir/f'{stem}.blend'; preview=outdir/f'{stem}_preview.png'
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',export_materials='EXPORT',export_yup=True,export_apply=True,use_selection=True)
    scene=bpy.context.scene; scene.render.engine='BLENDER_WORKBENCH'; scene.render.resolution_x=768; scene.render.resolution_y=768; scene.render.resolution_percentage=100; scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=True
    scene.display.shading.light='STUDIO'; scene.display.shading.show_shadows=True; scene.display.shading.show_cavity=True; scene.display.shading.cavity_type='BOTH'; scene.display.shading.color_type='MATERIAL'; scene.display.shading.background_type='WORLD'
    target_z=target[2]*.5 if pivot=='floor-center' else (-target[2]*.5 if pivot=='upper-hinge' else 0)
    camdata=bpy.data.cameras.new('ArtRepairPreviewCamera'); cam=bpy.data.objects.new('ArtRepairPreviewCamera',camdata); scene.collection.objects.link(cam); cam.location=(max(target)*.8,-max(target)*2.5,target_z+target[2]*.55); cam.rotation_euler=(Vector((0,0,target_z))-cam.location).to_track_quat('-Z','Y').to_euler(); camdata.type='ORTHO'; camdata.ortho_scale=max(target)*1.48; scene.camera=cam; scene.render.filepath=str(preview); bpy.ops.render.render(write_still=True)
    # count the evaluated export geometry, including active modifiers
    tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    return {'asset_id':aid,'source_glb':source,'repaired_glb':glb.relative_to(ROOT).as_posix(),'editable_blend':blend.relative_to(ROOT).as_posix(),'preview':preview.relative_to(ROOT).as_posix(),'dimensions_blender_xyz':list(target),'pivot':pivot,'triangles':tris,'triangle_cap':CAPS[aid],'within_triangle_cap':tris<=CAPS[aid],'mesh_objects':len(meshes),'materials':sorted({m.name for o in meshes for m in o.data.materials if m}),'uv_layers':sorted({u.name for o in meshes for u in o.data.uv_layers}),'repair_notes':notes,'stage':'DCC art-detail candidate; visual/art and Studio/runtime acceptance pending'}

def create_P12():
    aid='P12'; open_scene(); objs=[]
    # Five sturdy stems form a compact, reusable cluster with broad overlapping leaves.
    bases=[(-.26,-.12),(.18,-.14),(.02,.18),(-.08,.02),(.28,.12)]
    heights=[3.25,3.8,3.55,3.0,3.45]
    for i,((x,y),h) in enumerate(zip(bases,heights)):
        top=Vector((x*.25,y*.25,h*.88)); base=Vector((x,y,.06)); mid=base.lerp(top,.5)
        # tapered two-part stem, kept inside the 3 x 4 x 3 contract
        vec=top-base; bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=.065,radius2=.035,depth=vec.length,location=(base+top)/2); stem=bpy.context.object; stem.name=f'P12_Stem_{i+1}'; stem.rotation_euler=vec.to_track_quat('Z','Y').to_euler(); assign(stem,M['leaf_dark']); objs.append(stem)
        angle=2*math.pi*i/5+.22; radial=Vector((math.cos(angle),math.sin(angle),0)); start=mid+radial*.03
        tip=Vector((x+radial.x*(.45+.08*(i%2)),y+radial.y*(.45+.08*(i%2)),h))
        objs.append(extrude_leaf(f'P12_BroadLeaf_{i+1}',start,tip,.42,M['leaf_light'] if i%2==0 else M['leaf_dark']))
        # a lower leaf adds fullness without a pot or extra scene dressing
        lowtip=Vector((x-radial.x*.46,y-radial.y*.46,h*.48))
        objs.append(extrude_leaf(f'P12_LowerLeaf_{i+1}',base.lerp(top,.34),lowtip,.34,M['leaf_dark'] if i%2==0 else M['leaf_light']))
    return save_candidate(aid,'Tripo P12 raw candidate preserved; DCC-built broad-leaf cluster replaces unstable leaf forms','floor-center',(3,3,4),'Rebuilt as a reusable plant-only cluster with ten broad ridged leaves and five stems; no pot; low transparency; no leaf collision; shared sage palette.')
def create_P13():
    aid='P13'; open_scene(); objs=[]
    # wall-sconce core points out from a rear-center mounting plane at y=0
    objs.append(box('P13_Walnut_WallPlate',(.85,.12,.85),(0,-.06,0),M['walnut'],.07))
    objs.append(box('P13_Teal_Mount',( .42,.18,.42),(0,-.18,0),M['teal'],.05))
    objs.append(box('P13_Arm',(.16,.62,.16),(0,-.52,.08),M['faded_teal'],.04))
    # wide enamel shade, simple tapered shell and separate amber diffuser
    bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=.68,radius2=.27,depth=.48,location=(0,-.96,-.1),rotation=(math.pi/2,0,0)); shade=bpy.context.object; shade.name='P13_Cream_Enamel_Shade'; assign(shade,M['cream']); objs.append(shade)
    cyl('P13_Teal_Shade_Rim',.69,.07,(0,-1.20,-.1),M['teal'],axis='Y',vertices=16); objs.append(bpy.context.object)
    cyl('P13_Amber_Diffuser',.37,.045,(0,-1.27,-.1),M['amber'],axis='Y',vertices=16); objs.append(bpy.context.object)
    return save_candidate(aid,'Tripo P13 raw candidate preserved; DCC rebuild resolves the wall-mount orientation','rear-center',(1.5,1.5,2),'Rebuilt wall sconce with an actual rear wall plate, central mounting boss, short arm, cream shade and separate amber diffuser; mounting plane and light core are aligned.')
def create_I01():
    aid='I01'; open_scene(); objs=[]
    # hinge at origin; hanging plate extends downward to z=-2 and toward the player along -Y
    cyl('I01_Fixed_Hinge_Pin',.075,.5,(0,-.02,-.04),M['brass'],axis='X',vertices=8); objs.append(bpy.context.object)
    box('I01_Fixed_Wall_Mount',(.56,.12,.24),(0,-.05,-.12),M['walnut'],.04); objs.append(bpy.context.object)
    box('I01_Fixed_Hinge_Lugs',(.11,.16,.42),(0,-.10,-.18),M['teal'],.03); objs.append(bpy.context.object)
    box('I01_Swinging_Sign_Body',(2.62,.17,1.70),(0,-.15,-1.12),M['teal'],.10); objs.append(bpy.context.object)
    # broad high-contrast but text-free sound plate on the sign face
    cyl('I01_Swinging_Strike_Plate',.48,.055,(0,-.265,-1.16),M['brass'],axis='Y',vertices=8); objs.append(bpy.context.object)
    cyl('I01_Swinging_Strike_Centre',.30,.035,(0,-.305,-1.16),M['walnut'],axis='Y',vertices=8); objs.append(bpy.context.object)
    # trim strips signal the sign face without any language-dependent artwork
    box('I01_Swinging_Cream_Upper_Trim',(2.18,.035,.07),(0,-.252,-.40),M['cream'],.02); objs.append(bpy.context.object)
    return save_candidate(aid,'Tripo I01 raw candidate preserved; sign and mount rebuilt as a hinged assembly','upper-hinge',(3,.3,2),'Separate fixed mount and swinging teal sign plate with upper hinge pivot, oversized brass strike plate and blank face ready for G04 status graphics.')
def create_I04():
    aid='I04'; open_scene(); objs=[]
    objs += [box('I04_Walnut_Wall_Backplate',(2.92,.12,3.88),(0,-.06,0),M['walnut'],.1),box('I04_Teal_Cabinet',(2.72,1.32,3.66),(0,-.78,0),M['teal'],.12),box('I04_Cream_Faceplate',(2.40,.08,3.34),(0,-1.445,0),M['cream'],.08)]
    # Four independent large indicators for explicit state changes
    positions=[(-.62,.72),(.62,.72),(-.62,-.12),(.62,-.12)]
    colors=[M['amber'],M['indicator_teal'],M['coral'],M['cream']]
    for i,((x,z),mat) in enumerate(zip(positions,colors),1):
        cyl(f'I04_Indicator_{i}_Socket',.30,.07,(x,-1.50,z),M['graphite'],axis='Y',vertices=12); objs.append(bpy.context.object)
        cyl(f'I04_Indicator_{i}_Lens',.22,.05,(x,-1.56,z),mat,axis='Y',vertices=12); objs.append(bpy.context.object)
    cyl('I04_Dial_Graphite_Base',.39,.07,(0,-1.50,-1.18),M['graphite'],axis='Y',vertices=16); objs.append(bpy.context.object)
    cyl('I04_Dial_Brass_Ring',.31,.055,(0,-1.56,-1.18),M['brass'],axis='Y',vertices=16); objs.append(bpy.context.object)
    cyl('I04_Dial_Teal_Knob',.22,.08,(0,-1.61,-1.18),M['faded_teal'],axis='Y',vertices=12); objs.append(bpy.context.object)
    return save_candidate(aid,'Tripo I04 raw candidate preserved; interactive wall panel rebuilt to include authored states','rear-center',(3,1.5,4),'Added four separate colored indicator lenses and a separate tuning dial on a cream/teal cabinet; all state elements are geometric parts, not baked labels.')
def decorate_imported(aid,source,pivot,target,details):
    open_scene(); meshes=import_model(source); set_base_material(meshes,M['teal'])
    # Imported model already has exact bounds and pivot; keep a slight inset on the body front to reserve space for flush details.
    for o in meshes:
        for v in o.data.vertices:
            if aid=='P14': v.co.y*=.94
            elif aid=='I05': v.co.y*=.96
        o.data.update()
    parts=[]
    if aid=='P14':
        # outer ring plus a large dark socket and a physically separate warm status lens
        cyl('P14_Socket_Rim',.36,.06,(-.36,-.96,.02),M['brass'],axis='Y',vertices=8); parts.append(bpy.context.object)
        cyl('P14_Socket_Recess',.285,.07,(-.36,-.935,.02),M['graphite'],axis='Y',vertices=8); parts.append(bpy.context.object)
        cyl('P14_Status_Bezel',.16,.055,(.48,-.945,.10),M['walnut'],axis='Y',vertices=8); parts.append(bpy.context.object)
        cyl('P14_Status_Insert',.105,.05,(.48,-.99,.10),M['amber'],axis='Y',vertices=8); parts.append(bpy.context.object)
        return save_candidate(aid,source,pivot,target,'Added a separated oversized front socket and a separate amber status insert; original shell and raw Tripo source are retained.')
    if aid=='I05':
        # Seat status details into the top and recessed front face of the podium.
        top=Vector((.68,-.20,3.5377)); normal=Vector((0,-.669,.7435)).normalized()
        bezel=cyl('I05_Status_Bezel',.20,.055,top+normal*.0275,M['graphite'],axis='Z',vertices=12)
        bezel.rotation_euler=normal.to_track_quat('Z','Y').to_euler(); parts.append(bezel)
        insert=cyl('I05_Status_Insert',.135,.04,top+normal*.075,M['amber'],axis='Z',vertices=12)
        insert.rotation_euler=normal.to_track_quat('Z','Y').to_euler(); parts.append(insert)
        # Front bar is supported by the cabinet face; the lens overlaps its plate.
        box('I05_Front_Status_Plate',(.72,.05,.22),(0,-.78,2.65),M['walnut'],.035); parts.append(bpy.context.object)
        box('I05_Front_Status_Lens',(.40,.025,.08),(0,-.8025,2.65),M['indicator_teal'],.018); parts.append(bpy.context.object)
        return save_candidate(aid,source,pivot,target,'Reseated the top amber status insert and front state bar against the podium surfaces; insert remains separate and the lens overlaps its supporting plate.')

# Target dims are Blender X,Y,Z; pivots follow contracts. P14 and I05 are based on their DCC-normalized GLBs.
results=[create_P12(),create_P13(),decorate_imported('P14','assets/cleaned/P14/P14_normalized_geometry_candidate.glb','rear-center',(2,1,3),None),create_I01(),create_I04(),decorate_imported('I05','assets/cleaned/I05/I05_normalized_geometry_candidate.glb','floor-center',(3,2,4),None)]
(ROOT/'docs/evidence/dcc-normalization/art-repair-candidates.json').write_text(json.dumps({'blender_version':bpy.app.version_string,'assets':results},indent=2)+'\n',encoding='utf-8')
print(json.dumps(results,indent=2))
