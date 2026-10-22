"""Build explicit local-review requests and call the discovered Studio MCP schema.

Target the project review place only. Subcommands do not publish assets or a place.
"""
import argparse
import base64
import json
from pathlib import Path
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--studio-id", required=True)
parser.add_argument("operation", choices=["texture", "graphics", "mesh", "sources", "code", "tool"])
parser.add_argument("value")
parser.add_argument("--resolution", type=int, choices=[512, 1024], default=512)
parser.add_argument("--model", choices=["Edit", "Client", "Server"], default="Edit")
parser.add_argument("--output", type=Path)
args = parser.parse_args()
work = ROOT / "work/studio-requests"
work.mkdir(parents=True, exist_ok=True)
name = args.operation + "-" + Path(args.value).stem + "-" + str(args.resolution)
request_file = work / (name + ".json")
output = args.output or work / (name + "-result.json")


def lua_json(obj):
    raw = json.dumps(obj, separators=(",", ":"))
    assert "]==]" not in raw
    return "game:GetService('HttpService'):JSONDecode([==[" + raw + "]==])"


if args.operation == "texture":
    suffix = "_512" if args.resolution == 512 else ""
    path = ROOT / "assets/production/materials/sets" / args.value / ("atlas_basecolor" + suffix + ".png")
    image = Image.open(path).convert("RGBA")
    encoded = base64.b64encode(image.tobytes()).decode("ascii")
    layout = json.loads((ROOT / "assets/production/materials/layout.json").read_text())
    code = "local slots=" + lua_json(layout["slots"]) + "\n"
    code += f"local size={args.resolution}\nlocal finish={json.dumps(args.value)}\n"
    code += "local a=game:GetService('AssetService');local rs=game:GetService('ReplicatedStorage')\n"
    code += "local folder=rs:FindFirstChild('AppearanceLibrary') or Instance.new('Folder');folder.Name='AppearanceLibrary';folder.Parent=rs\n"
    code += "local name=finish..'_'..tostring(size);assert(not folder:FindFirstChild(name),'Template already exists')\n"
    code += "local color=a:CreateEditableImage({Size=Vector2.new(size,size)})\n"
    code += "local pixels=game:GetService('EncodingService'):Base64Decode(buffer.fromstring('" + encoded + "'))\n"
    code += "color:WritePixelsBuffer(Vector2.zero,Vector2.new(size,size),pixels)\n"
    code += "local rough=a:CreateEditableImage({Size=Vector2.new(size,size)});local metal=a:CreateEditableImage({Size=Vector2.new(size,size)})\n"
    code += "for i,s in slots do local p=Vector2.new(((i-1)%4)*size/4,math.floor((i-1)/4)*size/4);local span=Vector2.new(size/4,size/4);rough:DrawRectangle(p,span,Color3.new(s.roughness,s.roughness,s.roughness),0,Enum.ImageCombineType.Overwrite);metal:DrawRectangle(p,span,Color3.new(s.metalness,s.metalness,s.metalness),0,Enum.ImageCombineType.Overwrite) end\n"
    code += "local surface=a:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(color),RoughnessMap=Content.fromObject(rough),MetalnessMap=Content.fromObject(metal)})\n"
    code += "surface.Name=name;surface:SetAttribute('FinishSet',finish);surface:SetAttribute('LocalEditableReview',true);surface.Parent=folder;return name\n"
elif args.operation == "graphics":
    files = {"Icons": "G03_G04_icons.png", "Panel": "panel_9slice.png"}
    path = ROOT / "assets/production/graphics" / files[args.value]
    image = Image.open(path).convert("RGBA")
    encoded = base64.b64encode(image.tobytes()).decode("ascii")
    width, height = image.size
    code = f"local name={json.dumps(args.value)};local size=Vector2.new({width},{height})\n"
    code += "local image=game:GetService('AssetService'):CreateEditableImage({Size=size})\n"
    code += "image:WritePixelsBuffer(Vector2.zero,size,game:GetService('EncodingService'):Base64Decode(buffer.fromstring('" + encoded + "')))\n"
    code += "local rs=game:GetService('ReplicatedStorage');local folder=rs:FindFirstChild('UiImageLibrary') or Instance.new('Folder');folder.Name='UiImageLibrary';folder.Parent=rs\n"
    code += "assert(not folder:FindFirstChild(name),'Graphic already exists');local template=Instance.new('ImageLabel');template.Name=name;template.ImageContent=Content.fromObject(image);template:SetAttribute('LocalEditableReview',true);template.Parent=folder;return name\n"
elif args.operation == "mesh":
    payload = json.loads((ROOT / "work/studio-payloads" / (args.value + ".json")).read_text())
    code = (ROOT / "tools/studio_import_mesh.luau").read_text().replace("local payload = __PAYLOAD__", "local payload = " + lua_json(payload))
elif args.operation == "sources":
    mappings = [("src/shared", "ReplicatedStorage", "Shared", None),
                ("src/server", "ServerScriptService", "Server", "init.server.luau"),
                ("src/client", "StarterPlayer.StarterPlayerScripts", "Client", "init.client.luau")]
    records = []
    for directory, service, name_root, init in mappings:
        for path in sorted((ROOT / directory).glob("*.luau")):
            records.append({"service": service, "root": name_root, "name": name_root if path.name == init else path.stem,
                            "class": "Script" if path.name == "init.server.luau" else "LocalScript" if path.name == "init.client.luau" else "ModuleScript",
                            "isRoot": path.name == init, "source": path.read_text(encoding="utf-8")})
    code = "local records=" + lua_json(records) + "\n"
    code += "local roots={}\nfor _,r in records do local service=game;for segment in r.service:gmatch('[^.]+') do service=service:FindFirstChild(segment) or game:GetService(segment) end;local key=r.service..'.'..r.root;if not roots[key] then local root=service:FindFirstChild(r.root);if not root then root=Instance.new(if r.root=='Shared' then 'Folder' elseif r.root=='Server' then 'Script' else 'LocalScript');root.Name=r.root;root.Parent=service end;roots[key]=root end end\n"
    code += "for i,r in records do local root=roots[r.service..'.'..r.root];local obj=if r.isRoot then root else root:FindFirstChild(r.name);if not obj then obj=Instance.new(r.class);obj.Name=r.name;obj.Parent=root end;assert(obj.ClassName==r.class,'Unexpected source class');obj.Source=r.source;if i%6==0 then task.wait() end end\n"
    code += "return 'Installed '..tostring(#records)..' source scripts in the local review place'"
elif args.operation == "code":
    code = Path(args.value).read_text(encoding="utf-8")
else:
    request = json.loads(Path(args.value).read_text(encoding="utf-8"))
    request.setdefault("arguments", {})["studio_id"] = args.studio_id
if args.operation != "tool":
    request = {"name": "execute_luau", "arguments": {"studio_id": args.studio_id, "datamodel_type": args.model, "code": code}}
request_file.write_text(json.dumps(request), encoding="utf-8")
run = subprocess.run([sys.executable, str(ROOT / "tools/studio_mcp_bridge.py"), "--request", str(request_file),
                      "--output", str(output), "--timeout", "55"], cwd=ROOT)
if run.returncode:
    raise SystemExit(run.returncode)
result = json.loads(output.read_text())
if result.get("isError"):
    raise SystemExit("Studio tool reported an error. The saved result must be inspected; no automatic retry.")
