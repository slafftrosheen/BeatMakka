"""Prepare downloaded ambient candidates for local playback; no generation calls."""
from pathlib import Path
import json
import hashlib
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/production/needle-quay/ambience'
receipt = json.loads((OUT / 'generation-receipt.json').read_text())
for record in receipt['records']:
    path = ROOT / record['file']
    record['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
runtime = []
for name in ('waterfront', 'market', 'cafe', 'repair'):
    source = OUT / 'source' / f'{name}-take1.mp3'
    target = OUT / f'{name}.mp3'
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(source),
                    '-af', 'loudnorm=I=-23:TP=-6:LRA=7', '-ac', '1', '-ar', '44100',
                    '-b:a', '128k', str(target)], check=True)
    runtime.append({'id': name, 'file': target.relative_to(ROOT).as_posix(),
                    'source': source.relative_to(ROOT).as_posix(),
                    'sha256': hashlib.sha256(target.read_bytes()).hexdigest()})
receipt['runtime'] = runtime
receipt['processing'] = 'Take 1 per zone; mono 44.1kHz MP3, loudnorm I=-23 TP=-6 LRA=7. All alternate source takes preserved.'
receipt['acceptance'] = 'Generated and locally prepared; perceptual loop quality and Studio playback remain unverified.'
(OUT / 'provenance.json').write_text(json.dumps(receipt, indent=2))
print('Prepared four ambience beds; preserved sixteen source takes.')
