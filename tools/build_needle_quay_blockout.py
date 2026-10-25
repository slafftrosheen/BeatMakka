"""Author the separate Needle Quay layout scene from its supplemental register.

Run from the repository root with Python's standard library. No provider calls,
asset uploads, gameplay migrations, or test execution. Native Part geometry is
intentionally a blockout, not accepted final architecture or imported meshes.
"""
from pathlib import Path
import hashlib
import json
import math
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / 'data/needle-quay-environment.v1.json').read_text(encoding='utf-8'))
OUT = ROOT / 'assets/blockouts/needle-quay'
OUT.mkdir(parents=True, exist_ok=True)
PALETTE = {'teal': (47,92,88), 'faded': (111,145,134), 'cream': (232,216,183),
           'coral': (202,116,83), 'amber': (243,182,95), 'walnut': (121,81,59),
           'stone': (183,156,126), 'graphite': (44,48,49), 'ink': (22,35,34)}
sequence = 0
parts = []


def prop(item, kind, name, value):
    p = item.find('Properties')
    e = ET.SubElement(p, kind, {'name': name})
    if kind in ('Vector3', 'Color3'):
        for key, number in zip(('X','Y','Z') if kind == 'Vector3' else ('R','G','B'), value):
            ET.SubElement(e, key).text = str(number)
    elif kind == 'CoordinateFrame':
        for key, number in zip(('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'), value):
            ET.SubElement(e, key).text = str(number)
    elif kind == 'UDim2':
        for key, number in zip(('XS','XO','YS','YO'),value):
            ET.SubElement(e,key).text=str(number)
    else:
        e.text = str(value).lower() if isinstance(value, bool) else str(value)
    return e


def item(parent, cls, name):
    global sequence
    sequence += 1
    obj = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'NQ{sequence}'})
    ET.SubElement(obj, 'Properties')
    prop(obj, 'string', 'Name', name)
    return obj


def value(parent, name, text):
    obj = item(parent, 'StringValue', name)
    prop(obj, 'string', 'Value', text)
    return obj


def part(parent, name, size, pos, color='stone', collide=True, transparency=0, yaw=0, cls='Part'):
    obj = item(parent, cls, name)
    prop(obj, 'Vector3', 'size', size)
    c,s = math.cos(yaw),math.sin(yaw)
    prop(obj, 'CoordinateFrame', 'CFrame', (*pos,c,0,s,0,1,0,-s,0,c))
    prop(obj, 'Color3', 'Color', [x/255 for x in PALETTE[color]])
    for n,v in [('Anchored',True),('CanCollide',collide),('CanTouch',False),('CanQuery',collide),('CastShadow',transparency<0.5)]:
        prop(obj,'bool',n,v)
    prop(obj,'float','Transparency',transparency)
    prop(obj,'token','TopSurface',0);prop(obj,'token','BottomSurface',0)
    prop(obj,'token','Material',256)  # SmoothPlastic: neutral blockout palette.
    parts.append({'name':name,'size':size,'position':pos,'collidable':collide})
    return obj


def label(anchor, text, width=300, height=60):
    gui = item(anchor,'BillboardGui','BlockoutLabel')
    prop(gui,'UDim2','Size',(0,width,0,height))
    prop(gui,'Vector3','StudsOffsetWorldSpace',(0,3,0))
    prop(gui,'float','MaxDistance',150)
    prop(gui,'bool','AlwaysOnTop',False)
    t=item(gui,'TextLabel','Caption')
    prop(t,'UDim2','Size',(1,0,1,0));prop(t,'float','BackgroundTransparency',0.2)
    prop(t,'Color3','BackgroundColor3',[x/255 for x in PALETTE['ink']])
    prop(t,'Color3','TextColor3',[x/255 for x in PALETTE['cream']])
    prop(t,'string','Text',text);prop(t,'float','TextSize',16);prop(t,'bool','TextWrapped',True)


def floor_marker(parent,name,x,z,text,color='amber'):
    p=part(parent,name,(2,0.15,2),(x,0.4,z),color,False)
    label(p,text,240,55)
    return p


def path(parent,name,a,b,width=8,color='cream'):
    dx,dz=b[0]-a[0],b[1]-a[1]
    length=math.hypot(dx,dz)
    return part(parent,name,(width,0.12,length),((a[0]+b[0])/2,0.12,(a[1]+b[1])/2),color,False,yaw=math.atan2(dx,dz))


