"""Build measured candidate contracts and a Russian visual handoff from local DCC output."""
from pathlib import Path
import hashlib,json,struct,io,textwrap,argparse
from PIL import Image,ImageDraw,ImageFont,ImageOps
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/production/needle-quay/companions'
manifest=json.loads((ASSETS/'model-manifest.json').read_text(encoding='utf-8'))
OUT=ROOT/'assets/concepts/companions';OUT.mkdir(parents=True,exist_ok=True)
parser=argparse.ArgumentParser()
parser.add_argument('--evidence-dir',default='docs/evidence/issue-20-companions')
parser.add_argument('--output',default='docs/BeatMakka_Companions_Artbook_v2_CANDIDATE_RU.pdf')
args=parser.parse_args()
EVIDENCE=ROOT/args.evidence_dir;EVIDENCE.mkdir(parents=True,exist_ok=True)
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
catalog_path=ROOT/'src/shared/CompanionModels.luau'
models=json.loads(catalog_path.read_text(encoding='utf-8').split('[=[')[1].split(']=]')[0])
content=ROOT/'assets/local-demo/content/needle-quay'
for model in models:
    slug=model['id'].removeprefix('NQ-CMP-').lower()
    files=set()
    for level in model['lods']:
        for part in level['parts']:
            source=content/part['uri'].removeprefix('rbxasset://needle-quay/')
            assert sha(source)==part['sha256']
            relative=f"companions/{slug}_lod{level['lod']}_{part['bone']}_{part['sha256'][:12]}.mesh"
            target=content/relative
            if not target.exists():target.write_bytes(source.read_bytes())
            assert sha(target)==part['sha256']
            part['uri']='rbxasset://needle-quay/'+relative;files.add(relative)
    model['parts']=model['lods'][0]['parts']
    source=content/model['atlas'].removeprefix('rbxasset://needle-quay/')
    relative=f"companions/{slug}_color_{sha(source)[:12]}.png"
    target=content/relative
    if not target.exists():target.write_bytes(source.read_bytes())
    assert sha(target)==sha(source)
    model['atlas']='rbxasset://needle-quay/'+relative;files.add(relative)
    next(item for item in manifest['characters']if item['id']==model['id'])['runtime_content_files']=sorted(files)
