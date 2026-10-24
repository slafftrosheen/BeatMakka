"""Prepare an explicit three-client Studio suite; no launch or publication."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--cleanup", action="store_true")
args = parser.parse_args()
names = ["StageAcceptanceServer", "StageAcceptanceClient", "StageAcceptanceResult"]
if args.cleanup:
    code = 'local n=0;for _,root in {game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.ServerStorage} do for _,name in '+json.dumps(names).replace('[','{').replace(']','}')+' do local o=root:FindFirstChild(name);if o then assert(o:GetAttribute("AcceptanceSuite")=="StageAcceptance");o:Destroy();n+=1 end end end;return n'
else:
    records = [
        {"name": names[0], "class": "Script", "server": True, "source": (ROOT/"tests/StageMultiplayer.server.luau").read_text(encoding="utf-8")},
        {"name": names[1], "class": "LocalScript", "source": (ROOT/"tests/Multiplayer.client.luau").read_text(encoding="utf-8")},
    ]
    code = 'local records=game.HttpService:JSONDecode([====['+json.dumps(records)+']====]);for _,r in records do local root=if r.server then game.ServerScriptService else game.StarterPlayer.StarterPlayerScripts;assert(not root:FindFirstChild(r.name),"Existing QA driver") end;for _,r in records do local root=if r.server then game.ServerScriptService else game.StarterPlayer.StarterPlayerScripts;local o=Instance.new(r.class);o.Name=r.name;o.Source=r.source;o:SetAttribute("AcceptanceSuite","StageAcceptance");o.Parent=root end;return "Installed three-client stage QA drivers"'
out = ROOT/"work"/("stage-cleanup.luau" if args.cleanup else "stage-install.luau")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(code, encoding="utf-8")
print(out)
