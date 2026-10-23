"""Prepare opt-in Studio contract runners; never launch or modify Studio."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--model', choices=['Server','Client'], required=True)
args = parser.parse_args()
groups = {'Server':['ChapterConcert','NeighborhoodMissions','Contracts','Milestone','Rooms'],
          'Client':['ConcertUi','RecorderGuide','GrooveboxUi','RoomSettings']}
code = 'local result={}\n'
for name in groups[args.model]:
    source=(ROOT/'tests'/f'{name}.spec.luau').read_text(encoding='utf-8')
    code+='do local m=Instance.new("ModuleScript");m.Source='+json.dumps(source)+';m.Parent=game.ServerScriptService;local ok,value=pcall(function()return require(m)()end);m:Destroy();assert(ok,value);result['+json.dumps(name)+']=value end\n'
code+='return game.HttpService:JSONEncode(result)'
out=ROOT/'work'/f'concert-{args.model.lower()}-checks.luau'
out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(code,encoding='utf-8')
print(out)
