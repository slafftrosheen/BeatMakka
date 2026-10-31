"""Create bounded runtime copies; keep authored textures and UVs unchanged."""
from pathlib import Path
import hashlib, json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / 'assets/local-demo/content/needle-quay'

def prepare(active, provenance):
    bindings, unique = {}, {}
    for relative in sorted(active):
        source = CONTENT / relative
        if source.suffix.lower() != '.png':
            continue
        # Editable textures compete with character geometry on the Play client.
        limit = 768 if relative.startswith('companions/') else (512 if relative.startswith(('buildings-set-01/', 'vintage-van/', 'ui/')) or 'character_' in relative else 384)
        if relative.startswith('ui-device-v3/'):
            limit = 1024 if relative.endswith(('faceplate.png', 'journal.png', 'bezel-v4.png')) else (512 if relative.endswith('sleeve-v4.png') else 384)
        if any(channel in relative for channel in ('_normal', '_rough', 'roughness', 'metalness')):
            limit = 192
        with Image.open(source) as original:
            image = original.convert('RGBA')
            image.thumbnail((limit, limit), Image.Resampling.LANCZOS)
            digest = hashlib.sha256(image.tobytes() + str(image.size).encode()).hexdigest()[:20]
            target = 'runtime-textures/' + digest + '.png'
            (CONTENT / target).parent.mkdir(parents=True, exist_ok=True)
            image.save(CONTENT / target)
            unique[target] = image.width * image.height * 4
        bindings['rbxasset://needle-quay/' + relative] = 'rbxasset://needle-quay/' + target
        provenance.append({'source':source.relative_to(ROOT).as_posix(), 'file':target,
            'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'sha256':hashlib.sha256((CONTENT / target).read_bytes()).hexdigest(),
            'transform':'bounded runtime copy; UV layout unchanged', 'max_edge':limit})
    active.update(unique)
    (ROOT / 'src/shared/LocalTextureBudget.luau').write_text(
        '-- Generated local runtime texture bindings. Original images are retained.\nreturn game:GetService("HttpService"):JSONDecode([=[' + json.dumps(bindings,separators=(',',':')) + ']=])\n', encoding='utf-8')
    report = ROOT / 'docs/evidence/needle-quay-memory-fix'
    report.mkdir(parents=True, exist_ok=True)
    (report / 'texture-budget.json').write_text(json.dumps({'unique_runtime_images':len(unique),
        'all_variant_rgba_bytes':sum(unique.values()), 'note':'Uncompressed pixel estimate, not measured engine memory; includes unused assets.'},indent=2))
