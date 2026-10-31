"""Bundle existing local music, graphics and materials; no upload or generation."""
from pathlib import Path
import json, shutil, hashlib
from active_content import AUTHORITY, active_audio, package_policy, preview_audio
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
audio={};previews={};materials={};sky={};characters=[];user_materials=[]
for p in (ROOT/'assets/production/needle-quay/commission-voices/clips').glob('*.wav'):
    copy(p.relative_to(ROOT).as_posix(),'commission-voices/'+p.name)
for p in (ROOT/'assets/production/needle-quay/guide-voices/clips').glob('*.wav'):
    copy(p.relative_to(ROOT).as_posix(),'guide-voices/'+p.name)
for p in (ROOT/'assets/production/needle-quay/ambience').glob('*.mp3'):
    copy(p.relative_to(ROOT).as_posix(),'ambience/'+p.name)
for p in (ROOT/'assets/production/needle-quay/reward-voices/clips').glob('*.wav'):
    copy(p.relative_to(ROOT).as_posix(),'reward-voices/'+p.name)
for p in (ROOT/'assets/production/needle-quay/voices').glob('*.wav'):
    copy(p.relative_to(ROOT).as_posix(),'voices/'+p.name)
for p in (ROOT/'assets/production/needle-quay/ui-hardware').glob('*.png'):
    copy(p.relative_to(ROOT).as_posix(),'ui/'+p.name)
for name in ('faceplate.png','pad.png','knob.png','journal.png','bezel-v4.png','softkey-v4.png','sleeve-v4.png'):
    p=ROOT/'assets/production/needle-quay/ui-device-v3'/name
    if p.is_file():
        copy(p.relative_to(ROOT).as_posix(),'ui-device-v3/'+name)
for identity,s in active_audio().items():
    audio[identity]=copy(s['file'],'audio/'+identity+'.wav')
for identity,s in preview_audio().items():
    previews[identity]=copy(s['file'],'preview-audio/'+identity+'.wav')
    provenance[-1].update({'purpose':'local_personal_preview','audio_approved':False,
                          'runtime_admitted':False,'listening_review':'pending',
                          'intake_provenance':s['source_provenance']})
for p in (ROOT/'assets/production/needle-quay/graphics').glob('*.png'):
    copy(str(p.relative_to(ROOT)).replace('\\','/'),'graphics/'+p.name)
for p in (ROOT/'assets/production/needle-quay/ui-mki').glob('*.png'):
    copy(p.relative_to(ROOT).as_posix(),'ui-mki/'+p.name)
for p in (ROOT/'assets/production/needle-quay/surface-tiles').glob('*.png'):
    digest=hashlib.sha256(p.read_bytes()).hexdigest()[:12]
    materials['env_'+p.stem]=copy(str(p.relative_to(ROOT)).replace('\\','/'),'materials/env_'+p.stem+'_'+digest+'.png')
for p in (ROOT/'assets/production/needle-quay/sky-artbook').glob('*.png'):
    if p.stem not in ('rt','lf','ft','bk','up','dn'):continue
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
 'game:GetService("HttpService"):JSONDecode([=['+json.dumps({'Audio':audio,'PreviewAudio':previews,'Materials':materials,'Sky':sky,'Characters':sorted(characters),'UserMaterials':user_materials},separators=(',',':'))+']=])\n',encoding='utf-8')
