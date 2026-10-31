"""Measured clip envelopes for supplied meshes; preserves motion within safe range."""
from audit_character_deformation import np,frame,measure,decode,ROOT
from scipy.spatial.transform import Rotation

def scaled_poses(a,poses,gain):
 s=a.get('suppliedSkin') or a['skin'];names=s.get('order') or list(a['joints']);idx={n:i for i,n in enumerate(names)};parents=s['parents'];bind=np.array([frame(s['rest'][n]) if 'rest' in s else frame(a['joints'][n]+[0,0,0,1]) for n in names]);inv=np.linalg.inv(bind);result={}
 neutral=[frame(v) for v in decode(ROOT/"src/shared"/(s["clips"]["idle"]+".luau"))["samples"][0]] if "clips" in s else [np.eye(4)for _ in names]
 for label,samples in poses.items():
  result[label]=[]
  for transforms in samples:
   world=transforms@bind;local=[]
   for i,n in enumerate(names):
    p=parents[n];rest=inv[idx[p]]@bind[i] if p else bind[i];pose=np.linalg.inv(world[idx[p]])@world[i] if p else world[i];delta=np.linalg.inv(rest)@pose
    ref=neutral[i];delta[:3,:3]=ref[:3,:3]@Rotation.from_rotvec(Rotation.from_matrix(ref[:3,:3].T@delta[:3,:3]).as_rotvec()*gain).as_matrix();delta[:3,3]=ref[:3,3]+(delta[:3,3]-ref[:3,3])*gain;local.append(rest@delta)
   posed={}
   def rec(n):
    if n not in posed:posed[n]=rec(parents[n])@local[idx[n]] if parents[n] else local[idx[n]]
    return posed[n]
   result[label].append(np.array([rec(n)@inv[idx[n]]for n in names]))
 return result

def envelopes(a,v,w,e,poses,limit=1.85):
 gains={};final={}
 for name,samples in poses.items():
  one={name:samples};raw,_=measure(v,w,e,one)
  if raw[name]['max']<=limit:gains[name]=1.;final[name]=raw[name];continue
  lo,hi=0.,1.
  for _ in range(8):
   mid=(lo+hi)/2;r,_=measure(v,w,e,scaled_poses(a,one,mid))
   if r[name]['max']<=limit:lo=mid
   else:hi=mid
  gains[name]=round(lo,6);final[name]=measure(v,w,e,scaled_poses(a,one,gains[name]))[0][name]
 return gains,final
