"""Prepare explicit Studio MCP install/cleanup requests, never game-build scripts."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--cleanup', action='store_true')
args = parser.parse_args()
names = ['RoomAcceptanceServer', 'RoomAcceptanceClient']
records = [
    {'name': names[0], 'class': 'Script', 'source': (ROOT/'tests/RoomsMultiplayer.server.luau').read_text(), 'server': True},
    {'name': names[1], 'class': 'LocalScript', 'source': (ROOT/'tests/Multiplayer.client.luau').read_text()},
]
if args.cleanup:
    code = 'local count=0;for _,root in {game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts} do for _,name in {"RoomAcceptanceServer","RoomAcceptanceClient"} do local item=root:FindFirstChild(name);if item then assert(item:GetAttribute("AcceptanceSuite")=="RoomAcceptance","Unowned QA script");item:Destroy();count+=1 end end end;return "Removed "..count.." room QA scripts"'
else:
    code = 'local records=game.HttpService:JSONDecode([====['+json.dumps(records)+']====]);for _,r in records do local root=if r.server then game.ServerScriptService else game.StarterPlayer.StarterPlayerScripts;assert(not root:FindFirstChild(r.name),"QA script already exists") end;for _,r in records do local root=if r.server then game.ServerScriptService else game.StarterPlayer.StarterPlayerScripts;local item=Instance.new(r.class);item.Name=r.name;item.Source=r.source;item:SetAttribute("AcceptanceSuite","RoomAcceptance");item.Parent=root end;return "Installed room QA server and client"'
out = ROOT/('work/room-acceptance-cleanup.luau' if args.cleanup else 'work/room-acceptance-install.luau')
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(code, encoding='utf-8')
print(out)
