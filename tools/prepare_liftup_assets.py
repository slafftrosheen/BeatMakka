"""Blender: extract named supplied assets into bounded, grounded local scenery.

Run from the repository root with Blender --background --python this-file.
Original GLBs are never modified. This is an offline adaptation, not acceptance.
"""
import hashlib
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/production/needle-quay/liftup'
CONTENT = ROOT / 'assets/local-demo/content/needle-quay/liftup'
OUT.mkdir(parents=True, exist_ok=True)
CONTENT.mkdir(parents=True, exist_ok=True)
JOBS = [
    ('NQ-TRAFFIC-TAXI', 'generic_civil_service_vehicles_pack.glb', 'taxi', (5.6, 11, 5), 0),
    ('NQ-TRAFFIC-POST', 'generic_civil_service_vehicles_pack.glb', 'postvan', (5.8, 12, 6.4), 0),
    ('NQ-TRAFFIC-BUS', 'generic_civil_service_vehicles_pack.glb', 'citybus', (6.4, 20, 7.8), 0),
    ('NQ-SCENIC-01', 'city_game_ready_free.glb', 'Building.001', (24, 22, 34), 0),
    ('NQ-SCENIC-02', 'city_game_ready_free.glb', 'Building.002', (22, 22, 28), 0),
    ('NQ-SCENIC-03', 'city_game_ready_free.glb', 'Building.013', (28, 22, 30), 0),
]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mapped(v):
    return Vector((-v.x, v.z, v.y))


def nums(v):
    return ','.join(format(float(x), '.7g') for x in v)