xml=ET.Element('roblox',{'version':'4'})
model=item(xml,'Model','NeedleQuayEnvironmentBlockout')
value(model,'AcceptanceStage','BLOCKOUT CANDIDATE / art approval, DCC, Studio and runtime acceptance pending')
value(model,'SourceRegister','data/needle-quay-environment.v1.json')
value(model,'Scope','Separate district scene. Existing workshop and all player profiles remain in default.project.json.')
terrain=item(model,'Folder','GroundAndConnectedRoutes')
part(terrain,'QuayGround',(440,2,300),(0,-1,-5),'stone')
part(terrain,'WaterVisual_NoCollision',(620,0.5,140),(0,-3,215),'teal',False)
part(terrain,'TimberPier',(48,1,44),(-170,-0.5,132),'walnut')
part(terrain,'Breakwater',(70,1,36),(165,-0.5,128),'stone')
for z in (-140,-40,40):
    part(terrain,f'Street_Z{z}',(420,0.16,14),(0,0.08,z),'graphite',False)
    for x in range(-192,205,24):
        part(terrain,'StreetCenterDash',(6,0.02,0.3),(x,0.18,z),'cream',False)
for x in (-205,205,105):
    part(terrain,f'Connector_X{x}',(14,0.16,180),(x,0.08,-50),'graphite',False)
path(terrain,'RepairSideLane',(-158,-140),(-158,-40),8)
path(terrain,'ClubApproach',(0,40),(0,80),12)
path(terrain,'CafeApproach',(-65,40),(-65,82),8)
path(terrain,'FerryApproach',(-175,40),(-175,84),8)
path(terrain,'SignalApproach',(175,40),(175,87),8)
path(terrain,'RelayApproach',(140,40),(140,89),8)
path(terrain,'PierSideAccess',(-192,40),(-192,132),8,'walnut')
path(terrain,'PierCrossAccess',(-192,115),(-170,115),8,'walnut')
path(terrain,'BreakwaterSideAccess',(190,40),(190,130),8)
path(terrain,'BreakwaterCrossAccess',(190,130),(175,130),8)
for b in DATA['buildings']:
    x,z=b['blockout_center_xz_studs'];w,d,h=b['blockout_dimensions_wdh_studs']
    if z == -105:
        path(terrain,b['id']+'_FrontApproach',(x,-140),(x,z-d/2),8)
    elif z == 0:
        path(terrain,b['id']+'_FrontApproach',(x,-40),(x,z-d/2),8)

