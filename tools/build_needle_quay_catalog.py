"""Compile canonical authored data for the local playable demo. No providers."""
import json
from pathlib import Path
R = Path(__file__).resolve().parents[1]
environment = json.loads((R / 'data/needle-quay-environment.v1.json').read_text(encoding='utf-8'))
city = json.loads((R / 'data/world-districts.v1.json').read_text(encoding='utf-8'))
data = {'districts': city['districts'], 'stops': environment['stops'],
        'quests': environment['quests'], 'buildings': [
            {k: b[k] for k in ('id', 'name', 'blockout_center_xz_studs', 'blockout_dimensions_wdh_studs')}
            for b in environment['buildings']]}
(R / 'src/shared/NeedleQuayCatalog.luau').write_text(
    '-- Generated from canonical registers by tools/build_needle_quay_catalog.py.\n'
    'return game:GetService("HttpService"):JSONDecode([=[' + json.dumps(data, ensure_ascii=False, separators=(',', ':')) + ']=])\n', encoding='utf-8')
