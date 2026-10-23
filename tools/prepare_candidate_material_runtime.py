"""Prepare a muted/no-input Studio Client material acceptance request.

Uses retained candidate bytes without uploading. The generated harness restores
the existing AppearanceLibrary and destroys all editable resources on failure.
"""
import base64
import json
from pathlib import Path

from PIL import Image

from build_assets_folder_finishes import DEST, verify

ROOT = Path(__file__).resolve().parents[1]
verify(DEST)
images = {f: DEST/'sets'/f/'atlas_basecolor_512.png' for f in ['quay', 'chalk', 'coral', 'afterhours']}
images.update({c: DEST/'shared'/f'atlas_{c}_512.png' for c in ['roughness', 'metalness']})
payload = {name: base64.b64encode(Image.open(path).convert('RGBA').tobytes()).decode() for name, path in images.items()}
tests = {name: (ROOT/'tests'/f'{name}.spec.luau').read_text() for name in ['MaterialCandidateRuntime', 'DeviceAppearance', 'AppearanceLoading']}
code = '''local images=game.HttpService:JSONDecode([==[__IMAGES__]==])
local tests=game.HttpService:JSONDecode([==[__TESTS__]==])
local storage=game.ReplicatedStorage
local original=storage:FindFirstChild('AppearanceLibrary')
if original then original.Parent=nil end
local library=Instance.new('Folder');library.Name='AppearanceLibrary';library.Parent=storage
local resources={}
local modules={}
local result={}
local ok,err=pcall(function()
    local maps={}
    for name,encoded in images do
        local image=game.AssetService:CreateEditableImage({Size=Vector2.new(512,512)})
        assert(image,'Candidate image allocation failed');table.insert(resources,image)
        image:WritePixelsBuffer(Vector2.zero,Vector2.new(512,512),game.EncodingService:Base64Decode(buffer.fromstring(encoded)))
        maps[name]=image;task.wait()
    end
    for _,finish in {'quay','chalk','coral','afterhours'} do
        local surface=game.AssetService:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(maps[finish]),RoughnessMap=Content.fromObject(maps.roughness),MetalnessMap=Content.fromObject(maps.metalness)})
        surface.Name=finish..'_512';surface:SetAttribute('Candidate','assets-folder-v1');surface.Parent=library
        task.wait()
    end
    for _,name in {'MaterialCandidateRuntime','DeviceAppearance','AppearanceLoading'} do
        local module=Instance.new('ModuleScript');module.Name=name..'Qa';module.Source=tests[name];table.insert(modules,module);module.Parent=game.Players.LocalPlayer.PlayerScripts
        result[name]=require(module)();task.wait()
    end
end)
for _,module in modules do module:Destroy() end
library:Destroy()
for _,resource in resources do resource:Destroy() end
if original then original.Parent=storage end
assert(ok,err)
result.editableResourcesDisposed=#resources;result.originalLibraryRestored=storage:FindFirstChild('AppearanceLibrary')==original
return game.HttpService:JSONEncode(result)
'''
out = ROOT/'work/candidate-material-runtime.luau'
out.write_text(code.replace('__IMAGES__', json.dumps(payload, separators=(',', ':'))).replace('__TESTS__', json.dumps(tests)), encoding='utf-8')
print(out)
