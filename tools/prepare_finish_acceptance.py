"""Installable opt-in two-client QA scripts; never added to the game build."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--cleanup', action='store_true')
args = parser.parse_args()
names = ['FinishAcceptanceServer', 'FinishAcceptanceClient', 'FinishArtQa', 'FinishArtData']
if args.cleanup:
    code = 'local count=0;for _,root in {game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts} do for _,name in '+json.dumps(names).replace('[', '{').replace(']', '}')+' do local item=root:FindFirstChild(name);if item then assert(item:GetAttribute("AcceptanceSuite")=="FinishAcceptance","Unowned QA script");item:Destroy();count+=1 end end end;return "Removed "..count.." explicit finish QA scripts"'
    out = ROOT/'work/finish-acceptance-cleanup.luau'
else:
    payload = json.loads((ROOT/'work/studio-payloads/H01.json').read_text())
    assert payload['sha256'] == hashlib.sha256((ROOT/'assets/optimized/H01/H01_atlas_v1.glb').read_bytes()).hexdigest() == '7f27ff7da218c44e19fba120ab3decda47f4cbd836db0eb38d94d0882dfa15e3'
    assert sum(len(p['triangles']) for p in payload['parts']) == 2088
    records = [
        {'name': names[0], 'class': 'Script', 'source': (ROOT/'tests/FinishMultiplayer.server.luau').read_text(), 'server': True},
        {'name': names[1], 'class': 'LocalScript', 'source': (ROOT/'tests/Multiplayer.client.luau').read_text()},
        {'name': names[2], 'class': 'ModuleScript', 'source': (ROOT/'tests/FinishArtQa.luau').read_text()},
        {'name': names[3], 'class': 'ModuleScript',
         'source': 'local pieces={};for i=1,3 do pieces[i]=script["Chunk"..i].Value end;return game.HttpService:JSONDecode(table.concat(pieces))',
         'chunks': [json.dumps(payload, separators=(',', ':'))[i:i+100000] for i in range(0, len(json.dumps(payload, separators=(',', ':'))), 100000)]},
    ]
    assert len(records[-1]['chunks']) == 3 and all(len(r['source']) < 200000 for r in records)
    code = 'local records=game.HttpService:JSONDecode([====['+json.dumps(records)+']====]);for _,r in records do local root=if r.server then game.ServerScriptService else game.StarterPlayer.StarterPlayerScripts;assert(not root:FindFirstChild(r.name),"QA script already exists") end;for _,r in records do local root=if r.server then game.ServerScriptService else game.StarterPlayer.StarterPlayerScripts;local item=Instance.new(r.class);item.Name=r.name;item.Source=r.source;item:SetAttribute("AcceptanceSuite","FinishAcceptance");for i,value in r.chunks or {} do local chunk=Instance.new("StringValue");chunk.Name="Chunk"..i;chunk.Value=value;chunk.Parent=item end;item.Parent=root end;return "Installed four explicit finish QA scripts"'
    out = ROOT/'work/finish-acceptance-install.luau'
out.write_text(code, encoding='utf-8')
print(out)
