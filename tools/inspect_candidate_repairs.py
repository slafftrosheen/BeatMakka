"""Re-import repaired candidate GLBs and verify geometry, pivots, caps and UVs."""
import bpy, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPECS = {
    'P12': ((3.0, 3.0, 4.0), 'floor-center', 550),
    'P13': ((1.5, 1.5, 2.0), 'rear-center', 500),
    'P14': ((2.0, 1.0, 3.0), 'rear-center', 400),
    'I01': ((3.0, 0.3, 2.0), 'upper-hinge', 300),
    'I04': ((3.0, 1.5, 4.0), 'rear-center', 650),
    'I05': ((3.0, 2.0, 4.0), 'floor-center', 800),
}
assets = []
for aid, (expected, pivot, cap) in SPECS.items():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    path = ROOT / 'assets' / 'cleaned' / aid / f'{aid}_art_repair_candidate.glb'
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    points = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    mins = [min(p[i] for p in points) for i in range(3)]
    maxs = [max(p[i] for p in points) for i in range(3)]
    dims = [maxs[i] - mins[i] for i in range(3)]
    anchor = [
        (mins[0] + maxs[0]) / 2,
        (maxs[1] if pivot in ('rear-center', 'upper-hinge') else (mins[1] + maxs[1]) / 2),
        (mins[2] if pivot == 'floor-center' else maxs[2] if pivot == 'upper-hinge' else (mins[2] + maxs[2]) / 2),
    ]
    triangles = sum(sum(len(poly.vertices) - 2 for poly in o.data.polygons) for o in meshes)
    uv_count = sum(len(o.data.uv_layers) for o in meshes)
    materials = sorted({m.name for o in meshes for m in o.data.materials if m})
    dim_ok = all(abs(dims[i] - expected[i]) <= 0.005 for i in range(3))
    pivot_ok = all(abs(v) <= 0.005 for v in anchor)
    tri_ok = triangles <= cap
    uv_ok = uv_count > 0
    assets.append({
        'asset_id': aid, 'reimported_glb': path.relative_to(ROOT).as_posix(),
        'dimensions_blender_xyz': [round(v, 6) for v in dims], 'expected_xyz': list(expected),
        'pivot': pivot, 'pivot_anchor_xyz': [round(v, 6) for v in anchor],
        'triangles': triangles, 'triangle_cap': cap, 'triangle_cap_pass': tri_ok,
        'mesh_objects': len(meshes), 'uv_layers_across_meshes': uv_count,
        'uv_pass': uv_ok, 'materials': materials,
        'dimensions_pass': dim_ok, 'pivot_pass': pivot_ok,
        'pass': dim_ok and pivot_ok and tri_ok and uv_ok,
    })

receipt = {'blender_version': bpy.app.version_string, 'assets': assets,
           'all_pass': all(a['pass'] for a in assets)}
out = ROOT / 'docs' / 'evidence' / 'dcc-normalization' / 'art-repair-export-inspection.json'
out.write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
print(json.dumps(receipt, indent=2))
if not receipt['all_pass']:
    raise SystemExit('One or more re-imported candidate checks failed')
