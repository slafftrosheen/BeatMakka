import os;os.environ['OPENBLAS_NUM_THREADS']='1'
import json,hashlib
from pathlib import Path
from scipy.spatial import cKDTree
from audit_character_deformation import ROOT,data,decode,measure,np
from character_skin_weights import npc_weights
from optimize_skin_deformation import optimize
OUT=ROOT/'assets/production/needle-quay/skin-repair';OUT.mkdir(parents=True,exist_ok=True)
E=ROOT/'docs/evidence/needle-quay-skin-repair';E.mkdir(parents=True,exist_ok=True)
mp=ROOT/'assets/local-demo/mesh-manifest.json';manifest=json.loads(mp.read_text());receipts=[]
for a in manifest['assets']:
 if not a.get('skin'):continue
 original=OUT/(a['id']+'-original.json')
 if not original.exists():original.write_text(json.dumps(a))
 else:a0=json.loads(original.read_text());a['skin']=a0['skin']
 v,w,e,poses,names,refs,keys=data(a);before,_=measure(v,w,e,poses)
 ww=npc_weights(v,w,e,names)
 # Solve proportions inside the anatomical four-bone support against all poses.
 ww=optimize(v,ww,e,poses,iterations=100)
 after,_=measure(v,ww,e,poses)
 tree=cKDTree(v)
 for part,_ in refs:
  part['weights']=[[p,[[names[i],round(float(ww[j,i]),9)]for i in np.flatnonzero(ww[j]>1e-8)]]for p,_ in part['weights'] for j in [tree.query(np.array(p)+part['center'])[1]]]
  part['weightRevision']='anatomical-continuous-v2'
 rows=[[list(p),[[names[i],float(row[i])]for i in np.flatnonzero(row>1e-8)]]for p,row in zip(v,ww)]
 (OUT/(a['id']+'-weights.json')).write_text(json.dumps(rows,separators=(',',':')))
 receipts.append({'id':a['id'],'source':a['source'],'source_sha256':a['source_sha256'],'before':before,'after':after,'vertices':len(v),'max_influences':int((ww>1e-8).sum(axis=1).max()),'weight_sum_error':float(abs(ww.sum(axis=1)-1).max()),'art_approved':False})
 print(a['id'],json.dumps(after),flush=True)
mp.write_text(json.dumps(manifest,indent=2))
payload=json.dumps(manifest['assets'],separators=(',',':'));modules=[]
for i,start in enumerate(range(0,len(payload),140000),1):
 name='LocalMeshCatalogData'+str(i);modules.append(name);(ROOT/'src/shared'/(name+'.luau')).write_text('return [=['+payload[start:start+140000]+']=]\n')
(ROOT/'src/shared/LocalMeshCatalog.luau').write_text('return game:GetService("HttpService"):JSONDecode(table.concat({'+','.join('require(script.Parent.'+n+')'for n in modules)+'}))\n')
(E/'npc-deformation.json').write_text(json.dumps(receipts,indent=2))
