"""Blender-only original companion candidates, local meshes, atlas and rig clips.

Source: issue 20's fictional design specification. No photographs or providers.
Does not alter existing NPCs, install content, upload, or claim art approval.
"""
import bpy, math, json, hashlib, random, argparse
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'assets/production/needle-quay/companions'
CONTENT = ROOT/'assets/local-demo/content/needle-quay/companions'
OUT.mkdir(parents=True, exist_ok=True); CONTENT.mkdir(parents=True, exist_ok=True)
PALETTE = ['E8D8B7','6F9186','2F5C58','CA7453','79513B','162322','496C76','A58B68','705039','C99B78','343F3D','F3B65F','B1B9B0','987B5B','F5EEDC','485957']
CLIPS = ['idle','idle_listen','walk','run','point','kneel','think','celebrate','wave','music_bob']
parser=argparse.ArgumentParser()
parser.add_argument('--character',choices=['ALISSIA','NIKOLAS'])
args=parser.parse_args(__import__('sys').argv[__import__('sys').argv.index('--')+1:] if '--' in __import__('sys').argv else [])
records=[];production=[]
if args.character and (OUT/'model-manifest.json').exists():
    production=[p for p in json.loads((OUT/'model-manifest.json').read_text(encoding='utf-8'))['characters'] if p['id']!='NQ-CMP-'+args.character]
    catalog=(ROOT/'src/shared/CompanionModels.luau').read_text(encoding='utf-8')
    records=[p for p in json.loads(catalog.split('[=[')[1].split(']=]')[0]) if p['id']!='NQ-CMP-'+args.character]
def rgb(value): return tuple(int(value[i:i+2],16)/255 for i in (0,2,4))
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def camera_at(camera, at, target):
    camera.location=at; camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