buildings=item(model,'Folder','Buildings_13')
for b in DATA['buildings']:
    obj=item(buildings,'Model',b['id']+'_'+b['name'].replace(' ','_'))
    x,z=b['blockout_center_xz_studs'];w,d,h=b['blockout_dimensions_wdh_studs']
    value(obj,'EnvironmentId',b['id']);value(obj,'ProposedDimensions_WDH',str(b['proposed_dimensions_wdh_studs']))
    value(obj,'BlockoutDimensions_WDH',str([w,d,h]));value(obj,'AccessContract',b['access'])
    value(obj,'QuestIds',','.join(b['quest_ids']));value(obj,'SignId',b['sign_id'])
    pivot=part(obj,'FloorCenterPivot',(0.2,0.2,0.2),(x,0,z),'cream',False,1)
    prop(obj,'Ref','PrimaryPart',pivot.attrib['referent'])
    if b.get('canonical_asset_id'):
        value(obj,'CanonicalAssetId',b['canonical_asset_id']);value(obj,'UnresolvedDimensionConflict',b['dimension_resolution'])
        value(obj,'CanonicalPivotContract',b['canonical_pivot'])
        part(obj,'CanonicalFrontLeftPivotMarker',(0.3,0.3,0.3),(x-w/2,0,z-d/2),'coral',False)
    body_color='faded' if b['tier']=='hero' else 'stone'
    part(obj,'Floor',(w,0.5,d),(x,0.25,z),'walnut')
    if b['id']=='NQ-BLD-04':
        for dx in (-w/2+1,w/2-1):
            for dz in (-d/2+1,d/2-1):
                part(obj,'CanopyColumn',(1,h-1,1),(x+dx,h/2,z+dz),'teal')
        for i,dx in enumerate((-18,-6,6,18),1):
            stall=item(obj,'Model',f'ModularStall_{i}')
            part(stall,'Counter',(8,3,4),(x+dx,1.75,z+7),'walnut')
            part(stall,'Awning',(9,0.5,5),(x+dx,7,z+7),'coral',False)
        part(obj,'SmallPerformancePlatform',(12,0.5,6),(x,0.75,z+11),'teal')
    elif b['id']=='NQ-BLD-05':
        part(obj,'RadioHouse',(w,12,d),(x,6.5,z),'faded')
        part(obj,'Mast',(1,h-13,1),(x,h/2+6.5,z),'graphite',False)
        part(obj,'AntennaCrossbar',(10,0.5,0.5),(x,h-2,z),'cream',False)
        part(obj,'AccessibleControlDesk',(5,3,2),(x+5,2,z-d/2-2),'teal')
    elif b['tier']=='hero':
        # Exact clear doorway, not a generated or invisible wall collision.
        side=(w-8)/2
        for sign in (-1,1):
            part(obj,'FrontWing',(side,h-1,1),(x+sign*(4+side/2),h/2,z-d/2+0.5),body_color)
        part(obj,'DoorHeader',(8,h-11,1),(x,(h+11)/2-0.5,z-d/2+0.5),'cream')
        part(obj,'RearWall',(w,h-1,1),(x,h/2,z+d/2-0.5),body_color)
        part(obj,'LeftWall',(1,h-1,d-2),(x-w/2+0.5,h/2,z),body_color)
        if b['id']=='NQ-BLD-01':
            # Right-side service opening: 6 studs clear with a ten-stud headroom.
            for sign in (-1,1):
                seg=(d-8)/2
                part(obj,'ServiceWallWing',(1,h-1,seg),(x+w/2-0.5,h/2,z+sign*(3+seg/2)),body_color)
            part(obj,'ServiceHeader',(1,h-11,6),(x+w/2-0.5,(h+11)/2-0.5,z),'cream')
            part(obj,'Stage_28x6',(28,1,6),(x,1,z+d/2-4),'teal')
            part(obj,'LobbyZone_40x6',(40,0.05,6),(x,0.53,z-11),'cream',False)
            part(obj,'HallZone_40x14',(40,0.05,14),(x,0.54,z-1),'stone',False)
            path(terrain,'ClubSideExit',(x+w/2,z),(x+w/2+10,z),8)
            path(terrain,'ClubSideToPromenade',(x+w/2+10,z),(x+w/2+10,40),8)
        else:
            part(obj,'RightWall',(1,h-1,d-2),(x+w/2-0.5,h/2,z),body_color)
        if b['id']=='NQ-BLD-02':
            for dx in (-10,10):
                part(obj,'VinylCounter',(5,3,3),(x+dx,2,z+3),'walnut')
            part(obj,'ListeningNook',(4,3,2),(x+11,2,z-3),'teal')
            for i in range(8):
                part(obj,'AwningStripe',(w/8,0.5,3),(x-w/2+(i+0.5)*w/8,11,z-d/2-1),'coral' if i%2 else 'cream',False)
        if b['id']=='NQ-BLD-03':
            part(obj,'WorkBench',(10,3,3),(x-8,2,z+7),'walnut')
            vent=part(obj,'P16_VentMechanismProxy',(3,3,2),(x+9,6,z-d/2-0.1),'graphite',False)
            value(vent,'CanonicalAssetId','P16')
            value(vent,'DiscoveryBinding','I02 / vent_thump')
    else:
        part(obj,'ClosedSupportingVolume',(w,h-1,d),(x,h/2,z),body_color)
    if b['id']!='NQ-BLD-05':
        part(obj,'Roof_RemoveForInteriorReview',(w,0.5,d),(x,h-0.25,z),'teal',False,0.45 if b['tier']=='hero' else 0)
    if b['id'] not in ('NQ-BLD-04','NQ-BLD-05'):
        for dx in (-w/3,w/3):
            part(obj,'WindowGraphicProxy',(w/5,5,0.15),(x+dx,6.5,z-d/2-0.12),'amber',False,0.35)
    sign=part(obj,b['sign_id'],(min(w-2,24),2,0.3),(x,min(h-3,14),z-d/2-0.3),'teal',False)
    label(sign,b['id']+' / '+b['name']+'\n'+str(w)+' × '+str(d)+' × '+str(h)+' studs')

