"""Prepare loopback-only source sync for the dedicated local demo Studio place.

Does not launch Studio, run tests, upload, publish, or contact a provider.
Serve work/quay-sync on 127.0.0.1 only if live local source sync is needed.
"""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
out = ROOT / 'work/quay-sync'
out.mkdir(parents=True, exist_ok=True)
records = []
for folder, root in [('server', 'ServerScriptService.Server'), ('shared', 'ReplicatedStorage.Shared'),
                     ('client', 'StarterPlayer.StarterPlayerScripts.Client')]:
    for source in (ROOT / 'src' / folder).glob('*.luau'):
        name = source.stem
        records.append({'path': root if name.startswith('init.') else root + '.' + name,
                        'class': 'Script' if name == 'init.server' else 'LocalScript' if name == 'init.client' else 'ModuleScript',
                        'source': source.read_text(encoding='utf-8')})
records.append({'path': 'StarterPlayer.StarterPlayerScripts.LocalContentLoading', 'class': 'LocalScript',
                'source': (ROOT / 'src/local-loading.client.luau').read_text(encoding='utf-8')})
(out / 'sources.json').write_text(json.dumps(records), encoding='utf-8')
print(f'Prepared {len(records)} scripts for the dedicated local demo')
