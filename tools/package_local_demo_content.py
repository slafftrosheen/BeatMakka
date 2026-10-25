"""Bundle existing local music, graphics and materials; no upload or generation."""
from pathlib import Path
import json, shutil, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/local-demo/content/needle-quay'
provenance=[]
def copy(source, relative):
    dest=OUT/relative;dest.parent.mkdir(parents=True,exist_ok=True)
    payload=(ROOT/source).read_bytes();digest=hashlib.sha256(payload).hexdigest()
    if not dest.exists() or hashlib.sha256(dest.read_bytes()).hexdigest()!=digest:
        temporary=dest.with_name(dest.name+'.stage');temporary.write_bytes(payload);temporary.replace(dest)
    provenance.append({'source':source,'file':relative,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
    return 'rbxasset://needle-quay/'+relative
audio={};materials={};sky={};characters=[];user_materials=[]
for s in json.loads((ROOT/'assets/production/audio/manifest.json').read_text())['samples']:
    audio[s['id']]=copy(s['file'],'audio/'+s['id']+'.wav')
for p in json.loads((ROOT/'assets/candidates/audio/style-starters-v1/manifest.json').read_text())['packs']:
    for s in p['samples']:audio[s['id']]=copy(s['file'],'audio/'+s['id']+'.wav')
for p in (ROOT/'assets/production/needle-quay/graphics').glob('*.png'):
    copy(str(p.relative_to(ROOT)).replace('\\','/'),'graphics/'+p.name)
for p in (ROOT/'assets/production/needle-quay/surface-tiles').glob('*.png'):
    digest=hashlib.sha256(p.read_bytes()).hexdigest()[:12]
    materials['env_'+p.stem]=copy(str(p.relative_to(ROOT)).replace('\\','/'),'materials/env_'+p.stem+'_'+digest+'.png')
for p in (ROOT/'assets/production/needle-quay/sky').glob('*.png'):
    digest=hashlib.sha256(p.read_bytes()).hexdigest()[:12]
    sky[p.stem]=copy(str(p.relative_to(ROOT)).replace('\\','/'),'sky/'+p.stem+'_'+digest+'.png')
for p in (ROOT/'assets/production/needle-quay/character-maps').glob('*.png'):
    digest=hashlib.sha256(p.read_bytes()).hexdigest()[:12]
    materials['character_'+p.stem]=copy(str(p.relative_to(ROOT)).replace('\\','/'),'materials/character_'+p.stem+'_'+digest+'.png')
    if p.stem.endswith('_color'):characters.append(p.stem.removesuffix('_color'))
user_source=ROOT/'assets/production/needle-quay/models/user-adapted/manifest.json'
if user_source.exists():
    used_images={}
    for key,maps in json.loads(user_source.read_text())['materials'].items():
        user_materials.append(key)
        for channel,source in maps.items():
            p=ROOT/source;digest=hashlib.sha256(p.read_bytes()).hexdigest()
            if digest not in used_images:used_images[digest]=copy(source,'materials/'+key+'_'+channel+'_'+digest[:12]+'.png')
            materials[key+'_'+channel]=used_images[digest]
for finish in ('quay','chalk','coral','afterhours'):
    for size in (512,1024):
        suffix='_512' if size==512 else ''
        maps={
          'ColorMap':copy(f'assets/production/materials/sets/{finish}/atlas_basecolor{suffix}.png',f'materials/{finish}_{size}.png'),
          'RoughnessMap':copy(f'assets/production/materials/shared/atlas_roughness{suffix}.png',f'materials/roughness_{size}.png'),
          'MetalnessMap':copy(f'assets/production/materials/shared/atlas_metalness{suffix}.png',f'materials/metalness_{size}.png')}
(ROOT/'src/shared/LocalContent.luau').write_text('-- Studio-only paths. Cloud IDs remain unchanged.\nreturn '+
 'game:GetService("HttpService"):JSONDecode([=['+json.dumps({'Audio':audio,'Materials':materials,'Sky':sky,'Characters':sorted(characters),'UserMaterials':user_materials},separators=(',',':'))+']=])\n',encoding='utf-8')
(ROOT/'assets/local-demo/content-provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
active={r['file'] for r in provenance}
for a in json.loads((ROOT/'assets/local-demo/mesh-manifest.json').read_text())['assets']:
    active.update(p['uri'].removeprefix('rbxasset://needle-quay/') for p in a['parts'])
    if a.get('skin'):active.add(a['skin']['uri'].removeprefix('rbxasset://needle-quay/'))
files=[{'file':relative,'bytes':(OUT/relative).stat().st_size,'sha256':hashlib.sha256((OUT/relative).read_bytes()).hexdigest()} for relative in sorted(active)]
(ROOT/'assets/local-demo/install-manifest.json').write_text(json.dumps({'version':1,'namespace':'needle-quay','files':files},indent=2),encoding='utf-8')
print('Packaged',len(files),'files;',len(audio),'audio bindings')
