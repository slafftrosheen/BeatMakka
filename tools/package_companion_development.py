"""Package the revised companion source/art handoff; preserve the supplied pack unchanged."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/needle-quay-demo/BeatMakka_Companions_v2_Development.zip'
PREFIX = 'BeatMakka_Companions_v2/'
paths = set()
for folder in ('src', 'assets/references/companions/provided-pack-v1',
               'assets/production/needle-quay/companions', 'assets/concepts/companions',
               'docs/evidence/issue-20-pack-continuation'):
    paths.update(p for p in (ROOT / folder).rglob('*')
                 if p.is_file() and p.suffix not in ('.blend1', '.blend2', '.zip'))
production=json.loads((ROOT/'assets/production/needle-quay/companions/model-manifest.json').read_text(encoding='utf-8'))
for character in production['characters']:
    paths.update(ROOT/'assets/local-demo/content/needle-quay'/name for name in character['runtime_content_files'])
for name in ('data/companion-production.v1.json', 'rokit.toml',
             'docs/COMPANION_ARTBOOK_RU.md', 'docs/COMPANION_DEV_HANDOFF_RU.md',
             'docs/COMPANION_PACK_CONTINUATION_2026-10-26.md',
             'docs/BeatMakka_Companions_Artbook_v3_CANDIDATE_RU.pdf',
             'tools/build_companion_candidates.py', 'tools/render_companion_details.py',
             'tools/build_companion_handoff.py', 'tools/package_companion_development.py'):
    paths.add(ROOT / name)

def digest(data):
    return hashlib.sha256(data).hexdigest()

manifest = {'base_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
            'stage': 'LOCAL_SOURCE_AND_DCC_CANDIDATE', 'uploads': 0, 'provider_spend': 0,
            'integration': 'Reviewed source snapshot for the existing BeatMakka repository, not a blind patch or standalone game.',
            'files': []}
readme = '''# BeatMakka Companions v2 / revised development pack

This edits and extends the supplied v1 pack against the current local project.
Open docs/BeatMakka_Companions_Artbook_v3_CANDIDATE_RU.pdf and the continuation report.
The original supplied documents, artwork and obsolete patch are preserved under
assets/references/companions/provided-pack-v1 with provenance; do not run that patch.

Added: sound notebook, saved-beat observations, optional place conversations,
local 3D character cards, revised DCC shapes/clothes/accessories and gesture timing.
All art remains candidate; no facial animation or device/multiplayer acceptance.

src/ is the CURRENT COMPLETE SOURCE SNAPSHOT, including existing game modules.
Integrate by review into the matching existing repository; never overwrite unrelated
work blindly. This handoff omits unrelated environment/audio dependencies and is not
an independent Rojo project. The separate NeedleQuay-Companions.zip is the runnable
local Studio demo with its checksum-verified content and launcher.

No new services, dependencies, test suites, paid operations, Roblox uploads, commits
or pushes. Existing profile schema and all music/quest authority are retained.
manifest.json records exact file hashes and the unchanged Git base.
'''
OUT.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(OUT, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    payload = readme.encode('utf-8')
    archive.writestr(PREFIX + 'README.md', payload)
    manifest['files'].append({'path': 'README.md', 'bytes': len(payload), 'sha256': digest(payload)})
    for path in sorted(paths):
        relative = path.relative_to(ROOT).as_posix()
        payload = path.read_bytes()
        archive.writestr(PREFIX + relative, payload)
        manifest['files'].append({'path': relative, 'bytes': len(payload), 'sha256': digest(payload)})
    archive.writestr(PREFIX + 'manifest.json', json.dumps(manifest, indent=2))
with zipfile.ZipFile(OUT) as archive:
    assert archive.testzip() is None
    for entry in manifest['files']:
        assert digest(archive.read(PREFIX + entry['path'])) == entry['sha256']
print(json.dumps({'path': OUT.relative_to(ROOT).as_posix(), 'bytes': OUT.stat().st_size,
                  'files': len(manifest['files']), 'sha256': digest(OUT.read_bytes()),
                  'verified_sha256': True}, indent=2))
