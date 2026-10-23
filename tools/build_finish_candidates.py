"""Original, deterministic material study. Never changes production or uploads.

Run with the existing project Python/Pillow/NumPy runtime. Candidate only:
preserves FZ_MaterialAtlas_v1, four palettes, 1024/512 sizes and eight-pixel
gutter. No baked lighting, text, provider media, new dependencies or normal map.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

from build_content_sources import SETS, SLOTS, SLOT_CHANNEL, rgb

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/candidates/materials/tactile-v1"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def input_sha(path):
    # Git's JSON eol=lf differs from existing Windows generated working bytes.
    return hashlib.sha256(path.read_bytes().replace(b'\r\n', b'\n')).hexdigest()


def detail(name, index, size=240):
    rng = np.random.default_rng(8000 + index)
    y, x = np.mgrid[:size, :size] / size
    fine = rng.normal(0, 0.65, (size, size))
    broad = np.sin(2 * np.pi * (x * 2 + y))
    value = fine + broad * 0.6
    rough = fine * 0.008
    wear = np.zeros((size, size), dtype=bool)
    if name == "wood":
        # Broad continuous grain and a softer second growth frequency.
        phase = y * 5 + 0.18 * np.sin(x * 2 * np.pi) + 0.05 * np.sin(x * 6 * np.pi)
        grain = np.sin(phase * 2 * np.pi)
        value = 5.5 * grain + 1.6 * np.sin(phase * 4 * np.pi) + fine
        rough += grain * 0.035
    elif name in ("paint_primary", "paint_secondary", "trim", "accent"):
        # Sparse handling marks; no fake per-object edge wear in shared UV tiles.
        for _ in range(12):
            cx, cy = rng.integers(12, size - 12, 2)
            length = int(rng.integers(2, 7))
            wear[cy, cx:cx + length] = True
        value = value * 0.7 - wear * 9
        rough += wear * 0.13
    elif name == "bare_metal":
        brushed = np.sin(y * np.pi * 150)
        value += brushed * 1.4
        rough += brushed * 0.025
    elif name == "rubber":
        stipple = np.sin(x * 2 * np.pi * 38) * np.sin(y * 2 * np.pi * 38)
        value = fine * 0.4 + stipple * 0.7
        rough += stipple * 0.012
    elif name in ("canvas", "cloth", "cloth_trim"):
        weave = np.sin(x * 2 * np.pi * 30) * np.sin(y * 2 * np.pi * 30)
        value += weave * 2.2
        rough += weave * 0.02
    elif name == "stone":
        value += 1.5 * np.sin(x * 6 * np.pi) * np.sin(y * 8 * np.pi)
    return value, rough


def gutter(tile):
    return np.pad(tile, ((8, 8), (8, 8)) + (((0, 0),) if tile.ndim == 3 else ()), mode="edge")


def write_map(path, array):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.uint8(np.clip(array, 0, 255))).save(path, optimize=True)


def build():
    if DEST.exists():
        raise SystemExit("Candidate exists; use --verify, do not overwrite review bytes")
    DEST.mkdir(parents=True)
    layout = ROOT / "assets/production/materials/layout.json"
    (DEST / "layout.json").write_bytes(layout.read_bytes())
    rmap, mmap = np.zeros((1024, 1024)), np.zeros((1024, 1024))
    details = [detail(name, i) for i, (name, _, _, _) in enumerate(SLOTS)]
    for i, (_, _, rough, metal) in enumerate(SLOTS):
        x, y = i % 4 * 256, i // 4 * 256
        rmap[y:y + 256, x:x + 256] = gutter(np.clip(rough + details[i][1], 0, 1) * 255)
        mmap[y:y + 256, x:x + 256] = metal * 255
    for name, array in [("roughness", rmap), ("metalness", mmap)]:
        write_map(DEST / "shared" / f"atlas_{name}.png", array)
        write_map(DEST / "shared" / f"atlas_{name}_512.png", np.asarray(Image.fromarray(np.uint8(array)).resize((512, 512), Image.Resampling.BOX)))
    for set_id, spec in SETS.items():
        atlas = np.zeros((1024, 1024, 3))
        for i, (name, color, _, _) in enumerate(SLOTS):
            color = spec.get(SLOT_CHANNEL.get(name), color)
            color = spec.get("materials", {}).get(name, color)
            x, y = i % 4 * 256, i // 4 * 256
            atlas[y:y + 256, x:x + 256] = gutter(rgb(color)[None, None, :] + details[i][0][:, :, None])
        path = DEST / "sets" / set_id / "atlas_basecolor.png"
        write_map(path, atlas)
        write_map(path.with_name("atlas_basecolor_512.png"), np.asarray(Image.open(path).resize((512, 512), Image.Resampling.LANCZOS)))
    manifest = {
        "schema": 1, "id": "tactile-v1", "stage": "candidate", "art_approved": False,
        "studio_imported": False, "runtime_verified": False, "uploaded": False,
        "provenance": "Original mathematical synthesis; fixed RNG seed 8000 + slot index. No third-party bitmap or paid provider.",
        "authority": "01_Visual_Artbook.pdf pages 4, 7, 9; 02_Production_Atlas.pdf T01-T04; approved Needle Quay style board",
        "layout": "FZ_MaterialAtlas_v1", "resolutions": [512, 1024], "gutter_1024": 8,
        "notes": "Broad wood grain, restrained handling marks, satin metal and dense matte rubber. Shared UVs cannot place convincing object-specific edge damage. No baked light or text.",
        "generator_sha256": input_sha(Path(__file__)), "production_layout_sha256": input_sha(layout),
        "content_ids_sha256": input_sha(ROOT / "data/content-ids.json"),
        "hash_policy": "Generator and production JSON input hashes normalize CRLF to LF; candidate file roster hashes exact bytes.",
        "files": {str(p.relative_to(DEST)).replace('\\', '/'): sha(p) for p in sorted(DEST.rglob('*')) if p.is_file()},
    }
    (DEST / "manifest.json").write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')


def verify():
    manifest = json.loads((DEST / "manifest.json").read_text(encoding='utf-8'))
    assert manifest['generator_sha256'] == input_sha(Path(__file__))
    assert manifest['production_layout_sha256'] == input_sha(ROOT / 'assets/production/materials/layout.json')
    assert manifest['content_ids_sha256'] == input_sha(ROOT / 'data/content-ids.json')
    assert input_sha(DEST / 'layout.json') == input_sha(ROOT / 'assets/production/materials/layout.json')
    assert set(manifest['files']) == {str(p.relative_to(DEST)).replace('\\', '/') for p in DEST.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for relative, digest in manifest['files'].items():
        path = DEST / relative
        assert sha(path) == digest, relative
        if path.suffix == '.png':
            image = Image.open(path)
            size = 512 if '_512' in path.name else 1024
            assert image.size == (size, size), relative
            assert image.mode == ('RGB' if 'basecolor' in path.name else 'L'), relative
    expected = {'layout.json'}
    for finish in SETS:
        expected.update({f'sets/{finish}/atlas_basecolor.png', f'sets/{finish}/atlas_basecolor_512.png'})
    for channel in ('roughness', 'metalness'):
        expected.update({f'shared/atlas_{channel}.png', f'shared/atlas_{channel}_512.png'})
    assert set(manifest['files']) == expected, 'Unexpected palette/map roster'
    print(json.dumps({'passed': True, 'stage': 'candidate', 'maps': 12, 'palettes': 4, 'layout_unchanged': True, 'bindings_unchanged': True}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    if not args.verify:
        build()
    verify()