records, materials, receipts = [], {}, []
for ident, filename, selected, limits, angle in JOBS:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source = ROOT / 'assets' / filename
    bpy.ops.import_scene.gltf(filepath=str(source))
    root = bpy.data.objects.get(selected)
    assert root is not None, (ident, selected)
    selected_objects = [root, *root.children_recursive]
    objects = [o for o in selected_objects if o.type == 'MESH']
    assert objects, (ident, selected)
    # The supplied vehicles are parked at different headings in their pack.
    # Remove the root heading so every export faces the same -Z runtime axis.
    heading = root.matrix_world.to_euler().z if ident.startswith('NQ-TRAFFIC') else 0
    rotation = Matrix.Rotation(angle - heading, 4, 'Z')
    transforms = {o: rotation @ o.matrix_world.copy() for o in objects}
    points = [transforms[o] @ v.co for o in objects for v in o.data.vertices]
    low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    origin = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
    scale = min(limits[i] / max((high - low)[i], .001) for i in range(3))
    for obj in objects:
        obj.data = obj.data.copy()
        for v in obj.data.vertices:
            v.co = (transforms[obj] @ v.co - origin) * scale
        obj.parent = None
        obj.matrix_world = Matrix.Identity(4)
    for obj in list(bpy.context.scene.objects):
        if obj not in objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    keys, colors, alpha = {}, {}, {}
    for material in {m for o in objects for m in o.data.materials if m}:
        shader = next((n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None) if material.use_nodes else None
        color = shader.inputs['Base Color'].default_value[:] if shader else material.diffuse_color[:]
        colors[material.name] = list(color[:3])
        alpha[material.name] = .28 if 'glass' in material.name.lower() else 0
        links = shader.inputs['Base Color'].links if shader else []
        if links and links[0].from_node.type == 'TEX_IMAGE':
            image = links[0].from_node.image
            if max(image.size) > 512:
                factor = 512 / max(image.size)
                image.scale(max(1, round(image.size[0] * factor)), max(1, round(image.size[1] * factor)))
            temp = CONTENT / 'atlas.tmp.png'
            image.filepath_raw, image.file_format = str(temp), 'PNG'
            image.save()
            digest = sha(temp)
            target = CONTENT / ('color_' + digest[:12] + '.png')
            target.write_bytes(temp.read_bytes())
            key = 'supplied_liftup_' + digest[:12]
            keys[material.name] = key
            materials[key] = 'rbxasset://needle-quay/liftup/' + target.name
            colors[material.name] = [1, 1, 1]
            image.pack()
    groups = {}
    for obj in objects:
        mesh = obj.data
        mesh.calc_loop_triangles()
        uv = mesh.uv_layers.active
        for tri in mesh.loop_triangles:
            material = mesh.materials[tri.material_index] if mesh.materials else None
            name = material.name if material else ''
            row = []
            for i in (0, 1, 2):
                loop = tri.loops[i]
                row.append((mapped(mesh.vertices[tri.vertices[i]].co), mapped(mesh.corner_normals[loop].vector), uv.data[loop].uv.copy() if uv else Vector((0, 0))))
            groups.setdefault(name, []).append(row)
    parts = []
    for name, triangles in groups.items():
        # The authored project cap is 10k per mesh; split without changing topology.
        for start in range(0, len(triangles), 9000):
            chunk = triangles[start:start + 9000]
            pts = [p for triangle in chunk for p, _, _ in triangle]
            lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
            hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
            center = (lo + hi) / 2
            lines = ['version 1.01', str(len(chunk))]
            lines += [''.join('[' + nums(p - center) + '][' + nums(n) + '][' + nums((u.x, u.y, 0)) + ']' for p, n, u in tri) for tri in chunk]
            payload = ('\n'.join(lines) + '\n').encode('ascii')
            digest = hashlib.sha256(payload).hexdigest()
            target = CONTENT / f'{ident}_{len(parts)}_{digest[:12]}.mesh'
            target.write_bytes(payload)
            parts.append(dict(name='Surface' + str(len(parts)), bone='', center=list(center), size=list(hi-lo), color=colors.get(name, [.6,.55,.45]), transparency=alpha.get(name, 0), surface_family=keys.get(name), triangles=len(chunk), sha256=digest, uri='rbxasset://needle-quay/liftup/' + target.name))
    blend = OUT / (ident + '.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    size = (high - low) * scale
    records.append(dict(id=ident, kind='supplied_liftup', source=blend.relative_to(ROOT).as_posix(), source_sha256=sha(blend), parts=parts, triangles=sum(p['triangles'] for p in parts), joints={}, dimensions=[abs(v) for v in mapped(size)], coordinate_basis='blender_to_roblox_front_minus_z_v2'))
    receipts.append(dict(id=ident, original=source.relative_to(ROOT).as_posix(), original_sha256=sha(source), selected_object=selected, uniform_scale=scale, stage='LOCAL_ADAPTATION_PENDING_ACCEPTANCE', art_approved=False, studio_imported=False, runtime_verified=False))
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples, scene.cycles.use_denoising = 12, True
    scene.render.resolution_x = scene.render.resolution_y = 480
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('NeutralReview')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (.24, .22, .19, 1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .8
    span, center = max(size), Vector((0,0,size.z/2))
    bpy.ops.object.light_add(type='AREA', location=center + Vector((span,-span,span*1.5)))
    light = bpy.context.object
    light.data.energy, light.data.size = 160 * span * span, span * 1.4
    light.rotation_euler = (center-light.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=center + Vector((span*.9,-span*1.6,span*.85)))
    camera = bpy.context.object
    camera.rotation_euler = (center-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type, camera.data.ortho_scale = 'ORTHO', span*1.55
    scene.camera, scene.render.filepath = camera, str(OUT/(ident+'.png'))
    bpy.ops.render.render(write_still=True)
    print('LIFTUP_ASSET', ident, records[-1]['triangles'], list(mapped(size)), flush=True)

for name, data in [('QuayLiftupCatalog', records), ('QuayLiftupMaterials', materials)]:
    (ROOT/'src/shared'/(name+'.luau')).write_text('return game:GetService("HttpService"):JSONDecode([=[' + json.dumps(data,separators=(',',':')) + ']=])\n',encoding='utf-8')
(OUT/'manifest.json').write_text(json.dumps(dict(assets=records, materials=materials, provenance=receipts, uploads=0),indent=2)+'\n',encoding='utf-8')
