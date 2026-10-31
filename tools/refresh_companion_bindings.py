"""Refresh local companion bindings/contracts after DCC export; no upload or tests.

Run after build_companion_candidates.py and render_companion_details.py.
Keeps content-addressed paths so Studio cannot reuse an older geometry cache.
Existing unrelated install entries and historical evidence stay untouched.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / 'assets/local-demo/content/needle-quay'
MANIFEST = ROOT / 'assets/production/needle-quay/companions/model-manifest.json'
CATALOG = ROOT / 'src/shared/CompanionModels.luau'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
models = json.loads(CATALOG.read_text(encoding='utf-8').split('[=[')[1].split(']=]')[0])
install_path = ROOT / 'assets/local-demo/install-manifest.json'
install = json.loads(install_path.read_text(encoding='utf-8'))
install['files'] = [row for row in install['files'] if not row['file'].startswith('companions/')]
provenance_path = ROOT / 'assets/local-demo/content-provenance.json'
provenance = [row for row in json.loads(provenance_path.read_text(encoding='utf-8'))
              if not row['file'].startswith('companions/')]
for model in models:
    slug = model['id'].removeprefix('NQ-CMP-').lower()
    item = next(row for row in manifest['characters'] if row['id'] == model['id'])
    files = set()
    for lod in model['lods']:
        for part in lod['parts']:
            source = CONTENT / part['uri'].removeprefix('rbxasset://needle-quay/')
            part['sha256'] = digest(source)
            relative = f"companions/{slug}_lod{lod['lod']}_{part['bone']}_{part['sha256'][:12]}.mesh"
            target = CONTENT / relative
            if not target.exists():
                target.write_bytes(source.read_bytes())
            part['uri'] = 'rbxasset://needle-quay/' + relative
            files.add(relative)
    model['parts'] = model['lods'][0]['parts']
    atlas = CONTENT / model['atlas'].removeprefix('rbxasset://needle-quay/')
    relative = f'companions/{slug}_color_{digest(atlas)[:12]}.png'
    if not (CONTENT / relative).exists():
        (CONTENT / relative).write_bytes(atlas.read_bytes())
    model['atlas'] = 'rbxasset://needle-quay/' + relative
    files.add(relative)
    item['runtime_content_files'] = sorted(files)
    item['local_lod_files'] = ['assets/local-demo/content/needle-quay/' + name
                             for name in sorted(files) if name.endswith('.mesh')]
    item['provenance']['artbook_refresh'] = 'assets/references/companions/artbook-refresh-provenance.json'
    item['provenance']['generator_sha256'] = digest(ROOT / 'tools/build_companion_candidates.py')
    item['rig_manifest'] = {
        'joints': [{'name': name, 'parent': parent} for name, parent in model['parents'].items()],
        'source_actions': item['source_actions'],
        'runtime_binding': 'rigid-part procedural counterpart; no uploaded animation IDs',
    }
    item['material_manifest'] = [{'name': slug.upper() + '_MatteAtlas',
                                 'base_color_image_size': item['atlas_resolution'],
                                 'atlas_sha256': item['atlas_sha256']}]
    for relative in sorted(files):
        path = CONTENT / relative
        install['files'].append({'file': relative, 'bytes': path.stat().st_size, 'sha256': digest(path)})
        provenance.append({'source': item['source'], 'file': relative, 'sha256': digest(path),
                           'generator': 'tools/build_companion_candidates.py', 'art_stage': item['stage']})
contract_path = ROOT / 'data/companion-production.v1.json'
contract = json.loads(contract_path.read_text(encoding='utf-8'))
contract['characters'] = manifest['characters']
contract['visual_refresh'] = {'date': '2026-10-28', 'stage': 'DCC_CANDIDATE_PENDING_ART_REVIEW',
                            'reference': 'assets/references/companions/artbook-refresh-provenance.json',
                            'tests': 'NOT_RUN', 'studio': 'NOT_RUN',
                            'existing_demo_archives': 'PRE_REFRESH_SNAPSHOTS'}
# Previous observations belong to earlier source and must not imply acceptance of this revision.
if 'local_prototype_observations' in contract:
    contract['historical_local_prototype_observations'] = contract.pop('local_prototype_observations')
write_json(MANIFEST, manifest)
write_json(contract_path, contract)
install['files'].sort(key=lambda row: row['file'])
write_json(install_path, install)
write_json(provenance_path, provenance)
CATALOG.write_text('-- Generated original DCC candidates; art approval remains open.\n'
                   'return game:GetService("HttpService"):JSONDecode([=['
                   + json.dumps(models, separators=(',', ':')) + ']=])\n', encoding='utf-8')
print(json.dumps([(row['id'], row['lod_triangles']) for row in manifest['characters']]))
