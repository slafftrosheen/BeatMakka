"""Anatomical continuous fields for the authored Needle Quay R15 residents."""
import numpy as np

def smooth(a,b,x):
 t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)

def npc_weights(v,w,e,names):
 h=max(v[:,1]);y=v[:,1]/h;x=v[:,0]/h;out=np.zeros_like(w)
 arm=smooth(.12,.25,abs(x))*smooth(.32,.43,y)*(1-smooth(.73,.82,y))
 leg=1-smooth(.40,.51,y);head=smooth(.73,.82,y);upper=smooth(.51,.65,y)
 out[:,names.index('Head')]=(1-arm)*head
 out[:,names.index('UpperTorso')]=(1-arm)*(1-head)*(1-leg)*upper
 out[:,names.index('LowerTorso')]=(1-arm)*(1-head)*(1-leg)*(1-upper)
 for side,mask in [('Left',(x<0).astype(float)),('Right',(x>=0).astype(float))]:
  elbow=smooth(.53,.62,y);wrist=smooth(.42,.49,y);knee=smooth(.22,.31,y);ankle=smooth(.06,.12,y)
  for suffix,val in [('UpperArm',elbow),('LowerArm',(1-elbow)*wrist),('Hand',(1-elbow)*(1-wrist))]:out[:,names.index(side+suffix)]=arm*mask*val
  for suffix,val in [('UpperLeg',knee),('LowerLeg',(1-knee)*ankle),('Foot',(1-knee)*(1-ankle))]:out[:,names.index(side+suffix)]=(1-arm)*(1-head)*leg*mask*val
 # Topological smoothing crosses neither detached accessories nor empty space.
 for _ in range(6):
  accum=np.zeros_like(out);count=np.zeros(len(v));np.add.at(accum,e[:,0],out[e[:,1]]);np.add.at(accum,e[:,1],out[e[:,0]]);np.add.at(count,e[:,0],1);np.add.at(count,e[:,1],1)
  valid=count>0;out[valid]=.7*out[valid]+.3*accum[valid]/count[valid,None]
 for row in out:row[np.argsort(row)[:-4]]=0
 out/=out.sum(axis=1)[:,None]
 return out
