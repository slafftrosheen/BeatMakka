import os;os.environ['OPENBLAS_NUM_THREADS']='1'
import sys;sys.path.insert(0,'tools')
from audit_character_deformation import *
def optimize(v,w,e,poses,iterations=120):
 # Keep each vertex on its authored four-bone neighborhood. Optimize only their
 # proportions against measured edge expansion in representative source poses.
 support=np.argsort(w,axis=1)[:,-4:];base=np.take_along_axis(w,support,axis=1);base/=base.sum(axis=1)[:,None];q=base.copy();h=np.column_stack((v,np.ones(len(v))))
 samples=[]
 for name,ps in poses.items():
  if name=='idle':continue
  samples.extend(ps)
 samples=np.array(samples);p=np.einsum('snkij,nj->snki',samples[:,support,:3,:],h,optimize=True).astype(np.float32)
 # Translation-invariant gradient reduces cancellation around mesh origins.
 p-=p[:,:,0:1,:]
 full=np.einsum('snij,nj->sni',samples[:,support[:,0],:3,:],h,optimize=True).astype(np.float32)
 rest=np.linalg.norm(v[e[:,0]]-v[e[:,1]],axis=1);target=np.maximum(rest*1.6,.008)
 edgeWeight=1/np.maximum(rest,.02)**2
 deg=np.bincount(e.flatten(),weights=np.r_[edgeWeight.repeat(2)],minlength=len(v));bound=np.max(np.sum(p*p,axis=3),axis=(0,2))*np.maximum(deg,1)*4+.05
 for it in range(iterations):
  pos=full+np.einsum('nk,snki->sni',q,p,optimize=True);delta=pos[:,e[:,0]]-pos[:,e[:,1]];length=np.linalg.norm(delta,axis=2);error=np.maximum(0,length-target);force=delta*(error*edgeWeight/np.maximum(length,1e-8))[:,:,None]
  grad=np.zeros_like(q)
  for si in range(len(samples)):
   f=np.column_stack([np.bincount(e[:,0],weights=force[si,:,axis],minlength=len(v))-np.bincount(e[:,1],weights=force[si,:,axis],minlength=len(v)) for axis in range(3)]);grad+=np.sum(p[si]*f[:,None,:],axis=2)/len(samples)
  grad+=.02*(q-base)
  q-=2*grad/bound[:,None]
  # Euclidean projection onto the probability simplex, maintaining nonnegative
  # normalized weights instead of normalizing signed descent values.
  u=np.sort(q,axis=1)[:,::-1];css=np.cumsum(u,axis=1)-1;condition=u-css/np.arange(1,5)>0;rho=condition.sum(axis=1)-1;theta=css[np.arange(len(v)),rho]/(rho+1);q=np.maximum(q-theta[:,None],0)
 out=np.zeros_like(w);np.put_along_axis(out,support,q,axis=1);return out
if __name__=='__main__':
 a=decode(ROOT/'src/shared/CompanionModels.luau')[0];v,w,e,poses,*_=data(a);ww=optimize(v,w,e,poses);print(measure(v,ww,e,poses)[0]);np.save('output/optimized-alissia.npy',ww)