catalog_path.write_text('-- Generated original DCC candidates; art approval remains open.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(models,separators=(',',':'))+']=])\n',encoding='utf-8')
inspection=[]
for item in manifest['characters']:
    data=(ROOT/item['glb']).read_bytes()
    assert data[:4]==b'glTF' and struct.unpack_from('<I',data,4)[0]==2 and struct.unpack_from('<I',data,8)[0]==len(data)
    length=struct.unpack_from('<I',data,12)[0];document=json.loads(data[20:20+length]);bin_start=20+length+8
    images=[]
    for image in document.get('images',[]):
        view=document['bufferViews'][image['bufferView']];start=bin_start+view.get('byteOffset',0)
        with Image.open(io.BytesIO(data[start:start+view['byteLength']]))as picture:images.append(list(picture.size))
    actions=[action.get('name')for action in document.get('animations',[])]
    assert len(actions)==10 and all(name in actions for name in item['source_actions'])
    assert images==[[512,512]] and len(document['skins'][0]['joints'])==16
    assert all(value<=budget for value,budget in zip(item['lod_triangles'],[4500,2000,800]))
    assert sha(ROOT/item['source'])==item['source_sha256'] and sha(ROOT/item['glb'])==item['glb_sha256']
    triangles=sum(document['accessors'][primitive['indices']]['count']//3 for mesh in document['meshes']for primitive in mesh['primitives'])
    node_parents={child:index for index,node in enumerate(document['nodes'])for child in node.get('children',[])}
    item['rig_manifest']={'joints':[{'name':document['nodes'][index].get('name'),'parent':document['nodes'][node_parents[index]].get('name')if index in node_parents else None}for index in document['skins'][0]['joints']],'source_actions':actions,'runtime_binding':'rigid-part procedural counterpart; no uploaded animation IDs'}
    item['material_manifest']=[{'name':material.get('name'),'roughness_factor':material.get('pbrMetallicRoughness',{}).get('roughnessFactor',1),'metallic_factor':material.get('pbrMetallicRoughness',{}).get('metallicFactor',1),'base_color_image_size':images[0]}for material in document.get('materials',[])]
    slug=item['id'].removeprefix('NQ-CMP-').lower()
    item['local_lod_files']=['assets/local-demo/content/needle-quay/'+name for name in item['runtime_content_files']if name.endswith('.mesh')]
    inspection.append({'id':item['id'],'glb_version':2,'glb_triangles':triangles,'native_lod_triangles':item['lod_triangles'],'images':images,'skin_joints':len(document['skins'][0]['joints']),'animations':actions,'verified_sha256':True,'art_approved':False})
(ASSETS/'model-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
(EVIDENCE/'static-assets.json').write_text(json.dumps(inspection,indent=2)+'\n',encoding='utf-8')
contract={'schema':'needle-quay.companions.v1','issue':20,'base_sha':'8e8b91f6a5472eb6200599e60932e45a8c9ea56b','stage':'DCC_CANDIDATE_PENDING_ART_REVIEW','default':'none','choices':['none','alissia','nikolas'],'followers_per_client':1,'privacy':{'family_photographs_used':False,'biometric_data':False,'real_voice':False,'external_generation':False},'targets_are_authored_not_platform_limits':True,'targets':{'lod_triangles':[4500,2000,800],'atlas':[512,512],'bones':[15,17],'height_studs':[3.7,4.2]},'characters':manifest['characters'],'acceptance':{'art_approval':False,'phone':False,'multiplayer':False,'cloud_conflict':False,'full_solo_route_replay':False},'source_files':['src/shared/CompanionCatalog.luau','src/shared/CompanionProgress.luau','src/server/CompanionService.luau','src/client/CompanionView.luau','src/client/CompanionFollower.luau','src/client/CompanionAnimation.luau'],'notes':'Local prototype observations are recorded separately from asset-stage acceptance.'}
contract['supplied_reference_pack']='assets/references/companions/provided-pack-v1/provenance.json'
contract['privacy']['supplied_candidate_art_used']=True
contract['implementation_features']=['optional selection','graduated hints','read-only sound notebook','saved-beat observations','place conversations','static local 3D character card']
runtime=EVIDENCE/'runtime-summary.json'
if runtime.exists():contract['local_prototype_observations']=json.loads(runtime.read_text(encoding='utf-8'))
(ROOT/'data/companion-production.v1.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf-8')
INK='#162322';TEAL='#2F5C58';CREAM='#E8D8B7';PAPER='#F5EEDC';CORAL='#CA7453';AMBER='#F3B65F'
def font(size,bold=False):return ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf'if bold else'C:/Windows/Fonts/segoeui.ttf',size)
pages=[]
def page(title,subtitle):
    im=Image.new('RGB',(1800,1200),PAPER);d=ImageDraw.Draw(im)
    d.rectangle((0,0,1800,22),fill=TEAL);d.text((55,45),title,font=font(45,True),fill=INK);d.text((55,111),subtitle,font=font(24),fill=TEAL)
    d.line((55,1120,1745,1120),fill=TEAL,width=2);d.text((55,1140),'BEATMAKKA / NEEDLE QUAY / CANDIDATE / 26.10.2026',font=font(18),fill=TEAL)
    d.text((1680,1140),f'{len(pages)+1:02}',font=font(20,True),fill=TEAL);pages.append(im);return im,d
def paragraph(d,text,x,y,width=1600,size=28,color=INK):
    words=text.split();line=''
    for word in words:
        test=line+' '+word if line else word
        if d.textbbox((0,0),test,font=font(size))[2]>width:
            d.text((x,y),line,font=font(size),fill=color);y+=size+10;line=word
        else:line=test
    if line:d.text((x,y),line,font=font(size),fill=color);y+=size+10
    return y
def picture(im,path,box):
    with Image.open(path)as source:
        image=ImageOps.contain(source.convert('RGB'),(box[2]-box[0],box[3]-box[1]))
    im.paste(image,(box[0]+(box[2]-box[0]-image.width)//2,box[1]+(box[3]-box[1]-image.height)//2))
im,d=page('Алиссия и Николас / Услышать и собрать','Оригинальные игровые образы. Семейные фотографии и реальные голоса не используются.')
for i,item in enumerate(manifest['characters']):picture(im,ASSETS/item['id'].removeprefix('NQ-CMP-')/'isometric.png',(90+i*850,185,840+i*850,870))
paragraph(d,'Они помогают замечать и понимать. Бит создаёт, играет и сохраняет сам игрок. Выбор свободный: Alone, Алиссия или Николас. Один follower для прогулки; музыка и все задания доступны соло.',65,920,1670,29)
for item in manifest['characters']:
    slug=item['id'].removeprefix('NQ-CMP-');name='Алиссия / The Sound Collector'if slug=='ALISSIA'else'Николас / The Beat Builder'
    im,d=page(name,'MASTER TURNAROUND / ортографические виды / художественная приёмка открыта')
    for i,(view,label)in enumerate([('front','FRONT'),('side','SIDE'),('back','BACK'),('isometric','3/4')]):
        picture(im,ASSETS/slug/(view+'.png'),(55+i*435,190,465+i*435,780));d.text((65+i*435,790),label,font=font(24,True),fill=TEAL)
    values=['2F5C58','6F9186','E8D8B7','F5EEDC','F3B65F','CA7453','79513B','162322']
    for i,value in enumerate(values):d.rectangle((65+i*205,850,235+i*205,910),fill='#'+value);d.text((65+i*205,918),'#'+value,font=font(21),fill=INK)
    paragraph(d,f"{item['id']} / bounds W-D-H: "+' × '.join(f'{n:.3f}'for n in item['bounds_wdh_studs'])+' studs. LOD0/1/2: '+' / '.join(str(n)for n in item['lod_triangles'])+' tris. Один atlas 512×512, 16 костей. Целевые бюджеты авторские.',65,985,1660,26)
    im.save(OUT/(slug.lower()+'-master-CANDIDATE.png'))
im,d=page('Поза слушания, мысль и поддержка','EMOTE RIG CANDIDATE / отдельная лицевая анимация ещё не изготовлена')
for row,item in enumerate(manifest['characters']):
    slug=item['id'].removeprefix('NQ-CMP-')
    for i,clip in enumerate(['idle_listen','point','think','celebrate']):
        picture(im,ASSETS/slug/('emote_'+clip+'.png'),(55+i*435,180+row*440,465+i*435,575+row*440));d.text((70+i*435,575+row*440),slug+' / '+clip,font=font(20),fill=TEAL)
im.save(OUT/'emotes-CANDIDATE.png')
im,d=page('Читаемый силуэт и сделанные руками вещи','Физические аксессуары: каталог готовых звуков и механический счётчик. Без магии и live microphone.')
for i,item in enumerate(manifest['characters']):
    slug=item['id'].removeprefix('NQ-CMP-');folder=ASSETS/slug
    if(folder/'silhouette.png').exists():picture(im,folder/'silhouette.png',(55+i*860,185,445+i*860,970))
    if(folder/'props.png').exists():picture(im,folder/'props.png',(455+i*860,300,845+i*860,850))
im.save(OUT/'silhouettes-props-CANDIDATE.png')
im,d=page('Компаньоны в существующей игре','Read-only подсказки / собственная музыка игрока / отдельная серверная авторитетность')
y=190
for title,body in [('P1 / Тори','Четыре разных шага для Quay metal. Старый metal_pulse с двумя шагами остаётся отдельной legacy-веткой.'),('P2 / Иво','Сначала безопасная последовательность ремонта. Затем разные A/B и сохранённый Beat Shelf.'),('P3 / Naya и Sana','Сначала слушать запись, потом выбрать роль. Сохранить собственную композицию и освободить место для сцены.'),('P4 / Mica','Подсказка о равных долях становится точнее только по просьбе. Шаги 1/5/9/13 показываются на третьем уровне.'),('Lantern Room / Ronan','Поддержка перед шестью фазами концерта. Follower скрыт во время музыкальных интерфейсов и не меняет playback.')]:
    d.text((65,y),title,font=font(29,True),fill=TEAL);y=paragraph(d,body,65,y+48,1630,27)+24
reference=ROOT/'assets/references/companions/provided-pack-v1/art'
if reference.exists():
    for title,filename in [('Пакет пользователя / дизайн персонажей','Character_Turnarounds_CANDIDATE.png'),('Пакет пользователя / жизнь в Needle Quay','Character_World_Scenes_CANDIDATE.png')]:
        im,d=page(title,'SOURCE CONCEPT CANDIDATE / текстовая спецификация и approved style board остаются главными')
        picture(im,reference/filename,(55,170,1745,1100))
im,d=page('Блокнот, ритм и разговор','Необязательные страницы из серверного состояния. Новых наград и музыкальных команд нет.')
y=190
for body in ['Алиссия: три страницы с местом и тембром уже найденных I01/I02/I03. Ненайденный звук оставляет незаполненную страницу; микрофон не используется.','Николас: пульс, слои и разные ответы chirp из последнего успешного сохранения Beat Shelf. Несохранённый паттерн не выдаётся за сохранённый; наблюдение не завершает задания.','Разговор о месте связан с текущей валидной остановкой: Tori, Ivo, Naya/Sana, Mica или Ronan. Можно открыть две реплики, выбрать другую страницу или продолжить прогулку.','Карточка показывает локальную 3D-модель без отдельного animation clock. При закрытии освобождаются её модель и EditableImage. Один follower остаётся отдельным объектом.','Модели уточнены по кандидатному пакету: мягче объёмы ткани, крупнее голова, уже плечи, дополнительные ремни и карманы. Фотореалистичное сходство и лицевая анимация не заявляются.']:
    y=paragraph(d,body,65,y,1630,30)+33
captures=[('alissia-card.jpg','КАРТОЧКА / локальная 3D-модель'),('alissia-notebook.jpg','БЛОКНОТ / страницы и разговор'),('nikolas-beat-bench.jpg','РИТМ / сохранённое наблюдение')]
if all((EVIDENCE/name).exists()for name,_ in captures):
    im,d=page('Карточка и блокнот в Studio','Фактический desktop viewport / не приёмка телефона, multiplayer или cloud rejoin')
    for i,(filename,label)in enumerate(captures):
        picture(im,EVIDENCE/filename,(55+i*580,175,590+i*580,1030))
        d.text((60+i*580,1055),label,font=font(20,True),fill=TEAL)
im,d=page('Производственный статус и handoff','Кандидат не превращается в approved asset от наличия GLB или скриншота.')
y=190
for body in ['Сделано: отдельные Blender/GLB, реальные LOD0/1/2, atlas 512, 16 skin joints и 10 source actions. Хэши и измерения находятся в production manifest.','Добавлено в игру: Alone по умолчанию, выбор в журнале, три уровня серверных подсказок, session save, один локальный non-colliding follower и teardown.','Проверки кода и ограниченная Studio-инспекция записываются отдельно. Desktop viewport не считается phone acceptance.','Открыто: художественное согласование с Needle Quay, лицевая анимация, физические phone/gamepad проверки, multiplayer, cloud conflict и полный solo route replay.','См. docs/COMPANION_ARTBOOK_RU.md, docs/COMPANION_DEV_HANDOFF_RU.md и data/companion-production.v1.json. Исходные детские фотографии в проект не добавлялись.']:
    y=paragraph(d,body,65,y,1630,31)+35
output=ROOT/args.output
pages[0].save(output,'PDF',resolution=150,save_all=True,append_images=pages[1:])
print('Produced',len(pages),'Russian artbook pages; static assets verified; bytes',output.stat().st_size)
