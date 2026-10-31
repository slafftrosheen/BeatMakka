import os;os.environ['OPENBLAS_NUM_THREADS']='1'
import json
from scipy.spatial import cKDTree
from audit_character_deformation import *
from optimize_skin_deformation import optimize
from character_motion_envelopes import envelopes
OUT=ROOT/'assets/production/needle-quay/skin-repair';E=ROOT/'docs/evidence/needle-quay-skin-repair';E.mkdir(parents=True,exist_ok=True)
p=ROOT/'src/shared/CompanionModels.luau';records=decode(p);reports=[]
for a in records:
 original=OUT/(a['id']+'-original.json')
 if not original.exists():original.write_text(json.dumps(a))
 else:
  old=json.loads(original.read_text());a['suppliedSkin']=old['suppliedSkin']
 v,w,e,poses,names,refs,keys=data(a);before,_=measure(v,w,e,poses)
 ww=optimize(v,w,e,poses,iterations=120)
 weightsOnly=measure(v,ww,e,poses)[0];gains,after=envelopes(a,v,ww,e,poses)
 tree=cKDTree(v)
 for part,_ in refs:
  part['weights']=[[p,[[names[i],round(float(ww[j,i]),9)]for i in np.flatnonzero(ww[j]>1e-8)]]for p,_ in part['weights']for j in [tree.query(np.array(p)+part['center'])[1]]]
 a['suppliedSkin']['motionGains']=gains;a['suppliedSkin']['weightRevision']='strain-reviewed-v2'
 (OUT/(a['id']+'-weights.json')).write_text(json.dumps([[list(p),[[names[i],float(row[i])]for i in np.flatnonzero(row>1e-8)]]for p,row in zip(v,ww)],separators=(',',':')))
 reports.append({'id':a['id'],'before':before,'weights_only':weightsOnly,'motion_gains':gains,'after':after,'vertices':len(v),'max_influences':int((ww>1e-8).sum(axis=1).max()),'weight_sum_error':float(abs(ww.sum(axis=1)-1).max()),'art_approved':False})
 print(a['id'],gains,after,flush=True)
p.write_text('-- Repaired local weights; authored source geometry and clips preserved.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(records,separators=(',',':'))+']=])\n')
(E/'companion-deformation.json').write_text(json.dumps(reports,indent=2))
