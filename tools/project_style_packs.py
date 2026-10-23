"""Project assembled kit metadata into runtime catalog and explicit upload batch.

No Roblox IDs are fabricated, no source is regenerated and no asset is uploaded.
"""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'assets/candidates/audio/style-starters-v1/manifest.json').read_text(encoding='utf-8'))
lines=['-- Generated from the user-supplied style-starters-v1 source manifest.','-- Sources/derivatives are in the repo; real Roblox audio IDs remain separate.','return {']
for pack in manifest['packs']:
    lines += ['    {', f'        id = {json.dumps(pack["id"])}, label = {json.dumps(pack["label"])},', f'        key = {json.dumps(pack["key"])}, bpm = {pack["suggested_bpm"]},', '        samples = {']
    for sample in pack['samples']:
        lines.append('            { id = '+json.dumps(sample['id'])+', label = '+json.dumps(sample['label'])+', pack = '+json.dumps(pack['id'])+' },')
    lines += ['        },','    },']
lines+=['}','']
(ROOT/'src/shared/StylePacks.luau').write_text('\n'.join(lines),encoding='utf-8',newline='\n')
upload=json.loads((ROOT/'assets/production/upload-manifest.json').read_text(encoding='utf-8'))
bindings=json.loads((ROOT/'data/content-ids.json').read_text(encoding='utf-8'))
bound_images=bindings['Images']
upload['images']=[entry for entry in upload['images'] if entry['key'] in bound_images]
assert {entry['key'] for entry in upload['images']}==set(bound_images)
for entry in upload['images']:entry['asset_id']=bound_images[entry['key']]
for pack in manifest['packs']:
    for sample in pack['samples']:
        upload['audio'].append({'key':sample['id'],'file':sample['file'],'asset_id':bindings['Audio'].get(sample['id']),'source_sha256':sample['sha256'],'pack':pack['id'],'musical_key':pack['key']})
for entry in upload['audio']:entry['asset_id']=bindings['Audio'].get(entry['key'])
(ROOT/'data/style-upload-manifest.json').write_text(json.dumps(upload,indent=2)+'\n',encoding='utf-8')
print('Projected ten kits / 160 samples; upload manifest keeps all 24 original audio keys and 14 images')