parking=item(model,'Folder','Parking_4')
for s in DATA['stops']:
    obj=item(parking,'Model',s['id']+'_'+s['name'].replace(' ','_'))
    x,z=s['center_xz_studs']
    value(obj,'ParkingId',s['existing_parking_id']);value(obj,'EnvironmentStopId',s['id'])
    value(obj,'BuildingIds',','.join(s['building_ids']));value(obj,'SampleIds',','.join(s['sample_bindings']))
    part(obj,'Clearance_28x18',(28,0.1,18),(x,0.22,z),'cream',False,0.7)
    for dx in (-14,14):part(obj,'BayEdge',(0.3,0.08,18),(x+dx,0.3,z),'amber',False)
    for dz in (-9,9):part(obj,'BayEdge',(28,0.08,0.3),(x,0.3,z+dz),'amber',False)
    floor_marker(obj,'ParkingAnchor',x-12,z,s['existing_parking_id']+' / '+s['name'])
    path(terrain,s['id']+'_Route',(x,z),(x,40 if z>0 else -40),8)

van=item(model,'Model','LOOPVAN-01_StaticProxy')
value(van,'Stage','Static 22x9x10 envelope; no driving, teleport, ownership or studio interior implemented')
vx,vz=DATA['stops'][0]['center_xz_studs']
part(van,'VanBody',(22,8,9),(vx,6,vz),'teal')
part(van,'CabWindshield',(4,3,0.2),(vx+7,7,vz-4.55),'cream',False)
for dx in (-7,7):
    for dz in (-3.7,3.7):part(van,'WheelProxy',(3,3,1.2),(vx+dx,1.5,vz+dz),'graphite',False)
part(van,'FoldoutStage_SeparateTarget',(14,0.5,5),(vx,0.5,vz-7),'walnut')
part(van,'Awning_SeparateTarget',(16,0.3,5),(vx,9,vz-7),'coral',False)
floor_marker(van,'VanLocationLabel',vx,vz+6,'LOOPVAN-01 / static layout proxy')

markers=item(model,'Folder','NPC_And_Discovery_Locations')
npc_positions={'Tori':[-185,51],'Ivo':[-140,-125],'Naya':[-70,-16],'Sana Bell':[29,-23],'Mica':[187,82],'Ronan Wren':[-12,74],'Nell Fen':[-72,77]}
for npc in DATA['npcs']:
    x,z=npc_positions[npc['name']]
    obj=item(markers,'Model','NPC_Location_'+npc['name'].replace(' ','_'))
    value(obj,'Status','Location marker only, not authored NPC geometry/rig')
    if npc['canonical_asset_id']:value(obj,'CanonicalAssetId',npc['canonical_asset_id'])
    p=part(obj,'LocationTotem',(1.5,5,1.5),(x,2.5,z),'coral',False)
    label(p,npc['name']+'\nLOCATION ONLY',200,50)
for ident,name,x,z in [('I01','metal_hit',-185,112),('I02','vent_thump',-121,-120),('I03','robot_chirp',185,81)]:
    floor_marker(markers,ident,x,z,ident+' / '+name+'\nbinding location only')

spawn=part(model,'BlockoutSpawn',(6,0.5,6),(-193,0.5,49),'cream',True,cls='SpawnLocation')
prop(spawn,'bool','Neutral',True);prop(spawn,'float','Duration',0)
floor_marker(model,'ScopeNotice',-193,57,'NEEDLE QUAY / BLOCKOUT\nNo quest/runtime acceptance')

# Native light targets for later personal restoration, dormant in this scene.
lights=item(model,'Folder','RestorationTargets_Dormant')
for i,(x,z) in enumerate([(-170,78),(-130,-53),(-55,-53),(160,78),(0,74)],1):
    anchor=part(lights,f'RestorationLight_{i}',(1,1,1),(x,10,z),'amber',False)
    light=item(anchor,'PointLight','RestoredLight');prop(light,'bool','Enabled',False)
    prop(light,'float','Range',18);prop(light,'float','Brightness',1.5)
    prop(light,'Color3','Color',[x/255 for x in PALETTE['amber']])
    value(anchor,'Policy','Dormant preview target; personal client projection must be implemented separately')

ET.indent(xml)
dest=OUT/'NeedleQuayEnvironmentBlockout.rbxmx'
ET.ElementTree(xml).write(dest,encoding='utf-8',xml_declaration=True)
project={'name':'NeedleQuayEnvironmentBlockout','tree':{'$className':'DataModel','Workspace':{'$properties':{'StreamingEnabled':True},'NeedleQuayEnvironmentBlockout':{'$path':'assets/blockouts/needle-quay/NeedleQuayEnvironmentBlockout.rbxmx'}},'Lighting':{'$properties':{'ClockTime':16.5,'Brightness':2,'GlobalShadows':True}}}}
(ROOT/'needle-quay.blockout.project.json').write_text(json.dumps(project,indent=2)+'\n',encoding='utf-8')

