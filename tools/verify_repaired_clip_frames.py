import os;os.environ['OPENBLAS_NUM_THREADS']='1'
from audit_character_deformation import *
from character_motion_envelopes import scaled_poses
reports=[]
for a in decode(ROOT/'src/shared/CompanionModels.luau'):
 v,w,e,poses,*_=data(a,full=True);out={}
 for name,samples in poses.items():
  gain=a['suppliedSkin']['motionGains'][name];out[name]=measure(v,w,e,scaled_poses(a,{name:samples},gain))[0][name]
 reports.append({'id':a['id'],'sampled_frames':{n:len(p)for n,p in poses.items()},'results':out});print(a['id'],out,flush=True)
(ROOT/'docs/evidence/needle-quay-skin-repair/all-clip-frames.json').write_text(json.dumps(reports,indent=2))
