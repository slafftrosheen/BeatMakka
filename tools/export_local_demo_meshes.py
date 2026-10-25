"""Blender: export exact evaluated geometry to local Roblox mesh files.

No bounds substitution, remeshing, decimation, provider call or upload. The
engine accepts version 1.01 triangle files at their authored stud dimensions.
Collision remains independently authored. Source files are read-only.
"""
import bpy
import json
import hashlib
from pathlib import Path
from collections import defaultdict
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/local-demo/content/needle-quay'
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((ROOT / 'assets/production/needle-quay/models/model-manifest.json').read_text())
optimized = json.loads((ROOT / 'docs/evidence/optimized-assets.json').read_text())
sources = []
for b in report['buildings']:
    refined=ROOT/'assets/production/needle-quay/models/refined'/(b['id']+'.blend')
    source=str(refined.relative_to(ROOT)).replace('\\','/') if refined.exists() else b['source']
    sources.append((b['id'], source, 'building', None))
for n in report['npcs']:
    refined=ROOT/'assets/production/needle-quay/models/refined'/(n['id']+'.blend')
    if n['id'] != 'H04': sources.append((n['id'], str(refined.relative_to(ROOT)).replace('\\','/') if refined.exists() else n['source'], 'npc', None))
for a in optimized['assets']:
    sources.append((a['id'], a['output'], 'asset', a['texture_size']))
van=ROOT/'assets/production/needle-quay/models/refined/LOOPVAN-01.blend'
sources.append(('LOOPVAN-01', van.relative_to(ROOT).as_posix() if van.exists() else 'assets/production/needle-quay/models/LOOPVAN-01/LOOPVAN-01.blend', 'vehicle', None))
tree=ROOT/'assets/production/needle-quay/models/refined/NQ-SCENERY-TREE.blend'
if tree.exists():sources.append(('NQ-SCENERY-TREE',tree.relative_to(ROOT).as_posix(),'scenery',None))
user_manifest=ROOT/'assets/production/needle-quay/models/user-adapted/manifest.json'
user_assets={a['id']:a for a in json.loads(user_manifest.read_text())['assets']} if user_manifest.exists() else {}
for asset in user_assets.values():
    sources=[s for s in sources if s[0]!=asset['id']]
    sources.append((asset['id'],asset['source'],asset['kind'],None))

def mapped(v): return Vector((v.x, v.z, v.y))
def numbers(v): return ','.join(format(float(x), '.7g') for x in v)