# An editable top-down diagram uses exactly the same positions as the native model.
scale=2;ox=490;oy=355
def point(x,z):return ox+x*scale,oy+z*scale
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="980" height="760" viewBox="0 0 980 760">','<rect width="980" height="760" fill="#eee5d1"/>','<style>text{font-family:Arial,sans-serif;fill:#162322}.small{font-size:11px}.label{font-size:12px;font-weight:bold}</style>','<text x="40" y="40" font-size="25" font-weight="bold">NEEDLE QUAY / DISTRICT BLOCKOUT</text>','<text x="40" y="63" font-size="12">13 buildings · 4 parking anchors · 7 NPC locations · -Z is north · proposed layout, not runtime acceptance</text>']
for p in parts:
    if p['name'].startswith(('Street_Z','Connector_X','RepairSideLane')):
        x,y,z=p['position'];w,_,d=p['size'];sx,sy=point(x-w/2,z-d/2)
        svg.append(f'<rect x="{sx}" y="{sy}" width="{w*scale}" height="{d*scale}" fill="#b7a78d"/>')
for b in DATA['buildings']:
    x,z=b['blockout_center_xz_studs'];w,d,h=b['blockout_dimensions_wdh_studs'];sx,sy=point(x-w/2,z-d/2)
    fill='#6f9186' if b['tier']=='hero' else '#d2bda0'
    svg.append(f'<rect x="{sx}" y="{sy}" width="{w*scale}" height="{d*scale}" rx="3" fill="{fill}" stroke="#2f5c58"/>')
    svg.append(f'<text x="{sx+w}" y="{sy+d+4}" text-anchor="middle" class="label">{b["id"][-2:]}</text>')
    svg.append(f'<path d="M {sx+w-5} {sy} l 5 -6 l 5 6" fill="#ca7453"/>')
for s in DATA['stops']:
    x,z=s['center_xz_studs'];sx,sy=point(x-14,z-9)
    svg.append(f'<rect x="{sx}" y="{sy}" width="56" height="36" fill="none" stroke="#ca7453" stroke-width="2"/>')
    svg.append(f'<text x="{sx+28}" y="{sy+22}" text-anchor="middle" class="label">{s["existing_parking_id"]}</text>')
for name,(x,z) in npc_positions.items():
    sx,sy=point(x,z);svg.append(f'<circle cx="{sx}" cy="{sy}" r="3" fill="#ca7453"/>')
svg.append('<rect x="45" y="665" width="890" height="73" fill="#e8d8b7"/>')
for i,b in enumerate(DATA['buildings']):
    col=i//5;row=i%5;sx=55+col*295;sy=681+row*12
    svg.append(f'<text x="{sx}" y="{sy}" class="small">{b["id"][-2:]} {b["name"]} ({" × ".join(map(str,b["blockout_dimensions_wdh_studs"]))})</text>')
svg.append('</svg>')
(OUT/'district-plan.svg').write_text('\n'.join(svg),encoding='utf-8')
receipt={'kind':'DETERMINISTIC_AUTHORING_RECEIPT_NOT_TEST_OR_RUNTIME_EVIDENCE','register':'data/needle-quay-environment.v1.json','register_sha256':hashlib.sha256((ROOT/'data/needle-quay-environment.v1.json').read_bytes()).hexdigest(),'model':str(dest.relative_to(ROOT)).replace('\\','/'),'model_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'part_count':len(parts),'instance_count':sequence,'buildings':len(DATA['buildings']),'parking_anchors':len(DATA['stops']),'npc_location_markers':len(npc_positions),'canonical_H06_dimensions':[32,16,24],'studio_connection':'Not connected at authoring start; see docs/needle-quay/studio-delivery.json for actual delivery','runtime_quests_implemented':False,'tripo_calls':0,'tripo_credits_spent':0,'tests_run':False,'build_command':'rojo build needle-quay.blockout.project.json --output output/needle-quay/NeedleQuayEnvironmentBlockout-v1.rbxlx'}
(OUT/'authoring-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'model':receipt['model'],'parts':len(parts),'instances':sequence,'stage':'BLOCKOUT_CANDIDATE'}))
