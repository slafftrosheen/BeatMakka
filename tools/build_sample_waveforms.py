"""Real local PCM peak envelopes for the sample editor; no generated imagery."""
from pathlib import Path
import json,wave,array
root=Path(__file__).resolve().parents[1];result={}
for row in json.loads((root/'assets/local-demo/install-manifest.json').read_text())['files']:
 if not row['file'].startswith('audio/'):continue
 p=root/'assets/local-demo/content/needle-quay'/row['file']
 with wave.open(str(p),'rb') as w:
  if w.getsampwidth()!=2:continue
  frames=w.getnframes();channels=w.getnchannels();rate=w.getframerate();samples=array.array('h',w.readframes(frames))
  peaks=[]
  for i in range(64):
   chunk=samples[i*len(samples)//64:(i+1)*len(samples)//64]
   peaks.append(round(max((abs(v)for v in chunk),default=0)/32768,3))
  result[p.stem]={'duration':round(frames/rate,5),'peaks':peaks}
out=root/'src/shared/SampleWaveforms.luau'
out.write_text('-- Generated from the actual companion WAV files.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(result,separators=(',',':'))+']=])\n',encoding='utf-8')
print('Waveforms',len(result))
