"""Blender: preserve supplied GLBs, export local textured skins and source clips.
No provider calls, uploads, topology reduction, or external animation IDs.
"""
import bpy, json, math, hashlib
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/production/needle-quay/companions/supplied'
CONTENT = ROOT / 'assets/local-demo/content/needle-quay/companions'
OUT.mkdir(parents=True, exist_ok=True)
CONTENT.mkdir(parents=True, exist_ok=True)
AXIS = Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def numbers(v): return ','.join(format(float(n), '.7g') for n in v)
def rounded(v): return [round(float(n), 6) for n in v]
def frame(m):
    q=m.to_quaternion()
    return rounded(m.translation)+rounded((q.x,q.y,q.z,q.w))
records=[]
production=[]
for slug,filename,height in [('alissia','Alisija.glb',4.1),('nikolas','niklass.glb',3.8)]:
    source=ROOT/'assets/supplied/companions'/filename
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    scene=bpy.context.scene
    rig=next(o for o in scene.objects if o.type=='ARMATURE')
    if rig.animation_data:
        rig.animation_data.action=None
        for track in rig.animation_data.nla_tracks: track.mute=True
    rig.data.pose_position='REST'
    bpy.context.view_layer.update()
    objects=[o for o in scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    scale=height/(hi.z-lo.z)
    origin=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    def position(v): return (AXIS@(v-origin))*scale
    def matrix(m):
        result=AXIS@m@AXIS
        result.translation=position(m.translation)
        return result
    bones=list(rig.data.bones)
    parents={b.name:b.parent.name if b.parent else None for b in bones}
    bind={b.name:matrix(rig.matrix_world@b.matrix_local) for b in bones}
    rest={name:frame(m) for name,m in bind.items()}
    # Keep one original material texture, downsample only the runtime copy.
    material=objects[0].data.materials[0]
    shader=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    image=shader.inputs['Base Color'].links[0].from_node.image.copy()
    original_resolution=list(image.size)
    if max(image.size)>1024: image.scale(1024,1024)
    temp=CONTENT/(slug+'_supplied_color.png')
    image.filepath_raw=str(temp);image.file_format='PNG';image.save()
    atlas=CONTENT/(slug+'_supplied_color_'+sha(temp)[:12]+'.png')
    atlas.write_bytes(temp.read_bytes())
    triangles=[]
    for obj in objects:
        mesh=obj.data;mesh.calc_loop_triangles();uv=mesh.uv_layers.active
        normals=obj.matrix_world.to_3x3().inverted().transposed()
        for tri in mesh.loop_triangles:
            corners=[]
            for i in (0,1,2):
                v=mesh.vertices[tri.vertices[i]];loop=tri.loops[i]
                p=position(obj.matrix_world@v.co)
                n=(AXIS.to_3x3()@(normals@mesh.corner_normals[loop].vector)).normalized()
                weights=[[obj.vertex_groups[g.group].name,round(g.weight,7)] for g in v.groups if g.weight>0.00001]
                total=sum(w[1] for w in weights)
                weights=[[name,w/total] for name,w in weights] if total else [[bones[0].name,1]]
                corners.append((p,n,uv.data[loop].uv.copy(),weights))
            triangles.append(corners)
    parts=[];skins=[]
    for index,start in enumerate(range(0,len(triangles),6000)):
        chunk=triangles[start:start+6000];pts=[c[0] for t in chunk for c in t]
        low=Vector(tuple(min(p[i]for p in pts)for i in range(3)))
        high=Vector(tuple(max(p[i]for p in pts)for i in range(3)))
        center=(low+high)/2
        lines=['version 1.01',str(len(chunk))];weights={}
        for tri in chunk:
            lines.append(''.join('['+numbers(p-center)+']['+numbers(n)+']['+numbers((uv.x,uv.y,0))+']' for p,n,uv,w in tri))
            for p,n,uv,w in tri: weights[tuple(rounded(p-center))]=w
        payload=('\n'.join(lines)+'\n').encode('ascii')
        digest=hashlib.sha256(payload).hexdigest()
        path=CONTENT/f'{slug}_supplied_{index}_{digest[:12]}.mesh';path.write_bytes(payload)
        part={'name':f'SuppliedBody{index}','bone':'Root','center':rounded(center),'size':rounded(high-low),
              'color':[1,1,1],'uri':'rbxasset://needle-quay/companions/'+path.name,'sha256':digest,'triangles':len(chunk)}
        parts.append(part)
        skins.append({**part,'weights':[[list(p),w] for p,w in weights.items()]})
    # Sample original source animations; remove horizontal root motion for following.
    rig.data.pose_position='POSE';rig.animation_data_create()
    clips={}
    for wanted in ['idle','walk','run','cheer','clap']:
        action=next((a for a in bpy.data.actions if a.name.split('.')[0]==wanted),None)
        if not action:continue
        rig.animation_data.action=action
        if action.slots:rig.animation_data.action_slot=action.slots[0]
        start,end=action.frame_range;duration=max((end-start)/scene.render.fps,0.1)
        count=max(2,math.ceil(duration*12)+1);samples=[]
        root_name=bones[0].name
        for i in range(count):
            f=start+(end-start)*i/(count-1);scene.frame_set(int(f),subframe=f%1)
            world={b.name:matrix(rig.matrix_world@rig.pose.bones[b.name].matrix) for b in bones}
            offset=world[root_name].translation-bind[root_name].translation
            for m in world.values():m.translation-=Vector((offset.x,0,offset.z))
            row=[]
            for b in bones:
                parent=parents[b.name]
                rest_local=bind[parent].inverted()@bind[b.name] if parent else bind[b.name]
                pose_local=world[parent].inverted()@world[b.name] if parent else world[b.name]
                row.append(frame(rest_local.inverted()@pose_local))
            samples.append(row)
        module='CompanionClip'+slug.title()+wanted.title()
        content={'duration':round(duration,6),'samples':samples,'coordinate_basis':'blender_to_roblox_front_minus_z_v2'}
        (ROOT/'src/shared'/f'{module}.luau').write_text('return game:GetService("HttpService"):JSONDecode([=['+json.dumps(content,separators=(',',':'))+']=])\n')
        clips[wanted]=module
    rig.animation_data.action=None;rig.data.pose_position='REST';scene.frame_set(0)
    for im in bpy.data.images:
        if im.has_data:
            try:im.pack()
            except RuntimeError:pass
    blend=OUT/(slug+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    record={'id':'NQ-CMP-'+slug.upper(),'kind':'companion','source':source.relative_to(ROOT).as_posix(),
            'source_sha256':sha(source),'triangles':len(triangles),'parts':parts,
            'joints':{'Root':[0,0,0]},'parents':{'Root':None},'atlas':'rbxasset://needle-quay/companions/'+atlas.name,
            'suppliedSkin':{'parts':skins,'rest':rest,'parents':parents,'order':[b.name for b in bones],'clips':clips},
            'lods':[{'lod':0,'triangles':len(triangles),'parts':parts}]}
    records.append(record)
    record['coordinate_basis']='blender_to_roblox_front_minus_z_v2'
    production.append({'id':record['id'],'source':record['source'],'source_sha256':sha(source),
                       'blend':blend.relative_to(ROOT).as_posix(),'height_studs':height,'triangles':len(triangles),
                       'bone_count':len(bones),'original_texture_resolution':original_resolution,'runtime_texture_resolution':list(image.size),
                       'runtime_content_files':['companions/'+atlas.name]+[p['uri'].removeprefix('rbxasset://needle-quay/')for p in parts],
                       'source_animations':[a.name for a in bpy.data.actions], 'runtime_clips':clips,
                       'stage':'USER_SUPPLIED_LOCAL_ADAPTATION_PENDING_STUDIO_ACCEPTANCE','runtime_verified':False,'uploads':0})
    # Blender preview of supplied appearance, not an acceptance test.
    scene.render.engine='CYCLES';scene.cycles.samples=8
    scene.render.resolution_x=640;scene.render.resolution_y=800;scene.render.resolution_percentage=100
    scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.65,.65,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
    target=(lo+hi)/2;span=hi.z-lo.z
    bpy.ops.object.light_add(type='AREA',location=target+Vector((span,-span,span)))
    bpy.context.object.data.energy=500*span*span;bpy.context.object.data.size=span*2
    bpy.ops.object.camera_add(location=target+Vector((0,-span*3,0)))
    camera=bpy.context.object;camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO';camera.data.ortho_scale=span*1.18;scene.camera=camera
    scene.render.filepath=str(OUT/(slug+'-front.png'));bpy.ops.render.render(write_still=True)
(ROOT/'src/shared/CompanionModels.luau').write_text('-- User-supplied GLBs; original geometry and skin weights retained.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(records,separators=(',',':'))+']=])\n')
(OUT/'manifest.json').write_text(json.dumps({'characters':production},indent=2)+'\n')
print('SUPPLIED_COMPANIONS',[(p['id'],p['triangles'])for p in production])
