import os;os.environ['OPENBLAS_NUM_THREADS']='1'
import json
from audit_character_deformation import *
from character_motion_envelopes import envelopes
p=ROOT/'assets/local-demo/mesh-manifest.json';m=json.loads(p.read_text());evidence=ROOT/'docs/evidence/needle-quay-skin-repair/npc-deformation.json';reports=json.loads(evidence.read_text())
for a in m['assets']:
 if not a.get('skin'):continue
 v,w,e,poses,*_=data(a);gains,after=envelopes(a,v,w,e,poses);a['skin']['motionGains']=gains
 r=next(r for r in reports if r['id']==a['id']);r['weights_only']=r['after'];r['after']=after;r['motion_gains']=gains;print(a['id'],gains,flush=True)
p.write_text(json.dumps(m,indent=2));evidence.write_text(json.dumps(reports,indent=2))
payload=json.dumps(m['assets'],separators=(',',':'));modules=[]
for i,start in enumerate(range(0,len(payload),140000),1):
 name='LocalMeshCatalogData'+str(i);modules.append(name);(ROOT/'src/shared'/(name+'.luau')).write_text('return [=['+payload[start:start+140000]+']=]\n')
(ROOT/'src/shared/LocalMeshCatalog.luau').write_text('return game:GetService("HttpService"):JSONDecode(table.concat({'+','.join('require(script.Parent.'+n+')'for n in modules)+'}))\n')
