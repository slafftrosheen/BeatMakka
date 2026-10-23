"""Adapt retained user alpha maps to the existing atlas. No uploads or source edits.

Initial --import-sources copies exactly two named TIFF files from the supplied
Assets folder. Subsequent builds and --verify work entirely from repo copies.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image

from build_content_sources import SETS, SLOTS, SLOT_CHANNEL, rgb
from build_finish_candidates import detail, gutter, write_map

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/candidates/materials/assets-folder-v1'
SOURCES = ROOT / 'assets/sources/materials/user-assets-v1'
EXTERNAL = Path('C:/Users/slavd/OneDrive/Pictures/Assets')
SOURCE_PATHS = {
    'wood_fibers_06_height.tif': 'Stylized Edition/Textures/Alphas/Wood/wood_fibers_06_height.tif',
    'metal_scratch_01_height.tif': 'Stylized Edition/Textures/Alphas/Metal/metal_scratch_01_height.tif',
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_digest(path):
    return hashlib.sha256(path.read_bytes().replace(b'\r\n', b'\n')).hexdigest()


def image_bindings():
    images = json.loads((ROOT/'data/content-ids.json').read_text())['Images']
    return hashlib.sha256(json.dumps(images, sort_keys=True).encode()).hexdigest()


def import_sources():
    assert not SOURCES.exists(), 'Retained sources already exist; never overwrite'
    SOURCES.mkdir(parents=True)
    records = []
    for name, relative in SOURCE_PATHS.items():
        source, target = EXTERNAL/relative, SOURCES/name
        shutil.copyfile(source, target)
        assert digest(source) == digest(target)
        with Image.open(target) as im:
            assert im.mode == 'I;16' and im.size == (4096, 4096)
        records.append({'file': name, 'source_relative_to_assets': relative,
                        'sha256': digest(target), 'bytes': target.stat().st_size,
                        'mode': 'I;16', 'size': [4096, 4096]})
    (SOURCES/'provenance.json').write_text(json.dumps({
        'source_root': str(EXTERNAL), 'files': records,
        'permission': 'User expressly directed use of materials from their Assets folder and repository copies of everything used.',
        'upstream_license': None, 'license_independently_verified': False,
        'note': 'User-provided reuse authorization; no claim that these visual assets are CC0 or freeware.'
    }, indent=2)+'\n', encoding='utf-8')


def height(name, size, crop=None):
    with Image.open(SOURCES/name) as im:
        assert im.mode == 'I;16' and im.size == (4096, 4096)
        values = np.asarray(im, dtype=np.float32)/65535
    image = Image.fromarray(values)
    if crop:
        image = image.crop(crop)
    result = np.asarray(image.resize(size, Image.Resampling.LANCZOS))
    assert np.isfinite(result).all()
    return np.clip(result, 0, 1)


def source_details():
    grain = height('wood_fibers_06_height.tif', (240, 240), (256, 256, 3840, 3840))
    grain = np.clip(grain/max(float(np.quantile(grain, .99)), .01), 0, 1)
    grain -= grain.mean()
    stamp = height('metal_scratch_01_height.tif', (20, 64))
    # Sparse local handling marks, not object-specific edges or baked shadows.
    scratch = np.zeros((240, 240), dtype=np.float32)
    for x, y in [(28, 39), (127, 116), (190, 58)]:
        scratch[y:y+64, x:x+20] = np.maximum(scratch[y:y+64, x:x+20], stamp)
    result = []
    for i, (name, _, _, _) in enumerate(SLOTS):
        color, rough = detail(name, i)
        if name == 'wood':
            color = grain*20
            rough = -grain*.12
        elif name in ('paint_primary', 'paint_secondary', 'trim', 'accent'):
            color = color*.35 - scratch*12
            rough = rough*.35 + scratch*.14
        elif name == 'bare_metal':
            color = color*.5 - scratch*8
            rough = rough*.5 + scratch*.18
        result.append((color, rough))
    return result


def build(dest):
    assert not (ROOT/'docs/evidence/a01-07-application/approval.json').exists(), 'Approved revision is frozen; use its recorded source commit for reproduction'
    assert not dest.exists(), 'Candidate exists; verify it or create a new version'
    provenance = json.loads((SOURCES/'provenance.json').read_text())
    for record in provenance['files']:
        assert digest(SOURCES/record['file']) == record['sha256']
    dest.mkdir(parents=True)
    shutil.copyfile(ROOT/'assets/production/materials/layout.json', dest/'layout.json')
    details = source_details()
    roughness, metalness = np.zeros((1024, 1024)), np.zeros((1024, 1024))
    for i, (_, _, rough, metal) in enumerate(SLOTS):
        x, y = i%4*256, i//4*256
        roughness[y:y+256, x:x+256] = gutter(np.clip(rough+details[i][1], 0, 1)*255)
        metalness[y:y+256, x:x+256] = metal*255
    for channel, values in [('roughness', roughness), ('metalness', metalness)]:
        write_map(dest/'shared'/f'atlas_{channel}.png', values)
        write_map(dest/'shared'/f'atlas_{channel}_512.png', np.asarray(Image.fromarray(values.astype('uint8')).resize((512, 512), Image.Resampling.BOX)))
    for finish, spec in SETS.items():
        atlas = np.zeros((1024, 1024, 3))
        for i, (name, color, _, _) in enumerate(SLOTS):
            color = spec.get('materials', {}).get(name, spec.get(SLOT_CHANNEL.get(name), color))
            x, y = i%4*256, i//4*256
            atlas[y:y+256, x:x+256] = gutter(rgb(color)[None, None, :]+details[i][0][:, :, None])
        path = dest/'sets'/finish/'atlas_basecolor.png'
        write_map(path, atlas)
        write_map(path.with_name('atlas_basecolor_512.png'), np.asarray(Image.open(path).resize((512, 512), Image.Resampling.LANCZOS)))
    manifest = {
        'schema': 1, 'id': 'assets-folder-v1', 'stage': 'candidate',
        'art_approved': False, 'studio_imported': False, 'runtime_verified': False, 'uploaded': False,
        'layout': 'FZ_MaterialAtlas_v1', 'resolutions': [512, 1024], 'gutter_1024': 8,
        'sources': str(SOURCES.relative_to(ROOT)).replace('\\', '/')+'/provenance.json',
        'source_provenance_sha256': normalized_digest(SOURCES/'provenance.json'),
        'inputs': {str(p.relative_to(ROOT)).replace('\\', '/'): normalized_digest(p) for p in [Path(__file__), ROOT/'tools/build_content_sources.py', ROOT/'tools/build_finish_candidates.py', ROOT/'assets/production/materials/layout.json']},
        'image_bindings_sha256': image_bindings(),
        'processing': {'wood': '16-bit linear height; crop [256,256,3840,3840], Lanczos 240px; normalize 99th percentile, subtract mean, color amplitude20/255 and roughness-.12.',
                       'handling': '16-bit scratch alpha resampled20x64; three fixed placements; paint color-12/255 and roughness+.14, metal-8/255 and+.18.',
                       'other_roles': 'Existing deterministic tactile detail and palette; no normal maps, displacement, geometry, baked lighting or text.'},
        'files': {str(p.relative_to(dest)).replace('\\', '/'): digest(p) for p in sorted(dest.rglob('*')) if p.is_file()},
    }
    (dest/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')


def verify(dest):
    manifest = json.loads((dest/'manifest.json').read_text())
    assert not any(manifest[k] for k in ['art_approved', 'studio_imported', 'runtime_verified', 'uploaded'])
    approval_path = ROOT/'docs/evidence/a01-07-application/approval.json'
    if approval_path.exists():
        approval = json.loads(approval_path.read_text())
        assert approval['art_approved'] is True and approval['candidate'] == manifest['id']
        assert digest(dest/'manifest.json') == approval['manifest_sha256'], 'Approved artifact changed'
        assert manifest['image_bindings_sha256'] == approval['artifact_image_bindings_sha256']
        for relative, expected in manifest['inputs'].items():
            original = subprocess.check_output(['git', 'show', approval['approved_source_commit']+':'+relative], cwd=ROOT)
            assert hashlib.sha256(original.replace(b'\r\n', b'\n')).hexdigest() == expected, relative
    else:
        assert manifest['image_bindings_sha256'] == image_bindings()
        for relative, expected in manifest['inputs'].items():
            assert normalized_digest(ROOT/relative) == expected, relative
    assert normalized_digest(SOURCES/'provenance.json') == manifest['source_provenance_sha256']
    provenance = json.loads((SOURCES/'provenance.json').read_text())
    assert {r['file'] for r in provenance['files']} == set(SOURCE_PATHS)
    for record in provenance['files']:
        assert digest(SOURCES/record['file']) == record['sha256']
    expected = {'layout.json'}
    expected.update(f'sets/{f}/atlas_basecolor{s}.png' for f in SETS for s in ['', '_512'])
    expected.update(f'shared/atlas_{c}{s}.png' for c in ['roughness', 'metalness'] for s in ['', '_512'])
    actual = {str(p.relative_to(dest)).replace('\\', '/') for p in dest.rglob('*') if p.is_file()}
    assert actual == expected|{'manifest.json'} and set(manifest['files']) == expected
    assert normalized_digest(dest/'layout.json') == normalized_digest(ROOT/'assets/production/materials/layout.json')
    for relative, expected_hash in manifest['files'].items():
        path = dest/relative
        assert digest(path) == expected_hash, relative
        if path.suffix != '.png':
            continue
        with Image.open(path) as im:
            size = 512 if '_512' in path.name else 1024
            assert im.size == (size, size) and im.mode == ('RGB' if 'basecolor' in path.name else 'L')
            if size == 1024:
                values = np.asarray(im)
                for y in range(0, 1024, 256):
                    for x in range(0, 1024, 256):
                        tile = values[y:y+256, x:x+256]
                        assert np.all(tile[:8] == tile[8]) and np.all(tile[-8:] == tile[-9])
                        assert np.all(tile[:, :8] == tile[:, 8:9]) and np.all(tile[:, -8:] == tile[:, -9:-8])
    return {'passed': True, 'stage': 'frozen candidate snapshot', 'sources': 2, 'maps': 12, 'palettes': 4, 'layout_and_approval_snapshot_verified': True}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--import-sources', action='store_true')
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--output', type=Path, default=DEST)
    args = parser.parse_args()
    if args.import_sources:
        assert not args.verify
        import_sources()
    if not args.verify:
        build(args.output)
    print(json.dumps(verify(args.output)))