for slug,height in [('ALISSIA',4.1),('NIKOLAS',3.8)]:
    if args.character and slug!=args.character:continue
    directory=OUT/slug;directory.mkdir(exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
    scene.render.resolution_x=900;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
    scene.world=bpy.data.worlds.new('WarmNeutral');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(*rgb('E8D8B7'),1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
    scene.view_settings.view_transform='AgX'
    scene.view_settings.look='AgX - Medium High Contrast'
    atlas=bpy.data.images.new(slug+'_Atlas',512,512,alpha=False)
    rand=random.Random(20);pixels=[]
    for y in range(512):
        for x in range(512):
            swatch=(y//128)*4+x//128
            base=rgb(PALETTE[swatch]);grain=rand.uniform(.975,1.015)
            if swatch in (1,2,6) and (x%6==0 or y%7==0):grain*=.985
            pixels.extend([min(1,c*grain)for c in base]+[1])
    atlas.pixels=pixels;atlas.filepath_raw=str(CONTENT/(slug.lower()+'_color.png'));atlas.file_format='PNG';atlas.save()
    material=bpy.data.materials.new(slug+'_MatteAtlas');material.use_nodes=True
    bs=material.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.86
    tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=atlas
    material.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    h=height
    joints={'Root':(0,0,0),'Hips':(0,0,.46*h),'Spine':(0,0,.62*h),'Head':(0,0,.79*h)}
    parents={'Root':None,'Hips':'Root','Spine':'Hips','Head':'Spine'}
    for side,sign in [('Left',-1),('Right',1)]:
        for name,z in [('UpperArm',.73),('LowerArm',.55),('Hand',.40)]:
            joints[side+name]=(sign*.205*h,0,z*h)
        parents[side+'UpperArm']='Spine';parents[side+'LowerArm']=side+'UpperArm';parents[side+'Hand']=side+'LowerArm'
        for name,z in [('UpperLeg',.46),('LowerLeg',.26),('Foot',.1)]:joints[side+name]=(sign*.115*h,0,z*h)
        parents[side+'UpperLeg']='Hips';parents[side+'LowerLeg']=side+'UpperLeg';parents[side+'Foot']=side+'LowerLeg'
    arm=bpy.data.armatures.new(slug+'_Rig');rig=bpy.data.objects.new(slug+'_Rig',arm);scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for name,position in joints.items():
        b=arm.edit_bones.new(name);b.head=position;b.tail=Vector(position)+Vector((0,0,.12*h))
        if parents[name]:b.parent=arm.edit_bones[parents[name]]
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    body=[]
    def finish(obj,name,swatch,bone):
        obj.name=name;obj.data.materials.clear();obj.data.materials.append(material)
        uv=obj.data.uv_layers.active or obj.data.uv_layers.new()
        for loop in uv.data:
            old=loop.uv.copy();loop.uv=((swatch%4+ .1+.8*(old.x%1))/4,(swatch//4+.1+.8*(old.y%1))/4)
        group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        mod=obj.modifiers.new('AuthoredRig','ARMATURE');mod.object=rig
        obj.parent=rig;body.append(obj);return obj
    def box(name,p,size,color,bone,bevel=.025):
        bpy.ops.mesh.primitive_cube_add(size=1,location=tuple(v*h for v in p));o=bpy.context.object;o.scale=tuple(v*h for v in size)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        if bevel and min(size) >= .035:
            m=o.modifiers.new('SoftManufacturedEdges','BEVEL');m.width=bevel*h;m.segments=1
            bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
        return finish(o,name,color,bone)
    def soft(name,p,size,color,bone):
        # Tapered elliptical cloth, with a stable joint binding and atlas UVs.
        segments=10;profiles=[(0,.72),(.09,.96),(.46,1),(.87,.94),(1,.68)]
        vertices=[(math.cos(i/segments*math.tau)*size[0]*.5*r*h,math.sin(i/segments*math.tau)*size[1]*.5*r*h,(t-.5)*size[2]*h)for t,r in profiles for i in range(segments)]
        faces=[tuple(reversed(range(segments)))]
        for ring in range(len(profiles)-1):
            for i in range(segments):faces.append((ring*segments+i,ring*segments+(i+1)%segments,(ring+1)*segments+(i+1)%segments,(ring+1)*segments+i))
        faces.append(tuple((len(profiles)-1)*segments+i for i in range(segments)))
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
        obj=bpy.data.objects.new(name,mesh);scene.collection.objects.link(obj);obj.location=tuple(v*h for v in p)
        uv=mesh.uv_layers.new()
        for loop in mesh.loops:
            v=mesh.vertices[loop.vertex_index].co;uv.data[loop.index].uv=((math.atan2(v.y,v.x)/math.tau+.5)%1,v.z/(size[2]*h)+.5)
        for polygon in mesh.polygons:polygon.use_smooth=len(polygon.vertices)==4
        return finish(obj,name,color,bone)
    def ball(name,p,size,color,bone,segments=12,rings=6):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=tuple(v*h for v in p));o=bpy.context.object;o.scale=tuple(v*h/2 for v in size)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        for poly in o.data.polygons:poly.use_smooth=True
        return finish(o,name,color,bone)
    for side,sign in [('Left',-1),('Right',1)]:
        box(side+'Shoe',(sign*.115,-.045,.065),(.18,.29,.12),2,side+'Foot',.022)
        box(side+'ToeCap',(sign*.115,-.190,.046),(.165,.065,.048),0,side+'Foot',.012)
        box(side+'ShoeTrim',(sign*.115,-.204,.071),(.115,.012,.018),3,side+'Foot',0)
        box(side+'Sole',(sign*.115,-.04,.025),(.18,.28,.035),0,side+'Foot',.009)
        soft(side+'UpperLeg',(sign*.115,0,.355),(.185,.19,.25),6 if slug=='ALISSIA' else 4,side+'UpperLeg')
        soft(side+'LowerLeg',(sign*.115,.012 if slug=='ALISSIA' else 0,.19),(.19,.18,.20) if slug=='ALISSIA' else (.11,.12,.20),6 if slug=='ALISSIA' else 9,side+'LowerLeg')
        soft(side+'Sleeve',(sign*.205,0,.63),(.14,.17,.23),1 if slug=='ALISSIA' else 0,side+'UpperArm')
        ball(side+'Forearm',(sign*.205,0,.47),(.105,.12,.19),1 if slug=='ALISSIA' else 9,side+'LowerArm',10,6)
        ball(side+'Hand',(sign*.205,-.005,.367),(.11,.12,.12),9,side+'Hand',10,6)
        for z in [.065,.085]:box(side+'Lace',(sign*.115,-.199,z),(.10,.012,.009),0,side+'Foot',0)
    box('Waist',(0,0,.465),(.34,.21,.11),6 if slug=='ALISSIA' else 4,'Hips',.025)
    soft('CreamTee',(0,0,.645),(.34,.23,.30),0,'Spine')
    soft('SoftCollar',(0,-.015,.765),(.17,.22,.055),0,'Spine')
    # Open outerwear keeps the cream shirt visible, as in the supplied turnaround.
    for sign in [-1,1]:
        for z in [.60,.67,.72]:box('BrassFastener',(sign*.065,-.155,z),(.009,.007,.009),11,'Spine',0)
    for sign in [-1,1]:
        outer=soft('JacketPanel' if slug=='ALISSIA' else 'VestPanel',(sign*.117,-.075,.645),(.14,.20,.29),1 if slug=='ALISSIA' else 2,'Spine')
        outer.rotation_euler.y=sign*-.055
        lapel=box('FoldedLapel',(sign*.076,-.154,.739),(.045,.023,.10),2 if slug=='ALISSIA' else 1,'Spine',.006)
        lapel.rotation_euler.y=sign*.35
        box('OuterPocket',(sign*.126,-.181,.576),(.072,.018,.065),6 if slug=='ALISSIA' else 1,'Spine',.005)
        box('PocketFlap',(sign*.126,-.192,.598),(.074,.014,.018),1 if slug=='ALISSIA' else 13,'Spine',0)
        box('PackStrap',(sign*.145,-.151,.706),(.027,.02,.16),3 if slug=='ALISSIA' else 13,'Spine',.003)
        box('StrapBuckle',(sign*.145,-.165,.692),(.035,.012,.024),11,'Spine',0)
    soft('OuterwearBack',(0,.075,.64),(.35,.15,.29),1 if slug=='ALISSIA' else 2,'Spine')
    soft('FoldedHood',(0,.105,.767),(.25,.16,.09),1 if slug=='ALISSIA' else 2,'Spine')
    # Small abstract stitched music marks, never baked gameplay text.
    if slug=='NIKOLAS':
        for x,z in [(-.035,.028),(-.012,.045),(.012,.065),(.035,.035)]:
            box('RhythmShirtMark',(x,-.122,.67),(.012,.008,z),3 if x<0 else 11,'Spine',0)
    else:
        box('NoteStem',(.025,-.122,.68),(.008,.008,.055),3,'Spine',0)
        box('NoteBeam',(.004,-.122,.704),(.05,.008,.008),3,'Spine',0)
        box('NoteStem',(-.02,-.122,.67),(.008,.008,.06),3,'Spine',0)
        for x,z in [(-.028,.643),(.018,.657)]:ball('NoteHead',(x,-.126,z),(.024,.009,.014),3,'Spine',8,4)
    ball('Neck',(0,0,.79),(.095,.10,.12),9,'Head',10,4)
    ball('Face',(0,-.004,.864),(.29,.265,.29),9,'Head',16,10)
    for x in [-.053,.053]:
        ball('Eye',(x,-.122,.887),(.042,.016,.025),14,'Head',8,4)
        ball('Pupil',(x,-.133,.887),(.019,.009,.022),5,'Head',8,4)
        box('Brow',(x,-.119,.915),(.039,.012,.009),8 if slug=='ALISSIA' else 7,'Head',.002)
    ball('Nose',(0,-.139,.862),(.026,.035,.034),9,'Head',8,4)
    for x,angle in [(-.022,-.25),(0,0),(.022,.25)]:
        smile=box('QuietSmile',(x,-.145,.830+abs(x)*.17),(.029,.007,.005),4,'Head',0);smile.rotation_euler.y=-angle
    for x in [-.053,.053]:ball('EyeGlint',(x-.004,-.139,.892),(.006,.003,.006),14,'Head',6,3)
    for x in [-.143,.143]:ball('Ear',(x,0,.86),(.035,.04,.055),9,'Head',8,4)
    # Open-bottom hair dome leaves the modest eyes and facial silhouette unobscured.
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=1)
    hair=bpy.context.object
    import bmesh
    bm=bmesh.new();bm.from_mesh(hair.data);bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.z<-.001],context='VERTS');bm.to_mesh(hair.data);bm.free()
    hair.scale=(.15*h,.14*h,.10*h);hair.location=(0,.008*h,.915*h)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(hair,'HairCap',8 if slug=='ALISSIA' else 7,'Head')
    if slug=='ALISSIA':
        ball('TiedHair',(0,.135,.89),(.13,.14,.15),8,'Head',10,6)
        for z,x in [(.845,-.012),(.813,.009),(.782,-.006)]:ball('TiedBraid',(x,.149,z),(.065,.073,.065),8,'Head',8,4)
        for sign in [-1,1]:
            lock=ball('FaceFramingLock',(sign*.126,-.077,.918),(.04,.05,.14),8,'Head',8,4);lock.rotation_euler.y=sign*-.3
        box('HairTie',(0,.153,.91),(.08,.018,.025),2,'Head',.004)
        for x,z,angle in [(-.080,.944,-.45),(-.025,.956,-.32),(.055,.954,.32)]:
            fringe=ball('SoftFringe',(x,-.112,z),(.115,.06,.048),8,'Head',8,4);fringe.rotation_euler.y=angle
        for x in [-.047,.047]:
            bpy.ops.mesh.primitive_torus_add(major_segments=12,minor_segments=4,location=(x*h,-.155*h,.97*h),major_radius=.035*h,minor_radius=.008*h,rotation=(math.pi/2,0,0))
            finish(bpy.context.object,'CoralGogglesFrame',3,'Head')
            ball('MatteLens',(x,-.156,.97),(.056,.012,.04),15,'Head',8,4)
        box('GogglesBridge',(0,-.155,.97),(.03,.014,.014),3,'Head',.003)
        for sign in [-1,1]:box('CoralGogglesStrap',(sign*.143,0,.965),(.016,.23,.019),3,'Head',.004)
        box('FieldPack',(0,.15,.65),(.20,.10,.23),0,'Spine',.018)
        box('FieldPackFlap',(0,.208,.67),(.18,.022,.10),1,'Spine',.008)
        box('SatchelLatch',(.255,-.139,.52),(.028,.012,.04),3,'Spine',.004)
        box('SoundSatchel',(.235,-.055,.49),(.18,.12,.19),0,'Spine',.023)
        box('SatchelFlap',(.235,-.122,.53),(.17,.02,.07),3,'Spine',.008)
        box('CatalogTabs',(.255,-.06,.59),(.09,.07,.025),3,'Spine',.003)
        strap=box('WovenStrap',(.045,-.13,.65),(.03,.02,.35),4,'Spine',.004);strap.rotation_euler.y=-.62
    else:
        for x,z in [(-.105,.958),(-.065,.981),(-.02,.992),(.028,.982),(.075,.968),(.11,.95)]:
            tuft=ball('HairSweep',(x,-.085,z),(.055,.095,.082),7,'Head',8,4);tuft.rotation_euler.y=-.45
        for x in [-.07,0,.07]:
            tuft=ball('CrownTuft',(x,.015,.995),(.065,.095,.055),13,'Head',8,4);tuft.rotation_euler.y=-.4
        box('UtilityPack',(0,.145,.65),(.18,.09,.20),2,'Spine',.016)
        box('UtilityPackFlap',(0,.20,.67),(.16,.02,.08),13,'Spine',.006)
        box('MechanicalCounter',(.235,-.07,.48),(.19,.10,.20),2,'Hips',.015)
        ball('AmberDial',(.235,-.126,.48),(.165,.018,.165),11,'Hips',16,4)
        ball('CounterFace',(.235,-.139,.48),(.139,.010,.139),0,'Hips',16,4)
        for i in range(4):
            a=i*math.pi/2
            box('CounterTick',(.235+math.sin(a)*.054,-.148,.48+math.cos(a)*.054),(.009,.006,.009),4,'Hips',0)
        box('DialPointer',(.235,-.151,.49),(.009,.01,.035),5,'Hips',.002)
        box('CounterClip',(.235,-.04,.55),(.035,.04,.03),13,'Hips',.004)
        strap=box('CounterStrap',(.145,-.13,.63),(.022,.018,.30),13,'Spine',.003);strap.rotation_euler.y=.32
        for sign in [-1,1]:
            box('CargoPocket',(sign*.16,-.075,.355),(.09,.08,.13),13,('Left' if sign<0 else 'Right')+'UpperLeg',.008)
            box('CargoFlap',(sign*.16,-.12,.40),(.095,.012,.03),4,('Left' if sign<0 else 'Right')+'UpperLeg',0)
    # Stable named source actions, with root motion deliberately disabled.
    for clip in CLIPS:
        action=bpy.data.actions.new(clip);rig.animation_data_create();rig.animation_data.action=action
        for frame in [0,8,16,24,32]:
            phase=frame/32*math.tau
            for bone in rig.pose.bones:
                bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
                sign=1 if bone.name.startswith('Left') else -1
                if clip in ['walk','run'] and ('UpperLeg' in bone.name or 'UpperArm' in bone.name):bone.rotation_euler.x=math.sin(phase)*sign*(.55 if clip=='run' else .32)*(1 if 'Leg'in bone.name else -1)
                elif clip=='idle_listen' and bone.name=='Head':bone.rotation_euler.x=.12
                elif clip in ['point','wave','celebrate'] and bone.name=='RightUpperArm':bone.rotation_euler.x=-1.25;bone.rotation_euler.z=math.sin(phase)*.16
                elif clip=='think' and bone.name=='LeftLowerArm':bone.rotation_euler.x=-1.5
                elif clip=='kneel' and 'LowerLeg'in bone.name:bone.rotation_euler.x=.8
                elif clip=='music_bob' and bone.name=='Spine':bone.rotation_euler.z=math.sin(phase)*.08
                elif clip=='idle' and bone.name=='Head':bone.rotation_euler.z=math.sin(phase)*.025
                bone.keyframe_insert(data_path='rotation_euler',frame=frame,group=bone.name)
        action.use_fake_user=True
    rig.animation_data.action=None
    for bone in rig.pose.bones:bone.rotation_euler=(0,0,0)
    scene.frame_set(0)
    # Export three actual geometric LODs. LOD0 retains all authored accessories.
    levels=[];modelCatalog=None
    for lod,ratio in [(0,1),(1,.40),(2,.12)]:
        duplicates=[]
        for source in body:
            obj=source.copy();obj.data=source.data.copy();scene.collection.objects.link(obj);obj.hide_render=False
            obj.modifiers.clear()
            if lod:
                modifier=obj.modifiers.new('LODReduction','DECIMATE');modifier.ratio=ratio
                bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=modifier.name)
            duplicates.append(obj)
        parts=[];triangles=0
        # Merge by rigid joint, preserving the shared atlas and exact evaluated surface.
        for bone in joints:
            group=[o for o in duplicates if o.vertex_groups and o.vertex_groups[0].name==bone]
            if not group:continue
            duplicates=[o for o in duplicates if o not in group]
            bpy.ops.object.select_all(action='DESELECT')
            for o in group:o.select_set(True)
            bpy.context.view_layer.objects.active=group[0]
            if len(group)>1:bpy.ops.object.join()
            obj=bpy.context.object
            obj.name=bone;obj.data.calc_loop_triangles();tris=obj.data.loop_triangles;triangles+=len(tris)
            # Joined mesh is object-local; apply the object matrix before axis conversion.
            points=[Vector((-(obj.matrix_world@v.co).x,(obj.matrix_world@v.co).z,(obj.matrix_world@v.co).y)) for v in obj.data.vertices]
            low=Vector(tuple(min(v[i]for v in points)for i in range(3)));high=Vector(tuple(max(v[i]for v in points)for i in range(3)));center=(low+high)/2
            uv=obj.data.uv_layers.active;normalMatrix=obj.matrix_world.to_3x3().inverted().transposed()
            lines=['version 1.01',str(len(tris))]
            for tri in tris:
                corners=[]
                for index in (0,1,2):
                    loop=tri.loops[index];normal=normalMatrix@obj.data.corner_normals[loop].vector;normal=Vector((-normal.x,normal.z,normal.y)).normalized();tex=uv.data[loop].uv
                    def numbers(v):return ','.join(format(float(n),'.7g')for n in v)
                    corners.append('['+numbers(points[tri.vertices[index]]-center)+']['+numbers(normal)+']['+numbers((tex.x,tex.y,0))+']')
                lines.append(''.join(corners))
            dest=CONTENT/(slug.lower()+f'_lod{lod}_{bone}.mesh');dest.write_text('\n'.join(lines)+'\n',encoding='ascii')
            parts.append({'bone':bone,'name':bone,'center':list(center),'size':list(high-low),'color':[1,1,1],'uri':'rbxasset://needle-quay/companions/'+dest.name,'sha256':digest(dest),'triangles':len(tris),'surface_family':'companion_'+slug.lower()})
            obj.hide_render=True;obj.hide_set(True)
        levels.append({'lod':lod,'triangles':triangles,'parts':parts})
    # Remove the export-only duplicates before saving/rendering the source.
    for obj in list(scene.objects):
        if obj.type=='MESH' and obj not in body:bpy.data.objects.remove(obj,do_unlink=True)
    for obj in body:obj.hide_set(False);obj.hide_render=False
    atlas.pack()
    source=directory/(f'NQ-CMP-{slug}.blend');bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for obj in body:obj.select_set(True)
    glb=directory/(f'NQ-CMP-{slug}.glb')
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS')
    rig.animation_data.action=None
    for bone in rig.pose.bones:bone.rotation_euler=(0,0,0)
    scene.frame_set(0)
    # Neutral orthographic views. Camera/lights never enter the character source.
    bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='ORTHO';camera.data.ortho_scale=h*1.18
    for p,power,size in [((4,-5,7),600,5),((-4,-2,4),400,4),((1,4,6),500,4)]:
        bpy.ops.object.light_add(type='AREA',location=p);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,h*.5))-light.location).to_track_quat('-Z','Y').to_euler()
    previews=[]
    for view,position in [('front',(0,-10,h*.52)),('side',(10,0,h*.52)),('back',(0,10,h*.52)),('isometric',(7,-10,6))]:
        camera_at(camera,position,(0,0,h*.52));scene.render.filepath=str(directory/(view+'.png'));bpy.ops.render.render(write_still=True);previews.append(str((directory/(view+'.png')).relative_to(ROOT)).replace('\\','/'))
    for clip in ['idle_listen','point','think','celebrate']:
        rig.animation_data.action=bpy.data.actions[clip];scene.frame_set(8)
        camera_at(camera,(0,-10,h*.52),(0,0,h*.52));scene.render.filepath=str(directory/('emote_'+clip+'.png'));bpy.ops.render.render(write_still=True)
    bounds=[max(part['center'][i]+part['size'][i]/2 for part in levels[0]['parts'])-min(part['center'][i]-part['size'][i]/2 for part in levels[0]['parts']) for i in range(3)]
    j={name:[-p[0],p[2],p[1]]for name,p in joints.items()}
    record={'id':'NQ-CMP-'+slug,'kind':'companion','source':source.relative_to(ROOT).as_posix(),'source_sha256':digest(source),'triangles':levels[0]['triangles'],'parts':levels[0]['parts'],'joints':j,'parents':parents,'lods':levels,'atlas':'rbxasset://needle-quay/companions/'+slug.lower()+'_color.png'}
    record['coordinate_basis']='blender_to_roblox_front_minus_z_v2'
    records.append(record)
    production.append({'id':record['id'],'name':slug.title(),'height_studs':bounds[1],'bounds_wdh_studs':[bounds[0],bounds[2],bounds[1]],'authored_height_parameter':height,'source':record['source'],'source_sha256':record['source_sha256'],'glb':glb.relative_to(ROOT).as_posix(),'glb_sha256':digest(glb),'lod_triangles':[l['triangles']for l in levels],'atlas_resolution':[512,512],'atlas_sha256':digest(CONTENT/(slug.lower()+'_color.png')),'bone_count':len(joints),'binding':'rigid one-bone weights per authored segment','source_actions':CLIPS,'previews':previews,'stage':'DCC_CANDIDATE_PENDING_ART_REVIEW','art_approved':False,'studio_imported':False,'runtime_verified':False,'provider_spend':0,'provenance':{'source':'Issue 20 textual brief and supplied candidate artwork','concept_reference':'assets/references/companions/provided-pack-v1/art/Character_Turnarounds_CANDIDATE.png','family_photographs_used':False,'generator':'tools/build_companion_candidates.py'}})
records.sort(key=lambda p:p['id']);production.sort(key=lambda p:p['id'])
(OUT/'model-manifest.json').write_text(json.dumps({'characters':production},indent=2)+'\n',encoding='utf-8')
payload=json.dumps(records,separators=(',',':'))
(ROOT/'src/shared/CompanionModels.luau').write_text('-- Generated original DCC candidates; art approval remains open.\nreturn game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n',encoding='utf-8')
print('COMPANION_CANDIDATES',json.dumps([(p['id'],p['lod_triangles'])for p in production]))
