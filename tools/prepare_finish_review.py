"""Prepare isolated Edit-mode Studio review code. No uploads or live bindings.

Execute the generated work/finish-review.luau through drive_studio.py code.
After captures, destroy Workspace.A01FinishCandidateReview and restore its saved
Lighting properties. screen_capture's camera arguments are temporary.
"""
import base64
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--cleanup', action='store_true')
args = parser.parse_args()
if args.cleanup:
    code = """local review=workspace:FindFirstChild('A01FinishCandidateReview')
if not review then return 'No candidate review to remove' end
assert(review:GetAttribute('SourceSHA256')=='7f27ff7da218c44e19fba120ab3decda47f4cbd836db0eb38d94d0882dfa15e3','Unrecognized review')
for _,p in {'Brightness','ClockTime','Ambient','OutdoorAmbient','ExposureCompensation'} do game.Lighting[p]=review:GetAttribute('Saved'..p) end
review:Destroy();return 'Candidate review removed; Lighting restored'"""
    (ROOT/'work/finish-review-cleanup.luau').write_text(code,encoding='utf-8')
    print('Prepared explicit cleanup code: work/finish-review-cleanup.luau')
    raise SystemExit(0)
maps = ROOT / 'assets/candidates/materials/tactile-v1'
payload = json.loads((ROOT/'work/studio-payloads/H01.json').read_text(encoding='utf-8'))
source_hash = hashlib.sha256((ROOT/'assets/optimized/H01/H01_atlas_v1.glb').read_bytes()).hexdigest()
assert payload['id'] == 'H01' and payload['sha256'] == source_hash == '7f27ff7da218c44e19fba120ab3decda47f4cbd836db0eb38d94d0882dfa15e3'
assert sum(len(p['triangles']) for p in payload['parts']) == 2088
images = {}
for finish in ['quay','chalk','coral','afterhours']:
    images[finish] = maps/'sets'/finish/'atlas_basecolor_512.png'
images.update({channel: maps/'shared'/f'atlas_{channel}_512.png' for channel in ['roughness','metalness']})
data = {'mesh': payload, 'images': {name: base64.b64encode(Image.open(path).convert('RGBA').tobytes()).decode() for name,path in images.items()}}
code = '''local data = game.HttpService:JSONDecode([==[__DATA__]==])
assert(not workspace:FindFirstChild('A01FinishCandidateReview'), 'Review already exists; preserve or clean it explicitly')
local service=game:GetService('AssetService')
local review=Instance.new('Model');review.Name='A01FinishCandidateReview'
review:SetAttribute('Stage','Candidate local EditableMesh review; no upload or acceptance')
review:SetAttribute('SourceSHA256',data.mesh.sha256)
local lighting=game:GetService('Lighting')
for _,p in {'Brightness','ClockTime','Ambient','OutdoorAmbient','ExposureCompensation'} do review:SetAttribute('Saved'..p,lighting[p]) end
review.Parent=workspace
lighting.Brightness=2;lighting.ClockTime=12;lighting.Ambient=Color3.new(.5,.5,.5);lighting.OutdoorAmbient=Color3.new(.5,.5,.5);lighting.ExposureCompensation=0
local images={}
for name,encoded in data.images do
    local image=service:CreateEditableImage({Size=Vector2.new(512,512)})
    assert(image,'Editable image allocation failed')
    image:WritePixelsBuffer(Vector2.zero,Vector2.new(512,512),game:GetService('EncodingService'):Base64Decode(buffer.fromstring(encoded)))
    images[name]=image;task.wait()
end
local surfaces={}
for _,finish in {'quay','chalk','coral','afterhours'} do
    surfaces[finish]=service:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(images[finish]),RoughnessMap=Content.fromObject(images.roughness),MetalnessMap=Content.fromObject(images.metalness)})
    task.wait()
end
local triangles=0
for _,part in data.mesh.parts do
    local editable=service:CreateEditableMesh();assert(editable,'Editable mesh allocation failed')
    local vertices,normals,uvs={},{},{}
    local low,high=Vector3.new(table.unpack(part.bounds_min)),Vector3.new(table.unpack(part.bounds_max));local center=(low+high)/2
    for i,p in part.positions do
        vertices[i]=editable:AddVertex(Vector3.new(table.unpack(p))-center)
        normals[i]=editable:AddNormal(Vector3.new(table.unpack(part.normals[i])))
        uvs[i]=editable:AddUV(Vector2.new(table.unpack(part.uvs[i])))
        if i%500==0 then task.wait() end
    end
    for i,face in part.triangles do
        local a,b,c=table.unpack(face);local f=editable:AddTriangle(vertices[a],vertices[b],vertices[c])
        editable:SetFaceNormals(f,{normals[a],normals[b],normals[c]});editable:SetFaceUVs(f,{uvs[a],uvs[b],uvs[c]})
        if i%500==0 then task.wait() end
    end
    local source=service:CreateMeshPartAsync(Content.fromObject(editable))
    source.Size=high-low;source.Anchored=true;source.CanCollide=false;source.CanTouch=false;source.CanQuery=false
    for i,finish in {'quay','chalk','coral','afterhours'} do
        local mesh=source:Clone();mesh.Name=finish;mesh.CFrame=CFrame.new(center+Vector3.new((i-1)*8,100,0));surfaces[finish]:Clone().Parent=mesh;mesh.Parent=review
    end
    source:Destroy();triangles+=#part.triangles;task.wait()
end
for _,surface in surfaces do surface:Destroy() end
return game.HttpService:JSONEncode({stage='Temporary candidate review only',finishes=4,trianglesPerFinish=triangles,resolution=512,sourceHash=data.mesh.sha256})
'''
path = ROOT/'work/finish-review.luau'
path.write_text(code.replace('__DATA__',json.dumps(data,separators=(',',':'))),encoding='utf-8')
print('Prepared isolated review code:', path)
