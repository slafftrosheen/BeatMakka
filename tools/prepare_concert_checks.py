"""Prepare opt-in Studio contract runners; never launch or modify Studio."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--model', choices=['Server','Client'], required=True)
parser.add_argument('--touch', action='store_true', help='Also run real concert touch integration; requires phone simulation and a player near ChapterTarget')
args = parser.parse_args()
if args.touch and args.model != 'Client':
    parser.error('--touch requires --model Client')
groups = {'Server':['ChapterConcert','NeighborhoodMissions','Contracts','Milestone','Rooms','WorldEntry'],
          'Client':['ConcertUi','RecorderGuide','GrooveboxUi','RoomSettings']}
code = 'local result={}\n'
if args.touch:
    groups['Client'].append('ConcertTouch')
for name in groups[args.model]:
    filename = 'ConcertTouch.integration.luau' if name == 'ConcertTouch' else f'{name}.spec.luau'
    source=(ROOT/'tests'/filename).read_text(encoding='utf-8')
    code+='do local m=Instance.new("ModuleScript");m.Source='+json.dumps(source)+';m.Parent=game.ServerScriptService;local ok,value=pcall(function()return require(m)()end);m:Destroy();assert(ok,value);result['+json.dumps(name)+']=value end\n'
code+='return game.HttpService:JSONEncode(result)'
out=ROOT/'work'/f'concert-{args.model.lower()}-checks.luau'
out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(code,encoding='utf-8')
print(out)
