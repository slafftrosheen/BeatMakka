"""Apply the pinned user-approved material revision and bake runtime templates.

No upload or ID invention. Canonical bindings are changed only by the existing
receipt merger. --verify checks production bytes and authored template IDs.
"""
import argparse
import hashlib
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageChops

from build_assets_folder_finishes import DEST, ROOT, verify

EVIDENCE = ROOT/'docs/evidence/a01-07-application'
PRODUCTION = ROOT/'assets/production/materials'
RUNTIME = ROOT/'assets/runtime/AppearanceLibrary.rbxmx'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def template_bytes(ids):
    root = ET.Element('roblox', version='4')
    folder = ET.SubElement(root, 'Item', {'class': 'Folder', 'referent': 'AppearanceLibrary'})
    props = ET.SubElement(folder, 'Properties')
    ET.SubElement(props, 'string', name='Name').text = 'AppearanceLibrary'
    for finish in ['quay', 'chalk', 'coral', 'afterhours']:
        for size in [512, 1024]:
            name = f'{finish}_{size}'
            item = ET.SubElement(folder, 'Item', {'class': 'SurfaceAppearance', 'referent': name})
            props = ET.SubElement(item, 'Properties')
            ET.SubElement(props, 'string', name='Name').text = name
            for prop, key in [('ColorMap', f'atlas.{finish}.basecolor.{size}'),
                              ('RoughnessMap', f'atlas.roughness.{size}'),
                              ('MetalnessMap', f'atlas.metalness.{size}')]:
                assert type(ids[key]) is int and 0 < ids[key] < 2**53
                content = ET.SubElement(props, 'Content', name=prop)
                ET.SubElement(content, 'url').text = f'rbxassetid://{ids[key]}'
    ET.indent(root)
    return ET.tostring(root, encoding='utf-8', xml_declaration=True)+b'\n'


def apply():
    verify(DEST)
    approval = json.loads((EVIDENCE/'approval.json').read_text())
    assert approval['art_approved'] is True
    candidate = json.loads((DEST/'manifest.json').read_text())
    layout = (DEST/'layout.json').read_bytes().replace(b'\r\n', b'\n')
    assert (PRODUCTION/'layout.json').read_bytes().replace(b'\r\n', b'\n') == layout
    changes, reused = [], []
    for relative in candidate['files']:
        if not relative.endswith('.png'):
            continue
        source, target = DEST/relative, PRODUCTION/relative
        with Image.open(source) as a, Image.open(target) as b:
            same = a.mode == b.mode and a.size == b.size and ImageChops.difference(a, b).getbbox() is None
        if same:
            reused.append(relative)
        else:
            shutil.copyfile(source, target)
            changes.append(relative)
    record = {'schema': 1, 'revision': 'assets-folder-v1', 'stage': 'art-approved; upload/runtime evidence recorded separately',
              'approval': 'docs/evidence/a01-07-application/approval.json',
              'candidate_manifest_sha256': sha(DEST/'manifest.json'),
              'files': {p: sha(PRODUCTION/p) for p in candidate['files'] if p.endswith('.png')}}
    (PRODUCTION/'revision.json').write_text(json.dumps(record, indent=2)+'\n', encoding='utf-8')
    # Preserve unrelated audio/graphics records and their provenance.
    path = ROOT/'assets/production/source-manifest.json'
    source_manifest = json.loads(path.read_text())
    for entry in source_manifest['files']:
        file = ROOT/entry['path']
        if file.is_relative_to(PRODUCTION) and file.suffix == '.png' and str(file.relative_to(PRODUCTION)).replace('\\', '/') in record['files']:
            entry.update(bytes=file.stat().st_size, sha256=sha(file), material_revision='assets-folder-v1')
    source_manifest['material_revision'] = 'assets/production/materials/revision.json'
    source_manifest['provenance'] = 'Original deterministic graphics/audio and authoring masks; approved user-supplied wood/scratch-derived material atlas. See material revision and retained source provenance.'
    path.write_text(json.dumps(source_manifest, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'copied_maps': len(changes), 'pixel_identical_reused': reused}))


def bake():
    ids = json.loads((ROOT/'data/content-ids.json').read_text())['Images']
    RUNTIME.parent.mkdir(parents=True, exist_ok=True)
    RUNTIME.write_bytes(template_bytes(ids))


def verify_production():
    verify(DEST)
    revision = json.loads((PRODUCTION/'revision.json').read_text())
    assert revision['candidate_manifest_sha256'] == sha(DEST/'manifest.json')
    for relative, expected in revision['files'].items():
        assert sha(PRODUCTION/relative) == expected
        with Image.open(PRODUCTION/relative) as a, Image.open(DEST/relative) as b:
            assert a.mode == b.mode and a.size == b.size and ImageChops.difference(a, b).getbbox() is None
    ids = json.loads((ROOT/'data/content-ids.json').read_text())
    assert RUNTIME.read_bytes() == template_bytes(ids['Images']), 'Runtime templates are stale'
    approval = json.loads((EVIDENCE/'approval.json').read_text())
    assert ids['Audio'] == approval['previous_bindings']['Audio'], 'Material update changed audio bindings'
    for key in ['ui.icons', 'ui.panel', 'atlas.metalness.512', 'atlas.metalness.1024']:
        assert ids['Images'][key] == approval['previous_bindings']['Images'][key], 'Unchanged image rebound'
    print(json.dumps({'passed': True, 'production_maps': 12, 'authored_templates': 8, 'audio_preserved': len(ids['Audio'])}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--bake', action='store_true')
    parser.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    assert args.apply or args.bake or args.verify
    if args.apply:
        apply()
    if args.bake:
        bake()
    if args.verify:
        verify_production()
