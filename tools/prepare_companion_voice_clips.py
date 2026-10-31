"""Split existing ElevenLabs audition take 1 at measured silent gaps; no API calls."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/production/needle-quay/voices'
segments = {
    'alissia': [('turn', 0.08, 0.88), ('success', 1.38, 2.58), ('route', 3.02, 3.90)],
    'nikolas': [('turn', 0, 1.30), ('success', 1.55, 3.02), ('route', 3.52, 4.28)],
}
receipt = json.loads((ROOT / 'docs/evidence/playful-quay/voice-audition-submission.json').read_text())
records = []
for run in receipt['runs']:
    name = run['companion']
    for index, generation in enumerate(run['generationIds'], 1):
        source = OUT / 'source' / f'{name}-take{index}.mp3'
        records.append({'file': source.relative_to(ROOT).as_posix(), 'generationId': generation,
                        'sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'kind': 'original'})
    for cue, start, end in segments[name]:
        target = OUT / f'{name}_{cue}.wav'
        source = OUT / 'source' / f'{name}-take1.mp3'
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(source),
                        '-ss', str(start), '-t', str(end-start), '-ac', '1', '-ar', '44100',
                        '-c:a', 'pcm_s16le', str(target)], check=True)
        records.append({'file': target.relative_to(ROOT).as_posix(), 'source': source.relative_to(ROOT).as_posix(),
                        'startSeconds': start, 'endSeconds': end, 'subtitleId': f'{name}_{cue}',
                        'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'kind': 'runtime-clip'})
(OUT / 'provenance.json').write_text(json.dumps({'provider': 'ElevenLabs', 'model': 'eleven_v4',
    'records': records, 'selection': 'First take of each approved audition set; second takes preserved.',
    'processing': 'Cuts at measured silent gaps, mono 44.1kHz PCM16. No voice transformation.',
    'runtimeVerified': False, 'robloxUploads': 0}, indent=2))
print('Prepared six local voice clips and preserved four source takes.')
