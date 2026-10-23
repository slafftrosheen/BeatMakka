"""Build local listening previews from repository kit copies. No autoplay/network.

Each review presents all sixteen pads followed by the same short arrangement at
the kit's suggested BPM. Review gain is -12.04 dB, separate from source edits.
"""
import hashlib
import html
import json
import wave
from pathlib import Path

import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/style-starter-auditions'
OUT.mkdir(parents=True,exist_ok=True)
manifest=json.loads((ROOT/'assets/candidates/audio/style-starters-v1/manifest.json').read_text(encoding='utf-8'))
cards=[]
report=[]
for pack in manifest['packs']:
    signals=[]
    for sample in pack['samples']:
        with wave.open(str(ROOT/sample['file']),'rb') as wav:
            assert (wav.getnchannels(),wav.getsampwidth(),wav.getframerate())==(1,2,44100)
            signals.append(np.frombuffer(wav.readframes(wav.getnframes()),dtype='<i2').astype(float)/32768)
    tick=60/pack['suggested_bpm']/4
    arrangement=np.zeros(int((tick*32+1.2)*44100))
    roles=[s['role'] for s in pack['samples']]
    def pick(options,fallback):
        return next((i for i,r in enumerate(roles) if r in options),fallback)
    kick=pick({'kick','drum','drum_cut'},0)
    snare=pick({'snare'},min(1,len(signals)-1))
    hat=pick({'hat','percussion','percussion_cut'},min(2,len(signals)-1))
    tonal=[i for i,s in enumerate(pack['samples']) if 'target_midi' in s['edits']]
    for bar in range(2):
        events=[(kick,s) for s in [0,8,10]]+[(snare,s) for s in [4,12]]+[(hat,s) for s in range(0,16,2)]
        if tonal:
            events += [(tonal[0],s) for s in [0,6,8,14]]
            events += [(tonal[min(1,len(tonal)-1)],s) for s in [4,12]]
            events += [(tonal[min(2,len(tonal)-1)],s) for s in [2,10]]
        for index,step in events:
            signal=signals[index];start=round((bar*16+step)*tick*44100)
            arrangement[start:start+len(signal)]+=signal*.25
    hits=[]
    for signal in signals:
        hits.extend([signal*.25,np.zeros(round(.2*44100))])
    review=np.concatenate([*hits,np.zeros(44100),arrangement])
    assert np.max(np.abs(review))<.98, 'Review clipping'
    file=OUT/(pack['id']+'.wav')
    with wave.open(str(file),'wb') as wav:
        wav.setparams((1,2,44100,0,'NONE','not compressed'));wav.writeframes(np.rint(review*32767).astype('<i2').tobytes())
    rows=[]
    for sample in pack['samples']:
        relative='../../'+sample['file']
        rows.append('<li>'+html.escape(f'{sample["pad"]:02d} {sample["label"]}')+'<audio controls preload="none" src="'+html.escape(relative,quote=True)+'"></audio></li>')
    cards.append('<section><h2>'+html.escape(pack['label'])+'</h2><p>'+html.escape(pack['key'])+f' · {pack["suggested_bpm"]} BPM guide</p><p>16 pads in order, then a two-bar arrangement.</p><audio controls preload="none" src="'+file.name+'"></audio><details><summary>Individual pads</summary><ol>'+''.join(rows)+'</ol></details></section>')
    report.append({'pack':pack['id'],'key':pack['key'],'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'seconds':len(review)/44100,'review_gain_db':-12.041199826559248,'peak_dbfs':float(20*np.log10(max(np.max(np.abs(review)),1e-9))),'clipped_samples':0,'arrangement_begins_seconds':sum(map(len,hits))/44100+1})
(OUT/'review.json').write_text(json.dumps({'stage':'Listening review pending; not hosted Roblox playback','packs':report},indent=2)+'\n',encoding='utf-8')
(OUT/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Frequency Zero · Style starter kits</title><style>body{font:16px system-ui;background:#202526;color:#e8d8b7;max-width:1000px;margin:auto;padding:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}section{padding:20px;background:#2f3d3c;border-radius:12px}h1{font-size:28px}h2{margin-top:0}audio{width:100%;margin:8px 0}li{margin:12px 0}summary{cursor:pointer;padding:12px 0}button{font:inherit;padding:12px;border:0;border-radius:6px;background:#e8d8b7;color:#202526}</style><h1>Ten style starter kits</h1><p>One coherent key per kit. Tonal and FX pads are source-derived, key-locked versions; percussion is unpitched. Original selected files are retained in the repository. No Roblox upload or listening approval is implied.</p><button id="stop">Stop all previews</button><main>'''+''.join(cards)+'''</main><script>document.addEventListener('play',e=>{if(e.target.tagName==='AUDIO')document.querySelectorAll('audio').forEach(a=>{if(a!==e.target)a.pause()})},true);document.querySelector('#stop').onclick=()=>document.querySelectorAll('audio').forEach(a=>{a.pause();a.currentTime=0});</script></html>''',encoding='utf-8')
print('Built ten full-kit listening WAVs and individual-pad review page')