records = []
for ident, relative, kind, resolution in sources:
    source = ROOT / relative
    if source.suffix == '.blend': bpy.ops.wm.open_mainfile(filepath=str(source))
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(source))
    deps = bpy.context.evaluated_depsgraph_get()
    groups = defaultdict(list)
    skin_weights = {}
    colors = {}
    joints = {}
    armature = next((o for o in bpy.context.scene.objects if o.type == 'ARMATURE'), None)
    if armature:
        for bone in armature.data.bones:
            joints[bone.name] = list(mapped(armature.matrix_world @ bone.head_local))
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH': continue
        evaluated = obj.evaluated_get(deps)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        transform = evaluated.matrix_world
        normal_transform = transform.to_3x3().inverted().transposed()
        if kind=='npc' and '/refined/' in relative:
            for vertex in mesh.vertices:
                p=mapped(transform@vertex.co)
                skin_weights[tuple(round(float(c),6) for c in p)]=[[obj.vertex_groups[g.group].name,round(g.weight,7)] for g in vertex.groups if g.weight>0]
        bone = obj.vertex_groups[0].name if kind == 'npc' and obj.vertex_groups else ''
        uv = mesh.uv_layers.active
        for tri in mesh.loop_triangles:
            if kind == 'npc' and obj.vertex_groups:
                weights=defaultdict(float)
                for vertex_index in tri.vertices:
                    for group in mesh.vertices[vertex_index].groups:
                        weights[obj.vertex_groups[group.group].name] += group.weight
                bone=max(weights,key=weights.get) if weights else ''
            material = mesh.materials[tri.material_index] if mesh.materials else None
            material_name = material.name if material else 'default'
            family = ('character_'+ident.removeprefix('NQ-NPC-').lower()) if kind=='npc' and '/refined/' in relative else None
            if ident in user_assets:family=user_assets[ident]['material_keys'].get(material_name)
            if kind == 'building':
                rgb=tuple(round(c*255) for c in material.diffuse_color[:3]) if material else (0,0,0)
                family = 'plaster'
                if 'walnut' in material_name or rgb==(121,81,59): family='wood'
                if ('Wall' in obj.name or 'Masonry' in obj.name or 'Brick' in obj.name) and family=='wood': family='brick'
                if 'stone' in material_name or rgb==(183,156,126): family='stone'
                if 'graphite' in material_name or rgb==(44,48,49): family='metal'
                if 'Awning' in obj.name or 'Canopy' in obj.name or 'coral' in material_name: family='canvas'
                if 'amber' in material_name or rgb==(243,182,95): family='light'
            key = (bone, material_name + ('__'+family if family else ''))
            colors[key] = [1,1,1] if kind=='asset' or (family and family.startswith(('character_','supplied_'))) else list(material.diffuse_color[:3]) if material else [1,1,1]
            corners = []
            # x,z,y changes handedness. Preserve front faces by reversing winding.
            order = (0,2,1) if transform.to_3x3().determinant() > 0 else (0,1,2)
            for index in order:
                loop = tri.loops[index]
                pos = mapped(transform @ mesh.vertices[tri.vertices[index]].co)
                # Needle Records deliberately has a canonical corner pivot in its source.
                if ident == 'NQ-BLD-02': pos -= Vector((16,0,8))
                norm = mapped(normal_transform @ mesh.corner_normals[loop].vector).normalized()
                tex = uv.data[loop].uv if uv else Vector((0,0))
                if kind == 'building':
                    axis=max(range(3),key=lambda i:abs(norm[i]))
                    tile=4 if family=='brick' else 8 if family not in ('wood','metal') else 6
                    tex=Vector(((pos.z if axis==0 else pos.x)/tile, (pos.z if axis==1 else pos.y)/tile))
                # The legacy .mesh reader flips V on import. Keep Blender's V here:
                # adding another flip selects the wrong atlas row (foliage became wood).
                corners.append((pos, norm, (tex.x, tex.y, 0)))
            groups[key].append(corners)
        evaluated.to_mesh_clear()
    parts = []
    for key,triangles in list(groups.items()):
        if len(triangles)>9000:
            del groups[key]
            for index,start in enumerate(range(0,len(triangles),9000)):
                chunk=(key[0],f'Chunk{index}_'+key[1]);groups[chunk]=triangles[start:start+9000];colors[chunk]=colors[key]
    skin = None
    if skin_weights:
        all_triangles=[t for ts in groups.values() for t in ts]
        groups[('', 'ContinuousSkinExport')] = all_triangles
        colors[('', 'ContinuousSkinExport')]=[1,1,1]
    for index, (key, triangles) in enumerate(sorted(groups.items())):
        points = [c[0] for t in triangles for c in t]
        lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
        hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))
        center = (lo + hi) / 2
        folder = OUT / 'meshes' / ident
        folder.mkdir(parents=True, exist_ok=True)
        dest = folder / f'{index:02d}.mesh.tmp'
        with dest.open('w', encoding='ascii', newline='\n') as stream:
            stream.write('version 1.01\n' + str(len(triangles)) + '\n')
            for triangle in triangles:
                stream.write(''.join('['+numbers(p-center)+']['+numbers(n)+']['+numbers(uv)+']' for p,n,uv in triangle)+'\n')
        digest=hashlib.sha256(dest.read_bytes()).hexdigest()
        final=folder/f'{index:02d}-{digest[:12]}.mesh';dest.replace(final);dest=final
        parts.append({'name': key[1], 'bone': key[0], 'surface_family':key[1].split('__')[-1] if '__' in key[1] else None,'center': list(center), 'size': list(hi-lo),
                      'color': colors[key], 'triangles': len(triangles), 'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(),
                      'uri': 'rbxasset://needle-quay/'+str(dest.relative_to(OUT)).replace('\\','/')})
        if key[1]=='ContinuousSkinExport':
            skin=parts.pop()
            skin['weights']=[[list(Vector(p)-center),w] for p,w in skin_weights.items()]
            skin['parents']={b.name:b.parent.name if b.parent else None for b in armature.data.bones}
    records.append({'id': ident, 'kind': kind, 'source': relative, 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                    'resolution': resolution, 'triangles':sum(p['triangles'] for p in parts), 'parts':parts,'joints':joints,'skin':skin,
                    'geometry_route':'exact evaluated triangles, normals and UVs; no decimation'})
    print(ident, records[-1]['triangles'], 'triangles', len(parts), 'parts')
manifest = ROOT / 'assets/local-demo/mesh-manifest.json'
manifest.write_text(json.dumps({'version':1,'assets':records},indent=2),encoding='utf-8')
payload=json.dumps(records,separators=(',',':'));modules=[]
for index,start in enumerate(range(0,len(payload),140000),1):
    name='LocalMeshCatalogData'+str(index);modules.append(name)
    (ROOT/'src/shared'/(name+'.luau')).write_text('return [=['+payload[start:start+140000]+']=]\n',encoding='utf-8')
(ROOT/'src/shared/LocalMeshCatalog.luau').write_text(
    '-- Generated catalog; chunks respect Studio Source assignment limits.\nreturn game:GetService("HttpService"):JSONDecode(table.concat({'+
    ','.join('require(script.Parent.'+name+')' for name in modules)+'}))\n',encoding='utf-8')
print('EXACT_LOCAL_ASSETS',len(records),'TRIANGLES',sum(r['triangles'] for r in records))
