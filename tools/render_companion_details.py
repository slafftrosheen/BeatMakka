"""Blender: finish portable source files and render candidate silhouettes/props."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'assets/production/needle-quay/companions'
manifest=json.loads((FOLDER/'model-manifest.json').read_text(encoding='utf-8'))
catalogPath=ROOT/'src/shared/CompanionModels.luau'
catalog=json.loads(catalogPath.read_text(encoding='utf-8').split('[=[')[1].split(']=]')[0])
for character in manifest['characters']:
    source=ROOT/character['source'];bpy.ops.wm.open_mainfile(filepath=str(source));scene=bpy.context.scene
    rig=next(o for o in scene.objects if o.type=='ARMATURE');rig.animation_data.action=None
    for bone in rig.pose.bones:bone.rotation_euler=(0,0,0)
    scene.frame_set(0)
    for image in bpy.data.images:
        if image.source=='FILE' or image.has_data:
            try:image.pack()
            except RuntimeError:pass
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    character['source_sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
    next(row for row in catalog if row['id']==character['id'])['source_sha256']=character['source_sha256']
    scene.render.engine='CYCLES';scene.cycles.samples=12
    scene.render.resolution_x=700;scene.render.resolution_y=900;scene.render.resolution_percentage=100
    bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='ORTHO'
    h=character['authored_height_parameter'];camera.data.ortho_scale=h*1.15
    def aim(position,target):camera.location=position;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    aim((0,-10,h*.52),(0,0,h*.52))
    black=bpy.data.materials.new('SilhouetteInk');black.use_nodes=True
    bs=black.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(0,0,0,1);bs.inputs['Roughness'].default_value=1
    if 'Specular IOR Level' in bs.inputs:bs.inputs['Specular IOR Level'].default_value=0
    scene.view_layers[0].material_override=black
    scene.render.filepath=str(source.parent/'silhouette.png');bpy.ops.render.render(write_still=True)
    scene.view_layers[0].material_override=None
    prefixes=('CoralGoggles','MatteLens','GogglesBridge','SoundSatchel','SatchelFlap','SatchelLatch','CatalogTabs','WovenStrap') if character['id'].endswith('ALISSIA') else ('MechanicalCounter','AmberDial','CounterFace','CounterTick','DialPointer','CounterClip')
    for obj in scene.objects:
        if obj.type=='MESH':obj.hide_render=not obj.name.startswith(prefixes)
    scene.render.resolution_x=800;scene.render.resolution_y=800
    if character['id'].endswith('ALISSIA'):
        target=(.12*h,-.06*h,.74*h);camera.data.ortho_scale=h*.65
    else:target=(.235*h,-.08*h,.49*h);camera.data.ortho_scale=1.1
    aim((target[0]+1,target[1]-6,target[2]+.6),target)
    for position,power in [((4,-5,7),600),((-3,-2,5),400)]:
        bpy.ops.object.light_add(type='AREA',location=position);light=bpy.context.object;light.data.energy=power;light.data.size=5;light.rotation_euler=(Vector(target)-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(source.parent/'props.png');bpy.ops.render.render(write_still=True)
    character['detail_previews']=[(source.parent/name).relative_to(ROOT).as_posix()for name in ['silhouette.png','props.png']]
(FOLDER/'model-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
catalogPath.write_text('-- Generated original DCC candidates; art approval remains open.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(catalog,separators=(',',':'))+']=])\n',encoding='utf-8')
print('Packed source atlases and rendered candidate silhouettes/props.')
