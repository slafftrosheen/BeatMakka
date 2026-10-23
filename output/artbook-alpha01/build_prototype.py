"""Build the offline design study using original project WAVs. No uploads."""
from pathlib import Path
import base64
import json
ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[1]
names = [('kick','Kick'),('snare','Snare'),('closed_hat','Closed hat'),('open_hat','Open hat'),
         ('clap','Clap'),('rim','Rim'),('low_tom','Low tom'),('high_tom','High tom'),
         ('shaker','Shaker'),('tambourine','Tambourine'),('bell','Bell'),('pluck','Pluck'),
         ('bass_c','Bass C'),('bass_eb','Bass E-flat'),('bass_g','Bass G'),('chord','Chord'),
         ('metal_hit','Quay metal'),('vent_thump','Vent thump'),('robot_chirp','Helper chirp')]
samples = [{'id':id,'label':label,'discovery':i>=16,
            'data':base64.b64encode((PROJECT/f'assets/production/audio/{id}.wav').read_bytes()).decode('ascii')}
           for i,(id,label) in enumerate(names)]
template=(ROOT/'prototype.template.html').read_text(encoding='utf-8')
(ROOT/'MK-I_Prototype.html').write_text(template.replace('__SAMPLES_JSON__',json.dumps(samples,separators=(',',':'))),encoding='utf-8')
print(json.dumps({'prototype':str(ROOT/'MK-I_Prototype.html'),'embedded_original_samples':len(samples)}))
