#!/usr/bin/env python3
"""Rebuild the Russian companion artbook from local candidate renders and the authored specification.
Only writes the PDF. No project/repo/network mutations.
"""
from pathlib import Path
import io
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader
from reportlab.lib.colors import HexColor, Color

ROOT=Path(__file__).resolve().parent.parent
OUTPUT=ROOT/'BeatMakka_Companions_Artbook_RU.pdf'
W,H=1280,720
FONT=next(p for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','C:/Windows/Fonts/arial.ttf'] if Path(p).exists())
BOLD=next(p for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf','C:/Windows/Fonts/arialbd.ttf'] if Path(p).exists())
pdfmetrics.registerFont(TTFont('DejaVu', FONT))
pdfmetrics.registerFont(TTFont('DejaVu-Bold', BOLD))
C={k:HexColor(v) for k,v in {
  'paper':'#F5EEDC','cream':'#E8D8B7','ink':'#162322','teal':'#2F5C58','faded':'#6F9186',
  'amber':'#F3B65F','coral':'#CA7453','walnut':'#79513B','white':'#FCFAF2','line':'#D5C9B4',
  'muted':'#5B6B65'}.items()}
img1=Image.open(ROOT/'art/Character_Turnarounds_CANDIDATE.png').convert('RGB')
img2=Image.open(ROOT/'art/Character_World_Scenes_CANDIDATE.png').convert('RGB')
c=canvas.Canvas(str(OUTPUT), pagesize=(W,H), pageCompression=1)
c.setTitle('BeatMakka — Алиссия и Николас / артбук компаньонов v1.0')
c.setAuthor('BeatMakka design handoff')
page=0

def bg():
    c.setFillColor(C['paper']); c.rect(0,0,W,H,stroke=0,fill=1)

def rr(x,y,w,h,fill='white',radius=18,stroke=None):
    c.setFillColor(C[fill]); c.setStrokeColor(C[stroke or fill]); c.roundRect(x,y,w,h,radius,stroke=int(stroke is not None),fill=1)

def txt(s,x,y,size=17,bold=False,color='ink'):
    c.setFillColor(C[color]); c.setFont('DejaVu-Bold' if bold else 'DejaVu', size)
    c.drawString(x,y,s)

def split_by_width(text,width,size,bold=False):
    font='DejaVu-Bold' if bold else 'DejaVu'
    result=[]
    for paragraph in str(text).split('\n'):
        if not paragraph:
            result.append('');continue
        line=''
        for word in paragraph.split(' '):
            attempt=word if not line else line+' '+word
            if pdfmetrics.stringWidth(attempt,font,size)>width and line:
                result.append(line);line=word
            else: line=attempt
        result.append(line)
    return result

def block(text,x,y,width,size=16,line=23,color='ink',max_lines=None,bold=False):
    lines=split_by_width(text,width,size,bold)
    if max_lines and len(lines)>max_lines:lines=lines[:max_lines-1]+[lines[max_lines-1]+'…']
    for row in lines:
        txt(row,x,y,size,bold,color);y-=line
    return y

def image_cover(im,x,y,w,h,box=None):
    # crop to fill slot without stretching characters
    crop=im if box is None else im.crop(box)
    ow,oh=crop.size
    ratio=max(w/ow,h/oh)
    nw,nh=round(w/ratio),round(h/ratio)
    left=(ow-nw)//2;top=(oh-nh)//2
    crop=crop.crop((left,top,left+nw,top+nh))
    c.drawImage(ImageReader(crop),x,y,width=w,height=h)

def img_contain(im,x,y,w,h):
    ow,oh=im.size; ratio=min(w/ow,h/oh)
    nw,nh=ow*ratio,oh*ratio
    c.drawImage(ImageReader(im),x+(w-nw)/2,y+(h-nh)/2,width=nw,height=nh)

def divider(y=100):
    c.setStrokeColor(C['line']);c.setLineWidth(1);c.line(48,y,1230,y)

def start(section,title,sub=None):
    global page
    page+=1;bg()
    c.setFillColor(C['teal']);c.rect(0,H-12,W,12,fill=1,stroke=0)
    txt('BEATMAKKA  /  FREQUENCY ZERO',44,H-47,14,True,'teal')
    txt(section.upper(),1045,H-47,13,True,'coral')
    txt(title,44,H-104,34,True,'ink')
    if sub:block(sub,46,H-135,1150,14,20,'muted')

def end():
    c.setStrokeColor(C['line']);c.line(44,33,1236,33)
    txt('CHARACTER ARTBOOK  ·  CONCEPT CANDIDATE  ·  25.10.2026',44,15,11,False,'muted')
    c.setFont('DejaVu-Bold',12);c.setFillColor(C['teal']);c.drawRightString(1235,14,f'{page:02}')
    c.showPage()

# 01 Cover
page+=1;bg()
image_cover(img2,0,230,W,490,(0,0,1536,760))
c.setFillColor(Color(0.07,0.12,0.11,alpha=.88));c.rect(0,0,W,248,stroke=0,fill=1)
txt('BEATMAKKA / FREQUENCY ZERO',52,200,24,True,'amber')
txt('АЛИССИЯ И НИКОЛАС',52,137,48,True,'white')
txt('Компаньоны, которые помогают услышать музыку города — и построить свой бит.',52,97,21,False,'cream')
txt('АРТБУК + ИНТЕГРАЦИЯ  /  v1.0',52,48,16,True,'amber')
txt('КОНЦЕПТ  ·  НЕ ФИНАЛЬНЫЙ RIG  ·  НЕ ОПУБЛИКОВАНО',784,48,12,True,'cream')
c.showPage()

# 02 Identity
start('ART DIRECTION','Не сказка, а тёплая музыкальная набережная','Реальная визуальная основа: Needle Quay и готовые дизайн-кандидаты Tori, Ivo, Naya, Sana, Ronan, Nell.')
rr(44,136,738,395,'white')
img_contain(img1.crop((0,0,1536,740)),57,179,711,342)
rr(804,136,432,395,'white')
txt('ОБЯЗАТЕЛЬНЫЕ ПРАВИЛА',828,498,19,True,'teal')
y=460
for hd,desc in [('Силуэт','Крупные простые формы, лёгкие скругления, читаемость с 10–15 studs.'),('Материалы','Выцветший хлопок, матовая краска, мягкая резина, небольшие рабочие детали.'),('Цвет','Teal + cream + walnut; coral у Алиссии, amber у Николаса.'),('Запреты','Никаких магических аур, HDR-гламура, неоновых миров и фототекстур лиц.')]:
  txt(hd,828,y,16,True,'ink');y=block(desc,828,y-20,380,14,19,'muted')-18
end()

# 03 colors
start('MATERIAL & PALETTE','Палитра мира и двух персонажей','Не плодить отдельные цветовые системы: ориентир — утверждённая палитра игры.')
names=['paper','cream','ink','teal','faded','amber','coral','walnut']
hexc=['#F5EEDC','#E8D8B7','#162322','#2F5C58','#6F9186','#F3B65F','#CA7453','#79513B']
for i,(n,h) in enumerate(zip(names,hexc)):
    x=55+i*151
    rr(x,366,132,156,'white',9)
    c.setFillColor(C[n]);c.roundRect(x+9,398,114,110,7,stroke=0,fill=1)
    txt(n.upper(),x+9,376,13,True,'ink')
    txt(h,x+9,351,12,False,'muted')
rr(50,124,1180,194,'white')
txt('МАТЕРИАЛЬНЫЙ КОНТРАКТ',71,279,20,True,'teal')
block('Стиль — дружелюбная ретрофутуристика и тактильные поверхности: кремовая эмаль, крашеный металл, деревянные ящики для винила и износ кроссовок. Детали одежды читаются даже при низком LOD. Очки Алиссии и ременной ритм-счётчик Николаса создают силуэт без фантастических устройств.',70,239,1110,17,26)
end()

# 04 Alissia
start('CHARACTER / 01','Алиссия — The Sound Collector','Замечает то, мимо чего проходят другие; помогает игроку понять, что даже простой звук может стать музыкой.')
rr(44,95,623,445,'white')
image_cover(img1,54,112,603,411,(0,0,770,725))
rr(690,95,544,445,'white')
txt('ОБРАЗ',716,498,19,True,'coral')
y=461
y=block('Розовые очки на голове, свободная потёртая teal куртка, широкие джинсы, небольшой полевой звуковой прибор, удобные кроссовки.',714,y,485,17,26)-18
txt('РОЛЬ В ИГРЕ',714,y,19,True,'teal');y-=35
y=block('I01 metal_hit  →  I02 vent_thump  →  I03 robot_chirp. Подсказывает, где искать звуки, и помогает их услышать. Все находки собирает игрок через существующие серверные проверки.',714,y,485,16,25)-22
txt('ХАРАКТЕР',714,y,18,True,'teal');y-=30
block('Внимательная, добрая, немного мечтательная, никогда не оценивает качество чужой музыки. Её вопрос: «Что ты сейчас услышал?»',714,y,490,16,23)
end()

# 05 Nikolas
start('CHARACTER / 02','Николас — The Beat Builder','Не нажимает кнопки за игрока, а показывает, как из простой идеи сделать собственный работающий ритм.')
rr(44,95,623,445,'white')
image_cover(img1,54,112,603,411,(765,0,1536,725))
rr(690,95,544,445,'white')
txt('ОБРАЗ',716,498,19,True,'amber')
y=461
y=block('Короткие русые волосы, светлая футболка, тёплый teal utility vest, тёмные шорты, chunky обувь и маленький янтарный счётчик ритма.',714,y,485,17,26)-18
txt('РОЛЬ В ИГРЕ',714,y,19,True,'teal');y-=35
y=block('Помогает понять задания metal_pulse, vent_duet и helper_reply: два разных шага, слои metal+vent, два отличающихся chirp-паттерна. Награды подтверждает только сервер после сохранения.',714,y,485,16,25)-22
txt('ХАРАКТЕР',714,y,18,True,'teal');y-=30
block('Неугомонный, любопытный, умеет собирать простые вещи и радоваться попыткам. Его вопрос: «А если изменить вот этот шаг?»',714,y,490,16,23)
end()

# 06 lore
start('LORE','Услышать. Собрать. Поделиться.','У каждого свой талант, но главное действие всегда принадлежит игроку: создавать музыку на MK-I.')
rr(45,140,1190,401,'white')
image_cover(img2,59,273,563,254,(0,550,950,1024))
txt('THE QUIET FADE',657,499,21,True,'teal')
y=457
y=block('Старая причальная улица стала молчаливой: соседи разучились творить музыку вместе. Алиссия ищет интересные звуки в мире вокруг. Николас собирает из них первые ритмические идеи. Mica знакомит их с игроком и настоящей музыкальной мастерской.',657,y,548,18,29)-15
y=block('Вместо магии, суперсил и злодея — реальные находки, решения соседских проблем, уважение к тишине и маленькие концерты, на которые люди приходят добровольно.',657,y,548,17,26)
end()

# 07 locations
start('WORLD / NEEDLE QUAY','Драматургия первой зоны','Новые персонажи встраиваются в существующие места, ID открытий и NPC. Названия площадок не равны готовым runtime-квестам.')
rows=[
 ('PROLOGUE','Mica / LOOPVAN','Знакомство, добровольный выбор спутника.'),
 ('P1  DOCKSIDE EXCHANGE','Tori / I01','Алиссия слышит metal; Николас подсказывает два разных шага.'),
 ('P2  REPAIR ALLEY','Ivo / I02','Сравнение тембра metal и vent; игрок сохраняет layered beat.'),
 ('P3  VINYL MARKET','Naya / Sana','Истории винила, подсказка о сохранении на Beat Shelf.'),
 ('P4  BREAKWATER STEPS','Mica / I03','Ответ робота; два разных chirp rhythms.'),
 ('FINALE  LANTERN ROOM','Ronan Wren','Игрок добровольно исполняет свой saved loop.'),
]
for i,(name,who,desc) in enumerate(rows):
    y=548-i*72
    rr(46,y-53,1187,65,'white',10)
    c.setFillColor(C['coral'] if i%2==0 else C['amber']);c.roundRect(54,y-44,9,47,3,fill=1,stroke=0)
    txt(name,79,y-4,16,True,'teal')
    txt(who,79,y-30,14,False,'muted')
    block(desc,528,y-8,674,15,21)
end()

# 08 gameplay system
start('GAMEPLAY / AUTHORITY','Спутники — помощь, не способ обойти прогресс','Нет новой системы reward. Подсказки — функция от уже проверенных событий в серверном MusicService.')
for i,(n,hd,body,color) in enumerate([
    ('01','PLAYER ACTION','Игрок сам собирает I01/I02/I03, ставит шаги, сохраняет beat и выбирает концерт.','teal'),
    ('02','SERVER PROOF','Quest, NeighborhoodMissions, BeatBook и ProfileStore проверяют музыку и события.','faded'),
    ('03','COMPANION HINT','В `State.companion` выдаётся следующая фраза Алиссии или Николаса.','coral'),
    ('04','CLIENT FEEDBACK','В свободной прогулке видно выбранного спутника; MK-I, сцена и listening не перекрываются.','amber')]):
    x=51+i*306
    rr(x,210,285,315,'white')
    c.setFillColor(C[color]);c.circle(x+37,477,22,stroke=0,fill=1)
    txt(n,x+25,471,16,True,'ink')
    txt(hd,x+19,422,17,True,'teal')
    block(body,x+19,377,245,16,25,'ink')
    if i<3:
        txt('›',x+288,347,38,True,'coral')
rr(53,129,1170,54,'teal')
txt('SOLO MODE = полноценная игра  ·  NO MIC RECORDING  ·  NO PAYWALL  ·  NO CLIENT-AWARDED REWARDS',75,149,18,True,'white')
end()

# 09 implementation
start('TECH HANDOFF','Модули, сеть и сохранение','Точка интеграции: уже существующие MusicNetwork.Command / State и schema-2 snapshot ProfileStore.')
left=[
 ('CompanionCatalog.luau','ID, displayName, разрешённый выбор'),
 ('CompanionProgress.luau','read-only сюжетные подсказки'),
 ('MusicService.luau','выбор на сервере и State projection'),
 ('ProfileStore.luau','optional sanitized companion field'),
 ('CommandPolicy.luau','разрешение команды вне MK-I'),
 ('CompanionView.luau','roaming UI / выбор и подсказка'),
 ('CompanionFollower.luau','локальный 3D blockout / teardown'),
 ('init.client.luau','подписка State, heartbeat, cleanup'),
]
rr(46,135,578,408,'white');rr(646,135,589,408,'white')
y=513
for i,(name,desc) in enumerate(left):
    txt(name,68,y,14,True,'teal')
    txt(desc,68,y-22,13,False,'muted')
    y-=48

txt('NETWORK',668,509,20,True,'coral')
block('Command: CompanionSelect("alissia" | "nikolas" | "none"). Сервер проверяет готовность, ограничение запросов и ID. Другой профиль, sample unlock, BPM, reward и position в запросе отсутствуют.',667,473,547,16,25)
txt('PERSISTENCE',668,347,20,True,'coral')
block('profile.companion — необязательное поле schema 2. Старые сохранения = "none". Выбор пишет прогресс через существующий `drainQuestSave` и conflict-aware snapshot; нельзя обходить cloud revision.',667,309,547,16,25)
end()

# 10 production
start('ASSET PRODUCTION','От концепта до игрового персонажа','Изображения внутри PDF — варианты художественных референсов. Их нельзя автоматически считать готовыми mesh/rig/texture.')
steps=[('01','CONCEPT','consistent front / side / back'),('02','DCC','Blender source mesh + pivot'),('03','QA','triangles / UV / rig / animation'),('04','ART APPROVAL','palette + NPC-scale comparison'),('05','STUDIO LOCAL','import and device check'),('06','RUNTIME','real mobile + multiplayer')]
for i,(num,hd,body) in enumerate(steps):
    x=44+(i%3)*402;y=353-(i//3)*180
    rr(x,y,382,152,'white',13)
    txt(num,x+18,y+99,32,True,'coral')
    txt(hd,x+87,y+105,17,True,'teal')
    block(body,x+87,y+73,270,15,22,'muted')
rr(47,106,1183,62,'teal')
txt('ПРОЕКТНЫЙ TARGET: LOD0 ≤4.5k tris  ·  LOD1 ≤2k  ·  LOD2 ≤800  ·  512² atlas',72,133,18,True,'white')
txt('Не ограничения движка; цифры требуют измерения и проверки в Studio.',71,115,12,False,'cream')
end()

# 11 acceptance
start('NEXT DEVELOPMENT BATCH','Что должен сделать Codex','Работать одним связанным пакетом, затем проверять. Не коммитить без нового прямого разрешения.')
items=[
('1','Сверить свежий main, локальные reference-assets и 6 NPC-листов; проверить открытые artbooks визуально.'),
('2','Создать отдельную ветку/worktree; выполнить tools/apply_companions.py --dry-run, затем интеграцию.'),
('3','Проверить ProfileStore migration/failed save, server allowance и independence нескольких игроков.'),
('4','Прогнать stylua, selene, один rojo build, затем согласованные Studio/phone acceptance checks.'),
('5','До создания финального rig согласовать характер/силуэты и очистить generated turnaround от несогласованных деталей.'),
('6','Не публиковать Roblox experience, не отправлять child photos/voice и не тратить Tripo credits.'),
]
y=550
for n,body in items:
    rr(47,y-63,1185,74,'white',11)
    txt(n,70,y-26,25,True,'coral')
    block(body,121,y-14,1066,17,24,'ink')
    y-=84
end()

# 12 truth/privacy
start('STATUS / SOURCES','Готово в документе ≠ готово в Roblox','Полная матрица приёмки и исходный patch: docs/COMPANION_DEV_HANDOFF_RU.md')
rr(48,140,1182,399,'white')
txt('ЧТО ПОДГОТОВЛЕНО',75,498,19,True,'teal')
block('Два новых character concept sheet, лор, art production constraints, исходные Luau-модули, fail-closed source patch, инженерная инструкция, список регрессионных проверок и машинный production manifest.',75,459,1080,18,28)
txt('ЧТО НЕ ПРОВЕРЕНО / НЕ СДЕЛАНО',75,339,19,True,'coral')
block('Не вносились изменения в удалённый GitHub; не было локальной сборки проекта, Studio импорта, теста на телефоне или реальной синхронизации Cloud DataStore. Публичные PDF с исходным артбуком не удалось визуально открыть в этой среде — непосредственно сверены текстовые правила, manifests и source code. Текущие 3D models существуют только как процедурный client-side blockout.',75,300,1080,17,27)
end()

c.save()
print(OUTPUT, OUTPUT.stat().st_size)
