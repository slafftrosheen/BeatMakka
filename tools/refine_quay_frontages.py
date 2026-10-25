"""Refine canonical building envelopes from the supplied hero sheets.
Retains originals. Adds sloped scalloped awnings, substantial roof trim, repair
plates, hardware and side ladders to separate revision sources. No upload.
"""
import bpy,math,json,hashlib
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
D=json.loads((R/'data/needle-quay-environment.v1.json').read_text())
report=json.loads((R/'assets/production/needle-quay/models/model-manifest.json').read_text())
OUT=R/'assets/production/needle-quay/models/refined';OUT.mkdir(parents=True,exist_ok=True)
palette={'teal':(47,92,88),'cream':(232,216,183),'coral':(202,116,83),'walnut':(121,81,59),'graphite':(44,48,49),'brass':(160,125,69)}
records=[]
for b in D['buildings']:
    ident=b['id'];source=R/next(a['source'] for a in report['buildings'] if a['id']==ident)
    bpy.ops.wm.open_mainfile(filepath=str(source))
    w,d,h=b['blockout_dimensions_wdh_studs'];offset=Vector((w/2,d/2,0)) if ident=='NQ-BLD-02' else Vector((0,0,0))
    mats={}
    for name,rgb in palette.items():
        m=bpy.data.materials.new(name);m.diffuse_color=(*(v/255 for v in rgb),1);mats[name]=m
    def cube(name,size,at,color,bevel=.07):
        bpy.ops.mesh.primitive_cube_add(size=1,location=Vector(at)+offset);o=bpy.context.object;o.name=name;o.dimensions=size
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[color])
        if bevel:
            mod=o.modifiers.new('Soft manufactured edges','BEVEL');mod.width=bevel;mod.segments=3
            o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL')
        return o
    for side in (-1,1):
        cube('RoofRim',(w+.6,.8,.6),(0,side*(d/2-.15),h-.3),'cream',.12)
        cube('RoofReturn',(.8,d,.6),(side*(w/2-.15),0,h-.3),'cream',.12)
        for end in (-1,1):
            cube('ParapetCorner',(1.3,1.3,1.8),(side*(w/2-.55),end*(d/2-.55),h-1.1),'coral',.13)
            cube('IronRoofCap',(1.6,1.6,.2),(side*(w/2-.55),end*(d/2-.55),h-.1),'graphite',.06)
    if ident in ('NQ-BLD-02','NQ-BLD-06','NQ-BLD-07','NQ-BLD-08','NQ-BLD-11'):
        for side in (-1,1):
            cube('PaintedTealPier',(1.45,.38,h-2.2),(side*(w/2-1.35),-d/2-.25,(h-2.2)/2+.35),'teal',.12)
            cube('CreamPierCap',(1.7,.55,.6),(side*(w/2-1.35),-d/2-.3,h-1.8),'cream',.08)
        cube('PaintedTealFascia',(w-1.2,.35,1.1),(0,-d/2-.21,h-2.35),'teal',.08)
        for o in list(bpy.context.scene.objects):
            if o.type=='MESH' and o.name.startswith('AwningStripe'):bpy.data.objects.remove(o,do_unlink=True)
        width=w-2;count=12 if w>24 else 8;step=width/count;rear=min(11.8,h-2.2);front=rear-1.3
        for i in range(count):
            x=-width/2+(i+.5)*step;color='coral' if ident=='NQ-BLD-06' or i%2 else 'cream'
            o=cube('AwningSlopedStripe',(step-.015,4.6,.17),(x,-d/2-2.2,(front+rear)/2),color,.045)
            o.rotation_euler[0]=math.atan(1.3/4.6)
            # Rounded scalloped valance with a real thickness and generous silhouette.
            profile=[(-step/2,front),(step/2,front)]
            profile += [(step/2-step*j/12,front-.65-.35*math.sin(math.pi*j/12)) for j in range(13)]
            verts=[(x+px,-d/2-4.45+depth,pz) for depth in (0,.14) for px,pz in profile]
            n=len(profile);faces=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
            mesh=bpy.data.meshes.new('ScallopedCanvas');mesh.from_pydata(verts,[],faces);mesh.materials.append(mats[color]);obj=bpy.data.objects.new('AwningValance',mesh);bpy.context.collection.objects.link(obj);obj.location=offset
        for x in (-width/2,width/2):cube('AwningSupport',(.16,4.6,.16),(x,-d/2-2.2,front-.2),'graphite',.03)
    if ident not in ('NQ-BLD-04','NQ-BLD-05'):
        for y in (-2.6,-.8):cube('SideLadderRail',(.22,.22,h-2),(w/2+.5,y,h/2),'graphite',.05)
        for level in range(2,int(h-1),2):cube('SideLadderRung',(.24,2,.16),(w/2+.55,-1.7,level),'graphite',.04)
        for x in (-w*.38,w*.38):
            cube('FrontPanelStrap',(.28,.18,max(2,h-13)),(x,-d/2-.14,(h+11)/2),'cream',.04)
            for level in (12,h-2):cube('FastenerHead',(.22,.18,.22),(x,-d/2-.28,level),'brass',.07)
        cube('RepairPlate',(2.4,.13,1.6),(w*.27,-d/2-.15,h*.6),'teal',.08)
        for x in (-1,1):
            for z in (-.6,.6):cube('RepairRivet',(.16,.12,.16),(w*.27+x,-d/2-.28,h*.6+z),'brass',.05)
    dest=OUT/(ident+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(dest))
    records.append({'id':ident,'source':str(source.relative_to(R)).replace('\\','/'),'revision':str(dest.relative_to(R)).replace('\\','/'),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'status':'ARTBOOK_ALIGNMENT_IN_PROGRESS'})
(OUT/'manifest.json').write_text(json.dumps(records,indent=2))