(ROOT/'assets/local-demo/content-provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
active={r['file'] for r in provenance}
replaced_ids=set()
for name in ('QuayArchitectureCatalog','QuayBuildingCatalog','QuayVanCatalog'):
    path=ROOT/'src/shared'/(name+'.luau')
    if path.exists():
        replaced_ids.update(a['id'] for a in json.loads(path.read_text().split('[=[')[1].split(']=]')[0]))
for a in json.loads((ROOT/'assets/local-demo/mesh-manifest.json').read_text())['assets']:
    if a['id'] in replaced_ids:continue
    active.update(p['uri'].removeprefix('rbxasset://needle-quay/') for p in a['parts'])
    if a.get('skin'):active.add(a['skin']['uri'].removeprefix('rbxasset://needle-quay/'))
# Resolve the active runtime catalogs, never a superseded candidate manifest.
for catalog_name in ('CompanionModels', 'QuayDressingCatalog', 'QuayBuildingCatalog', 'QuayVanCatalog', 'QuayLiftupCatalog', 'QuayArchitectureCatalog'):
    catalog_path=ROOT/'src/shared'/(catalog_name+'.luau')
    if not catalog_path.exists():continue
    catalog=json.loads(catalog_path.read_text(encoding='utf-8').split('[=[')[1].split(']=]')[0])
    for asset in catalog:
        paths={p['uri'].removeprefix('rbxasset://needle-quay/') for p in asset['parts']}
        if asset.get('atlas'):paths.add(asset['atlas'].removeprefix('rbxasset://needle-quay/'))
        for relative in sorted(paths):
            path=OUT/relative;active.add(relative)
            provenance.append({'source':asset['source'],'file':relative,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'art_stage':'LOCAL_ADAPTATION_PENDING_ACCEPTANCE'})
dressing_path=ROOT/'src/shared/QuayDressingMaterials.luau'
if dressing_path.exists():
    maps=json.loads(dressing_path.read_text().split('[=[')[1].split(']=]')[0])
    for uri in set(maps.values()):
        relative=uri.removeprefix('rbxasset://needle-quay/');active.add(relative)
        provenance.append({'source':'assets/production/needle-quay/dressing/manifest.json','file':relative,'sha256':hashlib.sha256((OUT/relative).read_bytes()).hexdigest()})
building_maps=ROOT/'src/shared/QuayBuildingMaterials.luau'
if building_maps.exists():
    for uri in json.loads(building_maps.read_text().split('[=[')[1].split(']=]')[0]).values():
        relative=uri.removeprefix('rbxasset://needle-quay/');active.add(relative)
        provenance.append({'source':'assets/production/needle-quay/models/supplied-buildings/manifest.json','file':relative,'sha256':hashlib.sha256((OUT/relative).read_bytes()).hexdigest()})
van_maps=ROOT/'src/shared/QuayVanMaterials.luau'
if van_maps.exists():
    for uri in json.loads(van_maps.read_text().split('[=[')[1].split(']=]')[0]).values():
        relative=uri.removeprefix('rbxasset://needle-quay/');active.add(relative)
        provenance.append({'source':'assets/production/needle-quay/models/supplied-van/manifest.json','file':relative,'sha256':hashlib.sha256((OUT/relative).read_bytes()).hexdigest()})
liftup_maps=ROOT/'src/shared/QuayLiftupMaterials.luau'
if liftup_maps.exists():
    for uri in set(json.loads(liftup_maps.read_text().split('[=[')[1].split(']=]')[0]).values()):
        relative=uri.removeprefix('rbxasset://needle-quay/');active.add(relative)
        provenance.append({'source':'assets/production/needle-quay/liftup/manifest.json','file':relative,'sha256':hashlib.sha256((OUT/relative).read_bytes()).hexdigest()})
from prepare_local_texture_budget import prepare
prepare(active, provenance)
(ROOT/'assets/local-demo/content-provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
files=[{'file':relative,'bytes':(OUT/relative).stat().st_size,'sha256':hashlib.sha256((OUT/relative).read_bytes()).hexdigest()} for relative in sorted(active)]
(ROOT/'assets/local-demo/install-manifest.json').write_text(json.dumps({'version':2,'namespace':'needle-quay','files':files,**package_policy()},indent=2),encoding='utf-8')
(ROOT/'assets/local-demo/active-content.json').write_bytes(AUTHORITY.read_bytes())
print('Packaged',len(files),'files;',len(audio),'admitted/nonmusical audio bindings;',len(previews),'local personal preview bindings')
