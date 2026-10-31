import os;os.environ['OPENBLAS_NUM_THREADS']='1'
import json
from audit_character_deformation import *
from character_motion_envelopes import envelopes
p=ROOT/'src/shared/CompanionModels.luau';records=decode(p);ep=ROOT/'docs/evidence/needle-quay-skin-repair/companion-deformation.json';reports=json.loads(ep.read_text())
for a in records:
 v,w,e,poses,*_=data(a,full=True);gains,after=envelopes(a,v,w,e,poses);a['suppliedSkin']['motionGains']=gains;a['suppliedSkin']['motionReference']='idle-first-frame'
 r=next(x for x in reports if x['id']==a['id']);r['after']=after;r['motion_gains']=gains;r['motion_reference']='idle-first-frame';print(a['id'],gains,flush=True)
p.write_text('-- Repaired local weights; authored geometry and source clips preserved.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(records,separators=(',',':'))+']=])\n');ep.write_text(json.dumps(reports,indent=2))
