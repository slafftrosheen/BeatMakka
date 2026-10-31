import json,re,math
from pathlib import Path
import numpy as np
from scipy.spatial import cKDTree
ROOT=Path(__file__).resolve().parents[1]
def decode(p):return json.loads(p.read_text().split('[=[')[1].split(']=]')[0])
def frame(v):
 t=np.eye(4);x,y,z,w=v[3:];n=math.sqrt(x*x+y*y+z*z+w*w);x,y,z,w=x/n,y/n,z/n,w/n
 t[:3,:3]=[[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]];t[:3,3]=v[:3];return t
def rot(x,y=0,z=0):
 def r(i,a):
  m=np.eye(4);j,k=[x for x in range(3) if x!=i];c,s=math.cos(a),math.sin(a);m[j,j]=m[k,k]=c;m[j,k]=-s;m[k,j]=s;return m
 return r(0,x)@r(1,-y)@r(2,z)
def data(a, full=False):
 s=a.get('suppliedSkin') or a['skin'];parts=s.get('parts') or [s];order=s.get('order') or list(a['joints']);parents=s['parents'];idx={n:i for i,n in enumerate(order)}
 bind=np.array([frame(s['rest'][n]) if 'rest' in s else frame(a['joints'][n]+[0,0,0,1]) for n in order]);verts=[];weights=[];keys={};edges=set();refs=[]
 for part in parts:
  lookup={tuple(np.round(np.array(p)+part['center'],5)):w for p,w in part['weights']}
  for k,w in lookup.items():
   if k not in keys:
    keys[k]=len(verts);verts.append(k);weights.append([dict(w).get(n,0) for n in order])
  tree=cKDTree(np.array(list(keys)));keylist=list(keys)
  path=ROOT/'assets/local-demo/content/needle-quay'/part['uri'].split('needle-quay/')[1]
  for line in path.read_text().splitlines()[2:]:
   vs=re.findall(r'\[([^\]]+)\]',line);tri=[]
   for off in (0,3,6):
    pos=np.array([float(x) for x in vs[off].split(',')])+part['center'];k=tuple(np.round(pos,5))
    if k not in keys:k=keylist[tree.query(pos)[1]]
    tri.append(keys[k])
   for i,j in ((0,1),(1,2),(2,0)):edges.add(tuple(sorted((tri[i],tri[j]))))
  refs.append((part,lookup))
 poses={}
 if 'clips' in s:
  for name,mod in s['clips'].items():
   c=decode(ROOT/'src/shared'/f'{mod}.luau');poses[name]=[np.array([frame(v) for v in row]) for row in c['samples'][::(1 if full else max(1,len(c['samples'])//16))]]
 else:
  for name in ('walk','dance','cheer','greet'):
   poses[name]=[]
   for phase in np.linspace(0,2*math.pi,16):
    row=[]
    for n in order:
     side=1 if n.startswith('Left') else -1;m=np.eye(4)
     if name=='walk':
      if 'UpperLeg' in n:m=rot(math.sin(phase)*.23*side)
      elif 'LowerLeg' in n:m=rot(-max(0,-math.sin(phase)*side)*.25)
      elif 'UpperArm' in n:m=rot(-math.sin(phase)*.16*side)
     elif name=='dance':
      if n=='UpperTorso':m=rot(0,math.sin(phase/2)*.1,math.sin(phase)*.07)
      elif 'UpperArm' in n:m=rot(.45+math.sin(phase+side)*.2,0,side*.12)
      elif 'LowerArm' in n:m=rot(.7)
      elif 'UpperLeg' in n:m=rot(math.sin(phase)*side*.1)
     elif name=='cheer':
      if 'UpperArm' in n:m=rot(1,0,side*.2)
      elif 'LowerArm' in n:m=rot(.8+math.sin(phase)*.18)
     elif n=='RightUpperArm':m=rot(1.1,0,math.sin(phase)*.12)
     row.append(m)
    poses[name].append(np.array(row))
 inv=np.linalg.inv(bind);deforms={}
 for name,samples in poses.items():
  deforms[name]=[]
  for sample in samples:
   world={}
   def pose(n):
    if n in world:return world[n]
    i=idx[n];p=parents[n];world[n]=pose(p)@inv[idx[p]]@bind[i]@sample[i] if p else bind[i]@sample[i];return world[n]
   deforms[name].append(np.array([pose(n)@inv[idx[n]] for n in order]))
 return np.array(verts),np.array(weights),np.array(sorted(edges)),deforms,order,refs,keys

def measure(v,w,e,poses):
 rest=np.linalg.norm(v[e[:,0]]-v[e[:,1]],axis=1);valid=rest>.015;h=np.column_stack((v,np.ones(len(v))));results={};worst=np.zeros(len(e))
 for name,samples in poses.items():
  ratios=[]
  for transforms in samples:
   p=np.einsum('vb,bkj,vj->vk',w,transforms[:,:3,:],h,optimize=True)
   ratio=np.linalg.norm(p[e[:,0]]-p[e[:,1]],axis=1)/np.maximum(rest,1e-9);worst=np.maximum(worst,ratio);ratios.append(ratio[valid])
  r=np.concatenate(ratios);results[name]={'max':round(float(r.max()),3),'p99':round(float(np.quantile(r,.99)),3),'over2':int((r>2).sum())}
 return results,worst
if __name__=='__main__':
 assets=[x for x in json.loads((ROOT/'assets/local-demo/mesh-manifest.json').read_text())['assets'] if x.get('skin')]+decode(ROOT/'src/shared/CompanionModels.luau')
 for a in assets:
  v,w,e,poses,*_=data(a);r,_=measure(v,w,e,poses);print(a['id'],json.dumps(r),flush=True)
