"""Blender: bake source actions from the preserved supplied rigs. No mesh changes."""
import bpy, json, math
from pathlib import Path
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
catalog_path = ROOT / 'src/shared/CompanionModels.luau'
records = json.loads(catalog_path.read_text().split('[=[')[1].split(']=]')[0])
manifest_path = ROOT / 'assets/production/needle-quay/companions/supplied/manifest.json'
manifest = json.loads(manifest_path.read_text())
AXIS = Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
def frame(m):
    q = m.to_quaternion()
    return [round(float(v),6) for v in (*m.translation,q.x,q.y,q.z,q.w)]

for record, production in zip(records, manifest['characters']):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / production['blend']))
    scene = bpy.context.scene
    rig = next(o for o in scene.objects if o.type == 'ARMATURE')
    rig.animation_data_create()
    rig.animation_data.action = None
    for track in rig.animation_data.nla_tracks: track.mute = True
    rig.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    objects = [o for o in scene.objects if o.type == 'MESH' and any(m.type == 'ARMATURE' for m in o.modifiers)]
    pts = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
    low = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    scale = production['height_studs'] / (high.z-low.z)
    origin = Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    def matrix(m):
        result = AXIS @ m @ AXIS
        result.translation = (AXIS @ (m.translation-origin))*scale
        return result
    order = record['suppliedSkin']['order']
    parents = record['suppliedSkin']['parents']
    bind = {n:matrix(rig.matrix_world @ rig.data.bones[n].matrix_local) for n in order}
    rig.data.pose_position = 'POSE'
    clips = {}
    for wanted in ['idle','walk','run','cheer','clap','dance_03','dance_06','agree','bow']:
        action = next((a for a in bpy.data.actions if a.name.split('.')[0] == wanted),None)
        if not action: continue
        rig.animation_data.action = action
        if action.slots: rig.animation_data.action_slot = action.slots[0]
        start,end = action.frame_range
        duration = max((end-start)/(scene.render.fps/scene.render.fps_base),.1)
        count = max(2,math.ceil(duration*24)+1)
        samples = []
        for i in range(count):
            f = start+(end-start)*i/(count-1)
            scene.frame_set(int(f),subframe=f%1)
            world = {n:matrix(rig.matrix_world @ rig.pose.bones[n].matrix) for n in order}
            offset = world[order[0]].translation-bind[order[0]].translation
            for m in world.values(): m.translation -= Vector((offset.x,0,offset.z))
            row = []
            for n in order:
                p = parents[n]
                rest = bind[p].inverted() @ bind[n] if p else bind[n]
                pose = world[p].inverted() @ world[n] if p else world[n]
                row.append(frame(rest.inverted() @ pose))
            samples.append(row)
        slug = record['id'].split('-')[-1].title()
        module = 'CompanionClip'+slug+wanted.title().replace('_','')
        clip = {'duration':round(duration,6),'loop':wanted in ['idle','walk','run','dance_03','dance_06'], 'samples':samples,'coordinate_basis':'blender_to_roblox_front_minus_z_v2'}
        (ROOT/'src/shared'/f'{module}.luau').write_text('return game:GetService("HttpService"):JSONDecode([=['+json.dumps(clip,separators=(',',':'))+']=])\n')
        clips[wanted] = module
    record['suppliedSkin']['clips'] = clips
    production['runtime_clips'] = clips
    production['runtime_clip_sample_rate'] = 24
    print(record['id'],list(clips))
catalog_path.write_text('-- Supplied geometry and skin weights retained; source animation clips.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(records,separators=(',',':'))+']=])\n')
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
