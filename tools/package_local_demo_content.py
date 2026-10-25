"""Bundle existing local music, graphics and materials; no upload or generation."""
from pathlib import Path
import json, shutil, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/local-demo/content/needle-quay'
provenance=[]
def copy(source, relative):
    dest=OUT/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/source,dest)
    provenance.append({'source':source,'file':relative,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
    return 'rbxasset://needle-quay/'+relative
audio={}
for s in json.loads((ROOT/'assets/production/audio/manifest.json').read_text())['samples']:
    audio[s['id']]=copy(s['file'],'audio/'+s['id']+'.wav')
for p in json.loads((ROOT/'assets/candidates/audio/style-starters-v1/manifest.json').read_text())['packs']:
    for s in p['samples']:audio[s['id']]=copy(s['file'],'audio/'+s['id']+'.wav')
for p in (ROOT/'assets/production/needle-quay/graphics').glob('*.png'):
    copy(str(p.relative_to(ROOT)).replace('\\','/'),'graphics/'+p.name)
for finish in ('quay','chalk','coral','afterhours'):
    for size in (512,1024):
        suffix='_512' if size==512 else ''
        maps={
          'ColorMap':copy(f'assets/production/materials/sets/{finish}/atlas_basecolor{suffix}.png',f'materials/{finish}_{size}.png'),
          'RoughnessMap':copy(f'assets/production/materials/shared/atlas_roughness{suffix}.png',f'materials/roughness_{size}.png'),
          'MetalnessMap':copy(f'assets/production/materials/shared/atlas_metalness{suffix}.png',f'materials/metalness_{size}.png')}
(ROOT/'src/shared/LocalContent.luau').write_text('-- Studio-only paths. Cloud IDs remain unchanged.\nreturn '+
 'game:GetService("HttpService"):JSONDecode([=['+json.dumps({'Audio':audio},separators=(',',':'))+']=])\n',encoding='utf-8')
(ROOT/'assets/local-demo/content-provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
files=[{'file':str(p.relative_to(OUT)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(OUT.rglob('*')) if p.is_file()]
(ROOT/'assets/local-demo/install-manifest.json').write_text(json.dumps({'version':1,'namespace':'needle-quay','files':files},indent=2),encoding='utf-8')
print('Packaged',len(files),'files;',len(audio),'audio bindings')
