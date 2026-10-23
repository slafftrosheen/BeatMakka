"""Editable design-artifact source. Uses bundled reportlab + pypdfium2, not the game build."""
from pathlib import Path
import json
import math
import textwrap
from xml.sax.saxutils import escape

from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.colors import HexColor, Color
from reportlab.lib.utils import ImageReader
import pypdfium2 as pdfium
from PIL import Image, ImageOps, ImageDraw

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[1]
W, H = 1440, 900
M = 64
P = {
    'paper':'F5EEDC', 'cream':'E8D8B7', 'white':'FAF4E6', 'ink':'162322',
    'teal':'2F5C58', 'faded':'6F9186', 'amber':'F3B65F', 'coral':'CA7453',
    'walnut':'79513B', 'stone':'B79C7E', 'graphite':'2C3031',
    'screen':'101B1A', 'screen2':'203431', 'muted':'52645D', 'rule':'C9C4B2',
}
FONTS = Path('C:/Windows/Fonts')
for name, file in [('Body','segoeui.ttf'),('Bold','segoeuib.ttf'),('Light','segoeuil.ttf'),('Mono','consola.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(FONTS/file)))

OUT = ROOT/'BeatMakka_MK-I_Artbook_Alpha01_RU.pdf'
c = canvas.Canvas(str(OUT), pagesize=(W,H), pageCompression=1)
c.setTitle('BeatMakka / MK-I - Device Artbook - Alpha 01')
c.setAuthor('BeatMakka - design study, 23 October 2026')
c.setSubject('Device, interaction, fixed touch UI and implementation handoff')
page_num = 0
page_records = []
active_record = None


def clean(s):
    return str(s).replace('\u2014','-').replace('\u2013','-').replace('\u2011','-').replace('\u00a0',' ')


def color(v):
    return HexColor('#'+P.get(v,v))


def rect(x,y,w,h,fill,r=0,stroke=None,lw=1):
    c.setFillColor(color(fill))
    c.setStrokeColor(color(stroke or fill))
    c.setLineWidth(lw)
    if r:
        c.roundRect(x,H-y-h,w,h,r,stroke=bool(stroke),fill=1)
    else:
        c.rect(x,H-y-h,w,h,stroke=bool(stroke),fill=1)


def line(x,y,x2,y2,col='rule',lw=1):
    c.setStrokeColor(color(col));c.setLineWidth(lw)
    c.line(x,H-y,x2,H-y2)


def txt(x,y,s,size=18,col='ink',font='Body',width=None):
    s=clean(s)
    if width and pdfmetrics.stringWidth(s,font,size)>width+1:
        raise ValueError(f'Page {page_num}: text too wide: {s}')
    c.setFillColor(color(col));c.setFont(font,size)
    c.drawString(x,H-y-size,s)
    if active_record is not None:
        active_record['text'].append(s)


def wrap(s,width,size,font='Body'):
    result=[]
    for block in clean(s).split('\n'):
        words=block.split(); current=''
        for word in words:
            trial=(current+' '+word).strip()
            if pdfmetrics.stringWidth(trial,font,size)>width and current:
                result.append(current);current=word
            else: current=trial
        result.append(current)
    return result


def para(x,y,s,width,size=19,col='ink',font='Body',leading=None,max_h=None):
    leading=leading or size*1.4
    rows=wrap(s,width,size,font)
    if max_h and len(rows)*leading>max_h+1:
        raise ValueError(f'Page {page_num}: paragraph overflow {len(rows)*leading}>{max_h}: {s[:70]}')
    for row in rows:
        txt(x,y,row,size,col,font);y+=leading
    return y


def badge(x,y,s,fill='teal',fg='cream',size=12):
    width=pdfmetrics.stringWidth(clean(s),'Bold',size)+24
    rect(x,y,width,28,fill,6);txt(x+12,y+5,s,size,fg,'Bold')
    return width


def bullets(x,y,rows,width=400,size=19,col='ink'):
    for s in rows:
        rect(x,y+10,5,5,'amber')
        y=para(x+18,y,s,width-18,size,col)+14
    return y


def image_fit(path,x,y,w,h):
    img=Image.open(path);iw,ih=img.size
    scale=min(w/iw,h/ih);dw,dh=iw*scale,ih*scale
    c.drawImage(ImageReader(img),x+(w-dw)/2,H-y-h+(h-dh)/2,dw,dh,mask='auto')


def image_cover(path,x,y,w,h):
    img=Image.open(path).convert('RGB')
    img=ImageOps.fit(img,(int(w*1.6),int(h*1.6)),method=Image.Resampling.LANCZOS)
    c.drawImage(ImageReader(img),x,H-y-h,w,h)


def page(kicker,title,subtitle='',dark=False):
    global page_num,active_record
    if page_num: c.showPage()
    page_num+=1
    bg='ink' if dark else 'paper'; fg='cream' if dark else 'ink'
    rect(0,0,W,H,bg)
    active_record={'page':page_num,'title':title,'text':[]}
    page_records.append(active_record)
    txt(M,30,'BEATMAKKA / MK-I',13,fg,'Bold')
    txt(945,32,'DEVICE ARTBOOK / ALPHA 01 / 23.10.2026',11,'faded','Mono')
    line(M,62,W-M,62,'teal' if dark else 'rule')
    txt(M,88,kicker.upper(),13,'faded' if dark else 'teal','Bold')
    if title: txt(M,118,title,42,fg,'Bold',width=W-M*2)
    if subtitle: para(M,180,subtitle,1240,18,'cream' if dark else 'muted',max_h=58)
    line(M,842,W-M,842,'teal' if dark else 'rule')
    txt(M,858,'DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE',10,'faded' if dark else 'muted','Mono')
    txt(W-115,853,f'{page_num:02}',24,fg,'Mono')


def note(x,y,w,title,body,fill='cream',h=150):
    rect(x,y,w,h,fill,10)
    fg='cream' if fill in ('teal','ink','screen') else 'ink'
    txt(x+22,y+18,title,20,fg,'Bold')
    para(x+22,y+54,body,w-44,17,fg,max_h=h-58)


def arrow(x1,y,x2,col='teal'):
    line(x1,y,x2,y,col,2)
    line(x2-8,y-5,x2,y,col,2);line(x2-8,y+5,x2,y,col,2)


LABELS=['Kick','Snare','Closed hat','Open hat','Clap','Rim','Low tom','High tom',
        'Shaker','Tambourine','Bell','Pluck','Bass C','Bass E-flat','Bass G','Chord']
KEYS=['1','2','3','4','Q','W','E','R','A','S','D','F','Z','X','C','V']


def wave(x,y,w,h,col='amber',n=64):
    for i in range(n):
        a=(math.sin(i*1.35)*.35+math.cos(i*.37)*.25+.45)*math.exp(-i/n*1.4)
        a=max(.08,abs(a))
        rect(x+i*w/n,y+h/2-a*h/2,max(2,w/n-3),a*h,col,1)


def grid_pads(x,y,w,h,selected=0,mini=False,finish='cream'):
    gap=w*.018
    pw=(w-3*gap)/4;ph=(h-3*gap)/4
    for i in range(16):
        xx=x+(i%4)*(pw+gap);yy=y+(i//4)*(ph+gap)
        muted=i==7
        fill='amber' if i==selected else ('stone' if muted else finish)
        rect(xx,yy,pw,ph,fill,7 if not mini else 3)
        if i==selected:
            rect(xx+4,yy+4,4,ph-8,'ink',2)
        sz=max(7,min(16,pw*.145))
        txt(xx+pw*.13,yy+ph*.12,f'{i+1:02}',sz,'ink','Mono')
        if not mini:
            label=LABELS[i]
            txt(xx+pw*.13,yy+ph*.42,label,max(8,min(17,pw*.14)),'ink','Bold')
            txt(xx+pw*.13,yy+ph*.76,'MUTED' if muted else ('SELECTED' if i==selected else KEYS[i]),max(6,min(10,pw*.085)),'ink','Mono')


def ui(x,y,w,mode='play',record=False,modal=False):
    """Original vector UI; reference resolution1200x680. Always exact sixteen pads."""
    h=w*680/1200;s=w/1200
    R=lambda a,b,d,e,f,r=0:rect(x+a*s,y+b*s,d*s,e*s,f,r*s)
    T=lambda a,b,t,z=16,col='cream',font='Body':txt(x+a*s,y+b*s,t,z*s,col,font)
    R(0,0,1200,680,'teal',18);R(10,10,1180,660,'screen',14)
    T(32,26,'MK-I',26,'cream','Bold');T(132,33,'QUAY SESSION',16,'faded','Mono')
    T(862,33,'SESSION SAVE',12,'faded','Mono');T(1056,31,'EXIT',15,'cream','Bold')
    for j,l in enumerate('ABCD'):
        R(32+j*84,78,72,34,'amber' if j==0 else 'screen2',5)
        T(60+j*84,84,l,18,'ink' if j==0 else 'cream','Bold')
    T(398,85,'96 BPM',22,'cream','Mono')
    T(560,87,'16 STEPS',14,'faded','Mono')
    T(1038,85,'REC' if record else 'READY',16,'coral' if record else 'faded','Bold')
    grid_pads(x+32*s,y+132*s,432*s,432*s,selected=0)
    R(492,132,676,432,'screen2',10)
    for j in range(4):
        R(510+j*158,146,150,30,'teal' if mode==['play','steps','sounds','beats'][j] else 'screen2',4)
        T(531+j*158,151,['PLAY','STEPS','SOUNDS','BEATS'][j],13,'cream','Bold')
    if mode=='play':
        T(518,200,'PAD 01 / KICK',14,'faded','Mono');T(518,233,'Warm kick',38,'cream','Bold')
        wave(x+520*s,y+304*s,616*s,90*s)
        T(518,422,'YOUR LOOP / A',14,'faded','Mono')
        for j in range(16):
            R(520+j*38,458,30,35,'amber' if j in (0,4,8,12) else 'teal',3)
        T(518,520,'Tap a pad. Build something yours.',17,'cream')
    elif mode=='steps':
        T(518,194,'PAD 01 / 16 STEPS',20,'cream','Bold');T(1002,198,'1/16',15,'faded','Mono')
        for j in range(16):
            a=520+(j%4)*156;b=237+(j//4)*63
            R(a,b,145,53,'amber' if j in (0,4,8,12) else 'teal',5)
            T(a+12,b+12,f'{j+1:02}  '+('ON' if j in (0,4,8,12) else 'OFF'),17,'ink' if j in (0,4,8,12) else 'cream','Mono')
        T(518,514,'CLEAR PAD',15,'coral','Bold');T(966,514,'MUTE PAD',15,'cream','Bold')
    elif mode=='sounds':
        T(518,194,'ASSIGN TO PAD 01',18,'cream','Bold')
        for j,name in enumerate(['Warm kick','Dry snare','Quay metal','Vent thump','Helper chirp']):
            R(518,235+j*45,604,39,'teal' if j==2 else 'screen2',4)
            T(534,241+j*45,f'{j+1:02}   '+name,17,'cream')
            T(1002,244+j*45,'COLLECTED' if j>=2 else 'READY',11,'faded','Mono')
        R(1142,235,4,220,'teal',2);R(1142,235,4,70,'amber',2)
        R(518,490,286,48,'teal',6);T(600,501,'PREVIEW',17,'cream','Bold')
        R(820,490,310,48,'amber',6);T(878,501,'ASSIGN TO PAD',17,'ink','Bold')
    elif mode=='beats':
        T(518,194,'YOUR BEAT SHELF',20,'cream','Bold')
        for j in range(6):
            a=518+j%3*208;b=237+j//3*98
            R(a,b,194,85,'amber' if j==0 else 'teal',6)
            T(a+15,b+12,f'Beat {j+1:02}',20,'ink' if j==0 else 'cream','Bold')
            T(a+15,b+47,'4 PATTERNS / SAVED' if j==0 else 'EMPTY',11,'ink' if j==0 else 'faded','Mono')
        R(518,466,286,49,'teal',6);T(567,479,'SAVE TO SHELF',16,'cream','Bold')
        R(820,466,310,49,'amber',6);T(888,479,'LOAD BEAT',16,'ink','Bold')
        T(518,532,'Each beat stores all four patterns.',13,'faded')
    R(32,588,184,53,'teal',7);T(80,601,'STOP',20,'cream','Bold')
    R(228,588,184,53,'amber',7);T(280,601,'PLAY',20,'ink','Bold')
    R(424,588,184,53,'coral' if record else 'screen2',7);T(468,601,'REC ON' if record else 'RECORD',20,'ink' if record else 'cream','Bold')
    T(636,603,'SOUND ON',15,'cream','Bold');T(812,603,'EFFECTS ON',15,'cream','Bold')
    T(1040,603,'SAVE *',15,'amber','Bold')
    T(38,650,'MK-I / NEEDLE QUAY',10,'faded','Mono');T(933,648,'LOOK   /   SETTINGS',12,'faded','Bold')
    if modal:
        R(498,182,658,365,'ink',10)
        T(532,212,'LOAD BEAT 01?',27,'cream','Bold')
        T(532,272,'Replaces all four working patterns.',18,'cream')
        T(532,307,'Stops playback. Shelf stays unchanged.',16,'faded')
        R(532,393,264,62,'teal',6);T(614,411,'CANCEL',18,'cream','Bold')
        R(814,393,304,62,'amber',6);T(862,411,'CONFIRM LOAD',18,'ink','Bold')
        T(532,487,'CONFIRMATION EXPIRES / 5s',12,'faded','Mono')
    return h


def phone(x,y,w,mode='play'):
    h=w*1.93;s=w/390
    rect(x-7,y-9,w+14,h+18,'graphite',28)
    rect(x,y,w,h,'screen',22)
    txt(x+18*s,y+17*s,'MK-I',19*s,'cream','Bold');txt(x+245*s,y+22*s,'96 BPM',17*s,'amber','Mono')
    for j,l in enumerate('ABCD'):
        rect(x+(18+j*56)*s,y+60*s,46*s,30*s,'amber' if j==0 else 'screen2',4)
        txt(x+(34+j*56)*s,y+65*s,l,14*s,'ink' if j==0 else 'cream','Bold')
    txt(x+273*s,y+66*s,'READY',12*s,'faded','Bold')
    rect(x+18*s,y+106*s,354*s,108*s,'screen2',7)
    txt(x+32*s,y+119*s,'PAD 01 / WARM KICK',14*s,'cream','Bold')
    if mode=='steps':
        for j in range(16):
            a=x+(32+j%8*40)*s;b=y+(151+j//8*26)*s
            rect(a,b,33*s,22*s,'amber' if j in (0,4,8,12) else 'teal',3)
            txt(a+6*s,b+3*s,str(j+1),10*s,'ink' if j in (0,4,8,12) else 'cream','Mono')
    else: wave(x+32*s,y+154*s,326*s,36*s)
    grid_pads(x+18*s,y+232*s,354*s,354*s,selected=0)
    for j,(l,f) in enumerate([('STOP','teal'),('PLAY','amber'),('REC','screen2')]):
        rect(x+(18+j*120)*s,y+608*s,114*s,48*s,f,6)
        txt(x+(45+j*120)*s,y+621*s,l,16*s,'ink' if f=='amber' else 'cream','Bold')
    for j,l in enumerate(['PLAY','STEPS','SOUNDS','BEATS']):
        txt(x+(20+j*93)*s,y+689*s,l,12*s,'amber' if l.upper()==mode.upper() else 'cream','Bold')
    return h


def device(x,y,w,finish='teal',numbers=False):
    h=w*.66
    rect(x,y,w,h,finish,20);rect(x+9,y+9,w-18,h-18,'cream',14)
    rect(x+19,y+19,w-38,h-38,finish,10)
    rect(x+w*.06,y+h*.08,w*.62,h*.19,'screen',7)
    wave(x+w*.09,y+h*.13,w*.55,h*.08)
    for j in range(2):
        c.setFillColor(color('graphite'));c.circle(x+w*(.79+j*.12),H-y-h*.17,w*.034,fill=1,stroke=0)
        line(x+w*(.79+j*.12),y+h*.15,x+w*(.79+j*.12),y+h*.11,'cream',2)
    grid_pads(x+w*.20,y+h*.34,w*.61,h*.57,mini=True,finish='cream')
    for j in range(3):rect(x+w*(.10+j*.18),y+h*.29,w*.13,h*.031,'coral' if j==1 else 'graphite',2)
    rect(x+w*.07,y+h*.42,w*.055,h*.39,'graphite',3)
    rect(x+w*.056,y+h*.62,w*.084,h*.045,'stone',2)
    return h


def table(x,y,width,headers,rows,cols,size=17,row_h=64):
    rect(x,y,width,42,'teal',6)
    xx=x
    for h,cw in zip(headers,cols):
        txt(xx+14,y+10,h,14,'cream','Bold');xx+=width*cw
    y+=42
    for j,row in enumerate(rows):
        rect(x,y,width,row_h,'white' if j%2==0 else 'cream',0)
        xx=x
        for value,cw in zip(row,cols):
            para(xx+14,y+13,str(value),width*cw-28,size,max_h=row_h-15)
            xx+=width*cw
        y+=row_h
    return y


def flow_row(y,steps):
    n=len(steps);gap=28;cw=(1312-gap*(n-1))/n
    for j,(name,body) in enumerate(steps):
        xx=M+j*(cw+gap)
        rect(xx,y,cw,178,'cream',10)
        badge(xx+18,y+15,f'{j+1:02}','teal')
        txt(xx+18,y+58,name,21,'ink','Bold')
        para(xx+18,y+96,body,cw-36,16,max_h=75)
        if j<n-1:arrow(xx+cw+5,y+86,xx+cw+gap-5)


# 01 / COVER
page('Alpha 01 / device design study','',dark=True)
image_cover(ROOT/'assets/mk-i-hero.png',0,64,W,778)
rect(64,94,560,185,'ink',14)
txt(88,109,'MK-I',66,'cream','Bold')
txt(91,195,'Собери свой ритм.',31,'cream','Light')
txt(91,244,'УСТРОЙСТВО / ЭКРАНЫ / УПРАВЛЕНИЕ',12,'amber','Mono')
badge(64,762,'BEATMAKKA / ALPHA 01','teal')
txt(782,782,'Русская редакция / дизайн-предложение v1.0',14,'cream')

# 02
page('01 / Product promise','Играть. Услышать. Сделать своим.','Один музыкальный инструмент, который хочется открыть ещё раз. Мир начинается с собственного ритма.')
txt(64,260,'Тактильный снаружи.',43,'teal','Bold')
txt(64,319,'Точный внутри.',43,'ink','Bold')
para(66,399,'Тёплый корпус принадлежит мастерской Needle Quay. Цифровой экран помогает сочинять: большие пэды, понятные состояния, короткий путь от удара до сохранённого бита.',520,22,max_h=188)
for j,(title,body) in enumerate([
    ('01 / Руки остаются на месте','Сетка 4×4 неподвижна. Жест игры не превращается в прокрутку.'),
    ('02 / Музыка отвечает сразу','Удар, выбранный пэд и записанная нота имеют различимые состояния.'),
    ('03 / Свой результат остаётся своим','Паттерны и сохранённый бит не теряются при переходах между экранами.')]):
    note(704,260+j*173,672,title,body,h=151)
badge(64,733,'ПРЕДЛОЖЕНИЕ / НА ОСНОВЕ ОБСУЖДЕНИЯ','teal')

# 03
page('02 / Sources & boundaries','Что является опорой дизайна','Новая визуальная редакция развивает устройство из исходного артбука. Она не заменяет реестр и не продвигает стадии готовности ассетов.')
table(64,256,1312,['Основа','Что сохраняем','Что проектируем здесь'],[
    ('Артбук v0.2 / board','Тёплая палитра, ремонт, материальность','Иерархия цифрового экрана и новая композиция UI'),
    ('H01 / authored contract','6×1.25×4 studs; 16 пэдов; -Z','Наглядный top view и смысл органов управления'),
    ('Код на 6ed1b00','16 шагов; 60–180 BPM; A–D; shelf ×6','Статичные экраны и touch-first flow'),
    ('Alpha 01 / issues #1–19','Инструмент раньше расширения мира','Порядок UI, звука, кастомизации и концерта'),
    ('Roblox / acceptance','Честные IDs и permissions','Отдельная приёмка, не показанная как готовая функция'),
],[.23,.35,.42],size=17,row_h=82)
note(64,735,1312,'Статусы в книге','ЕСТЬ В КОДЕ - существующая логика. ALPHA 01 - предлагаемый дизайн. ПОЗЖЕ - исследование или следующий этап.',h=82)

# 04
page('03 / Manufacturer research','Учимся устройствам, не копируем их','Просмотрены официальные страницы и руководства Akai, Ableton, Novation и Elektron. Ниже - выводы для нашего продукта, а не сравнительный обзор рынка.')
cards=[
 ('AKAI / MPC','Главный режим даёт контекст; редактирование открывается явно.','В MK-I: статус и транспорт постоянны, сложное действие имеет отдельный экран.','R1, R2'),
 ('ABLETON / MOVE','Короткая навигация и понятный возврат из браузера.','В MK-I: Preview отдельно от Assign; Back возвращает в предыдущий контекст.','R3'),
 ('NOVATION / CIRCUIT','Паттерн имеет различимые выбранное и ожидающее состояния.','В MK-I: слот виден текстом; будущую очередь не выдаём за готовую функцию.','R4'),
 ('ELEKTRON / DIGITAKT II','Контекст меняется, расположение параметров остаётся узнаваемым.','В MK-I: заголовок всегда объясняет, какой пэд или паттерн редактируется.','R5'),
]
for j,(name,a,b,ref) in enumerate(cards):
    x=64+j%2*672;y=254+j//2*274
    rect(x,y,640,248,'cream',12);txt(x+24,y+20,name,22,'teal','Bold')
    para(x+24,y+69,a,588,19,max_h=72);para(x+24,y+145,b,588,17,'muted',max_h=66)
    txt(x+24,y+219,ref+' / OFFICIAL MANUAL',10,'teal','Mono')

# 05
page('04 / Translation, not imitation','Что берём. Во что превращаем.','Аппаратные органы управления у производителей физические. В игре шестнадцать пэдов тоже должны помещаться в touch-интерфейсе.')
table(64,257,1312,['Принцип','Наша адаптация','Сознательно упрощаем'],[
    ('Стабильный Main','PLAY / STEPS / SOUNDS / BEATS','Не переносим desktop DAW на телефон'),
    ('Явные режимы','Один экран - одна задача','Нет обязательных Shift-комбинаций'),
    ('Контекстный редактор','PAD 01 / KICK виден в каждом действии','Нет десятков параметров одновременно'),
    ('Браузер с возвратом','Preview → Assign → Back','Не подменяем звук от простого скролла'),
    ('Статус музыкального времени','BPM, слот и transport на своих местах','Не обещаем hardware latency / velocity'),
    ('Живой переход паттерна','Предложение для будущего live-режима','Alpha пока останавливает транспорт при выборе'),
],[.22,.38,.40],row_h=75,size=17)
txt(64,790,'Ссылки R1–R5 и границы заимствования - в конце книги.',15,'muted')

# 06
page('05 / Device anatomy','Корпус узнаваем. Контролы точны.','H01 / MK-I. Ортографическая схема задаёт количество и соответствие контролов; концепт-иллюстрация задаёт материал и характер.')
device(295,267,760)
for xx,yy,s in [(70,286,'01 / цифровой экран'),(70,442,'02 / master slider'),(1108,286,'03 / 2 энкодера'),(1108,446,'04 / 16 пэдов')]:
    txt(xx,yy,s,17,'teal','Bold')
line(220,310,420,322,'teal',1.5);line(218,462,318,560,'teal',1.5)
line(1100,310,1010,354,'teal',1.5);line(1100,470,970,572,'teal',1.5)
txt(415,799,'6 W × 1.25 H × 4 D STUDS / PIVOT: BOTTOM CENTER / FRONT: -Z',13,'muted','Mono')

# 07
page('06 / Material language','Вещь с историей, экран без шума.','Повреждения живут на краях корпуса. Рабочие поверхности, надписи и зоны нажатия остаются чистыми и читаемыми.')
image_cover(ROOT/'assets/mk-i-materials.png',64,254,754,540)
materials=[('TEAL / краска','teal','Сатиновая краска, спокойный общий силуэт.'),('CREAM / кант','cream','Матовый защитный металл с точечным износом.'),('WALNUT / дерево','walnut','Крупный рисунок, тёплые боковины.'),('PAD / силикон','stone','Мягкая поверхность, лёгкий внутренний свет.'),('LCD / стекло','screen','Глубокий тёмный фон; никакой грязи поверх текста.')]
for j,(title,fill,body) in enumerate(materials):
    yy=258+j*108;rect(858,yy,56,56,fill,7);txt(934,yy,title,18,'ink','Bold');para(934,yy+32,body,420,16,'muted',max_h=69)

# 08
page('07 / Cosmetic family','Один инструмент. Четыре характера.','Существующие finish IDs сохраняются. Цвет корпуса не меняет значения пэдов, раскладку, hit targets или результат записи.')
for j,(fill,name,code) in enumerate([('teal','Workshop teal','quay'),('stone','Warm cream','chalk'),('coral','Repaired coral','coral'),('graphite','After hours','afterhours')]):
    x=80+j*335;device(x,310,285,fill)
    txt(x,540,name,22,'ink','Bold');txt(x,581,code,15,'teal','Mono')
    line(x,623,x+285,623)
para(80,671,'Косметические пресеты используют совместимый общий atlas. Смена скина не маскирует selected, muted, recording и unavailable; эти состояния имеют собственный текст и форму.',1230,23,max_h=115)

# 09
page('08 / Physical-to-digital map','Не заставлять пальцы целиться в 3D.','Модель приглашает подойти. Точная работа происходит в отдельном интерфейсе, где контролы достаточно крупные.')
device(64,302,526)
ui(666,281,710)
arrow(608,484,646)
table(64,685,1312,['На корпусе','В UI','Рамка Alpha 01'],[
    ('Пэды / экран / transport','Сетка 01–16; контекст; Play/Rec/Stop','Позиции и номера соответствуют миру'),
    ('Энкодеры / slider','Крупные цифровые поля / Sound control','Не все нарисованные ручки - реализованные параметры'),
],[.28,.35,.37],row_h=48,size=15)

# 10
page('09 / Digital design system','Тёплый свет. Строгая иерархия.','Цвет помогает, но никогда не является единственным носителем значения. Gameplay-текст остаётся native UI.')
for j,(name,fill,hexv) in enumerate([('INK','ink','162322'),('TEAL','teal','2F5C58'),('CREAM','cream','E8D8B7'),('AMBER','amber','F3B65F'),('CORAL','coral','CA7453'),('FADED','faded','6F9186')]):
    xx=64+j*221;rect(xx,267,196,122,fill,12);txt(xx,414,name,18,'ink','Bold');txt(xx,448,'#'+hexv,16,'muted','Mono')
note(64,524,620,'Сетка','Базовый шаг 8. Отступы 16 / 24 / 32. Радиусы 6–12 в UI; крупные рамки мягче. Минимальная цель нажатия - авторский target 44 px.',h=187)
note(716,524,660,'Типографика','В игре: Gotham / GothamBold из текущей Theme. Цифры BPM и шага - стабильной ширины. В PDF: Segoe UI и Consolas для качественного русского экспорта.',h=187)
txt(64,766,'AMBER FILL → INK TEXT / CORAL FILL → INK TEXT / INK FILL → CREAM TEXT',14,'teal','Mono')

# 11
page('10 / Navigation architecture','Четыре основных экрана. Один инструмент.','В performance-контексте пэды и транспорт закреплены. Библиотека и shelf открываются явным действием, а не случайным свайпом.')
for j,l in enumerate(['PLAY','STEPS','SOUNDS','BEATS']):
    x=64+j*336;rect(x,274,304,104,'teal',10);txt(x+23,300,l,34,'cream','Bold')
    txt(x+23,347,['играть','редактировать','выбирать','сохранять'][j],15,'cream')
    if j<3:arrow(x+308,324,x+332)
for j,(title,body) in enumerate([
    ('Глобально','BPM, A–D, Play / Record / Stop, статус сохранения.'),
    ('Внутри режима','Выбранный пэд, редактор шагов или список с отдельным Assign.'),
    ('Отдельно','Look и Settings доступны без перегрузки performance-панели.')]):
    note(64+j*448,440,416,title,body,h=186)
para(64,698,'Назад возвращает в предыдущий контекст. Прямой переход PLAY возвращает к инструменту за одно действие. Позиция списка сохраняется; selected pad и музыкальные данные не сбрасываются.',1312,22,max_h=113)

# 12
page('11 / Performance screen','Главный экран - музыкальная поверхность.','ALPHA 01 / основной вариант для планшета и desktop. Цифровое поле сообщает контекст, а не конкурирует с пэдами.')
ui(216,252,1008)

# 13
page('12 / Responsive composition','Та же память рук на любом экране.','Меняем композицию, а не номера пэдов и значения действий. Мировая форма устройства не обязана съедать экран телефона.')
phone(88,265,263)
ui(445,271,876)
txt(460,792,'Landscape: фиксированные пэды и транспорт; вторичный текст можно скрыть',14,'teal','Bold')

# 14
page('13 / Touch contract','Один палец - один управляемый удар.','Предлагаемый input-контракт. Значения задержек и число одновременных касаний подтверждаются измерением, не картинкой.')
touch=[('DOWN','Удар начинается по нажатию, не после отпускания.'),('CAPTURE','Палец закреплён за первым пэдом до Up / Cancel.'),('MULTITOUCH','Разные пальцы не отменяют и не переносят чужой удар.'),('NO SCROLL','В пределах performance-grid отключён touch pan.'),('CANCEL','Потеря фокуса и выход очищают активные касания.'),('NO PRESSURE','Не обещаем velocity по силе касания без API и устройства.')]
for j,(title,body) in enumerate(touch):note(64+(j%3)*448,263+(j//3)*245,416,title,body,h=210)
txt(64,791,'Свайп не «рисует» ноты по соседним пэдам. Hold-жесты не нужны для первого бита.',18,'teal','Bold')

# 15
page('14 / Transport & recording','Играть и записывать - разные состояния.','Понятная надпись и форма важнее одного цветного огонька. Звуковой отклик и запись шага - разные операции.')
flow_row(277,[('READY','Пэды звучат при нажатии. В паттерн ничего не пишется.'),('PLAY','Паттерн крутится. Пэды можно слушать поверх.'),('REC','Игровые удары добавляются в ближайший шаг.'),('STOP','Останавливает транспорт. Музыкальные данные остаются.')])
ui(96,520,532,record=True)
note(770,535,606,'Решение Alpha','Сохраняем существующее квантование 1/16 и 16 шагов. Count-in, undo и изменение resolution - отдельные будущие функции.',h=166)
para(770,737,'REC обозначается текстом и отдельной формой. Reduced motion не скрывает recording state.',570,18,max_h=78)

# 16
page('15 / Step editing','Сначала выбранный звук. Потом его шаги.','STEPS редактирует ровно один из 16 пэдов. Выбранный PAD, его звук и активный слот видны до любого изменения.')
ui(64,257,995,mode='steps')
bullets(1101,280,['Нажатие меняет ON/OFF.','Текущий playhead - рамка/указатель, не замена ON.','Mute сохраняет ноты.','Clear требует ясного контекста.','На телефоне шаги 4×4 на отдельном экране; PLAY возвращает пэды.'],275,18)

# 17
page('16 / Sound browser','Слушать отдельно. Назначать осознанно.','Прокручивается только список SOUNDS. Скролл и выделение файла не меняют звук в паттерне автоматически.')
ui(64,257,995,mode='sounds')
bullets(1101,279,['PAD 01 указан явно.','Preview не пишет в паттерн.','Assign - отдельное действие.','Locked объясняет, где найти звук.','На телефоне библиотека - отдельный экран с Back to Play.'],275,18)

# 18
page('17 / Discovery flow','Принести звук из района в свой бит.','Сбор виртуальных игровых звуков - текущая творческая основа. Это не обещание записи реального микрофона.')
flow_row(277,[('Найти','I03 / helper robot: взаимодействие с объектом.'),('Получить','Звук появляется в коллекции с происхождением.'),('Назначить','Выбран PAD 01, Preview → Assign.'),('Использовать','Добавить шаг или записать удар. Сохранить бит.')])
for j,(id,title,sub) in enumerate([('I01','QUAY METAL','metal_hit'),('I02','VENT THUMP','vent_thump'),('I03','HELPER CHIRP','robot_chirp')]):
    xx=64+j*448;rect(xx,527,416,225,'teal',12)
    txt(xx+24,552,id,48,'amber','Mono');txt(xx+24,622,title,23,'cream','Bold');txt(xx+24,673,sub,16,'cream','Mono')

# 19
page('18 / Four independent patterns','A–D - четыре варианта одной идеи.','Каждый слот хранит собственные 16×16 шагов, назначения, mute и BPM. Полка сохраняет весь четырёхслотовый проект.')
for j,l in enumerate('ABCD'):
    xx=64+j*336;rect(xx,265,304,220,'amber' if j==0 else 'teal',12)
    fg='ink' if j==0 else 'cream';txt(xx+25,283,l,72,fg,'Bold')
    txt(xx+26,392,['96 BPM / ACTIVE','120 BPM / LOOP','140 BPM / LOOP','96 BPM / EMPTY'][j],17,fg,'Mono')
note(64,546,638,'ЕСТЬ В КОДЕ','Выбор слота останавливает Play и Record. Сетка сразу показывает выбранный паттерн. Данные остальных слотов не стираются.',h=193)
note(734,546,642,'ПОЗЖЕ / LIVE-QUEUE','Запуск следующего паттерна по границе такта - отдельная проектная задача. Показывать QUEUED можно только после реализации протокола.',h=193)

# 20
page('19 / Personal beat shelf','Шесть мест. Каждый бит хранит A–D.','Фиксированные названия Beat 01–06 сохраняют понятность и не создают неготовую систему публичных имён.')
ui(64,257,995,mode='beats')
bullets(1101,280,['Выбор позиции сам ничего не загружает.','Save captures все четыре слота.','Load заменяет working slots, не полку.','Версия shelf защищает от stale overwrite.','Cloud и session save обозначены явно.'],275,18)

# 21
page('20 / Save & destructive actions','Ошибку можно заметить. Работу - сохранить.','Диалоги используются только для действий с последствиями. Сохранение и редактирование имеют независимые состояния.')
ui(64,257,890,mode='beats',modal=True)
note(996,264,380,'OVERWRITE / LOAD','Повторное подтверждение действует 5 секунд. Изменение проекта или позиции отменяет pending action.',h=175)
note(996,462,380,'FAILED SAVE','Правки остаются открытыми и dirty. Никакой ложной надписи Saved.',h=156)
note(996,641,380,'BUSY','Load / Restore недоступны во время сохранения. Статус объясняет ожидание.',h=147)

# 22
page('21 / First-beat storyboard','Первый бит без устного объяснения.','Сценарий приёмки, а не обещание фиксированного времени. Новичок должен суметь повторить путь самостоятельно.')
stories=[('01 / Открыть','Подойти к MK-I. Увидеть доступный инструмент и понятный вход.'),('02 / Поиграть','Нажать несколько неподвижных пэдов. Узнать характер звуков.'),('03 / Записать','Включить Record и сыграть простой ритм или включить шаги.'),('04 / Вариация','Выбрать B, создать вторую идею. A остаётся на месте.'),('05 / Сохранить','Beat 01 → Save to shelf. Увидеть точный save status.'),('06 / Вернуться','Изменить рабочие слоты, подтвердить Load и услышать сохранённый бит.')]
for j,(title,body) in enumerate(stories):
    xx=64+(j%3)*448;yy=263+(j//3)*253
    rect(xx,yy,416,222,'cream',12);txt(xx+22,yy+20,title,23,'teal','Bold')
    para(xx+22,yy+75,body,372,19,max_h=113)

# 23
page('22 / Pad detail & complexity','Открывать глубину постепенно.','Alpha 01 не превращает первый экран в студийный пульт. Дополнительные звуковые параметры проектируются отдельными этапами.')
table(64,266,1312,['Слой','Экран / управление','Статус'],[
    ('Игра','Hit / Select pad / Play / Record','Основной предлагаемый Alpha UX'),
    ('Редактор','Assign sound / 16 steps / Mute / Clear','Существующие операции в новой композиции'),
    ('Уровень звука','Sound on/off; явный master mute','Есть базовое управление; slider требует реализации'),
    ('Тембр / обработка','Gain, filter, envelopes, sends, automation','Позже: не выдавать ручки за рабочий DSP'),
    ('Undo / duplicate / arranger','Безопасные музыкальные вариации','Отдельные предложения, вне обещаний текущего кода'),
],[.22,.43,.35],row_h=86,size=18)
txt(64,777,'Физический энкодер может быть частью образа; игровая функция должна иметь отдельный контракт.',18,'teal','Bold')

# 24
page('23 / Status language','Не заставлять угадывать по цвету.','Каждое состояние имеет текст, форму или второй признак. Одновременные selected / muted / hit не смешиваются в один цвет.')
states=[('READY','cream','Тихий пэд; номер и имя видны.'),('SELECTED','amber','Рамка / боковой маркер + label.'),('HIT','amber','Короткий световой отклик; без тряски UI.'),('MUTED','stone','MUTED + перечёркнутый speaker marker.'),('RECORDING','coral','REC + видимый transport state.'),('UNAVAILABLE','graphite','Причина: locked, loading или no access.')]
for j,(title,fill,body) in enumerate(states):
    xx=64+(j%3)*448;yy=267+(j//3)*239
    rect(xx,yy,116,116,fill,12)
    txt(xx+15,yy+18,f'{j+1:02}',20,'cream' if fill=='graphite' else 'ink','Mono')
    txt(xx+145,yy+3,title,20,'teal','Bold');para(xx+145,yy+47,body,260,18,max_h=115)
txt(64,790,'Reduced motion: остаются текст, выбранная рамка и позиция playhead. Цветовое мерцание необязательно.',17,'muted')

# 25
page('24 / Settings & accessibility','Понятно на слух, видно глазами, удобно рукой.','Настройки открываются отдельно. Их изменение не стирает паттерны и не скрывает текущий музыкальный статус.')
for j,(title,body) in enumerate([
    ('Управление','Touch, keyboard и gamepad используют одни действия. Видимый focus; Back не теряет контекст.'),
    ('Доступность','Reduced motion; маркировка не только цветом; увеличение текста без уменьшения пэдов ниже hit target.'),
    ('Локализация','Короткие UI labels EN / RU / LV. Ширина с запасом; текст не запечён в корпус или texture atlas.'),
    ('Аудио','Mute отделён от Record. Загрузка/permissions не маскируются под тишину выбранного звука.')]):
    note(64+(j%2)*672,265+(j//2)*255,640,title,body,h=220)

# 26
page('25 / World-to-instrument flow','Мир зовёт. Устройство даёт контроль.','Сначала проверяем владельца станции и дистанцию. Музыкальный интерфейс не требует сидеть на стуле или целиться в маленькие 3D-надписи.')
flow_row(276,[('Подойти','Явный prompt и статус свободно / занято.'),('Открыть','Fixed performance UI. Touch movement не перекрывает пэды.'),('Создавать','Паттерн принадлежит игроку, а не станку.'),('Выйти','Освободить station, остановить запись, сохранить текущие правки в сессии.')])
note(64,528,640,'Уход со станции','Distance / death / respawn / disconnect очищают session ownership. Запись не продолжается незаметно после закрытия.',h=210)
note(736,528,640,'Сохранение - отдельное действие','Working state остаётся с игроком в сессии. Cloud durability подтверждается реальной save/rejoin-приёмкой, не видом экрана.',h=210)

# 27
page('26 / Chapter concert concept','Район узнаёт собственную музыку.','ПОЗЖЕ / финал секции района. Это новый encounter, а не изменение условий уже работающего первого квеста Мики.')
ui(64,257,910)
note(1016,267,360,'Не popularity gate','NPC реагируют на понятные освоенные приёмы. Для прохождения не нужна аудитория реальных игроков.',h=190)
note(1016,480,360,'Подсказка не перекрывает пэды','Один короткий музыкальный запрос в цифровом поле. Успех постепенно оживляет жителей, свет и вывески.',h=210)
txt(64,790,'Своя композиция остаётся своей. Не требовать совпадения с единственным «правильным» треком.',17,'teal','Bold')

# 28
page('27 / Future cooperative set','Два устройства. Одна музыкальная фраза.','ПОЗЖЕ / Link-подобное ощущение, не обещание интеграции Ableton Link SDK или готовой пятичленной группы.')
device(64,306,515);device(858,306,515)
rect(608,355,220,170,'teal',15);txt(634,378,'96 BPM',32,'cream','Mono');txt(634,430,'BAR START',19,'amber','Bold');txt(634,471,'SHARED CLOCK',12,'cream','Mono')
arrow(582,431,605);arrow(830,431,854)
note(64,692,640,'Сначала двое','Роли, темп, фаза, timestamped changes. Известные звуки воспроизводятся локально.',h=112)
note(736,692,640,'До пяти - после измерений','Clock drift, jitter, сеть, voices и headroom требуют доказательства на целевых устройствах.',h=112)

# 29
page('28 / Personal space & customization','Тот же характер - в своём record shop.','Косметика связывает инструмент с районом. Она не меняет музыкальные возможности и не вводит неутверждённую экономику.')
image_cover(ROOT/'assets/needle-quay-approved-style-board.png',64,263,820,492)
note(928,267,448,'Материалы одной семьи','Те же дерево, краска, ткань и металл. Новые варианты сохраняют совместимый atlas и читаемость.',h=208)
note(928,500,448,'Личное и общее','Отделить владение магазином, декором и finish устройства. Посетитель не редактирует чужие настройки.',h=208)
txt(64,786,'Исходный утверждённый board / визуальная опора, не новая приёмка отдельных моделей.',15,'muted')

# 30
page('29 / Roblox implementation handoff','Фиксированные Frames вместо длинного Canvas.','Предлагаемая компонентная структура. Книга и браузерный прототип не являются изменением production Luau.')
table(64,258,1312,['Компонент','Обязанность','Ограничение'],[
    ('InstrumentShell','Safe insets, layout, current view','Не скроллится; не перехватывает pad gestures'),
    ('PadGrid16','Pointer ownership, selected/hit/muted','Exact 4×4; canonical 01–16; no on-release-only hits'),
    ('ContextDisplay','Play / Steps / browser / shelf','Показывает selected pad, slot и operation target'),
    ('TransportBar','Play / Record / Stop / sound','Стабильное место; не уничтожается при смене view'),
    ('LibraryList','Samples / beats / длинные каталоги','Единственный явный scroll region'),
    ('SaveState / Dialog','Dirty, busy, error, stale version','Server authority; clear user confirmation'),
],[.22,.38,.40],row_h=75,size=17)
txt(64,790,'UI не создаёт аудио IDs, cloud permissions или asset acceptance. Эти этапы остаются отдельными.',17,'teal','Bold')

# 31
page('30 / Production contract','Красота укладывается в существующий бюджет.','Это authored project constraints, а не ограничения платформы. Никакая новая картинка не является лицензией на provider spend.')
table(64,262,1312,['Пакет / contract','Сохраняемый предел','Приёмка'],[
    ('H01 / assembled workstation','До 4500 triangles, включая 16 пэдов','Измерить полную сборку, а не одну оболочку'),
    ('H01 / world envelope','6×1.25×4 studs / bottom-center / -Z','Сверить границы, pivots и station interaction'),
    ('Texture family','1024 cap; shared 512 derivatives','UV/layout version, каналы, финальная PBR-проверка'),
    ('U01–U04 / native UI','Текст и focus отдельно от bitmap','Touch, gamepad, keyboard, reduced motion'),
    ('Stages','candidate → DCC-clean → art-approved','Потом Studio-imported → runtime-verified'),
],[.28,.34,.38],row_h=88,size=17)
txt(64,790,'Концепт-рендеры этой книги не отправляются как многообъектный provider input.',17,'teal','Bold')

# 32
page('31 / Alpha 01 delivery map','Что уже есть. Что делаем следующим.','Implementation evidence и design intent разделены. Главная приёмка - первый сохранённый и снова открытый бит.')
table(64,258,1312,['Слой','Статус','Связанные issues'],[
    ('A–D / shelf / first Mica quest','ЕСТЬ / проверено в Studio на 6ed1b00','#6 / сохранить поведение'),
    ('Fixed UI / touch / navigation','ALPHA 01 / дизайн этой книги','#2, #3, #6'),
    ('Настоящий звук / лицензии / cloud saves','ОТДЕЛЬНАЯ ПРИЁМКА','#4, #5, #10'),
    ('Finish / record shop / final imports','P1 / визуальный и ownership review','#8, #9, #11'),
    ('Район / concert finale','P1 / новый chapter encounter','#12, #13'),
    ('Jam / MIDI / microphone','ПОЗЖЕ / исследование и измерения','#15, #16, #18, #19'),
],[.35,.40,.25],row_h=76,size=17)

# 33
page('32 / Acceptance checklist','Принимать руками, глазами и сохранённым результатом.','Это чек-лист будущей implementation-приёмки. Проверка самого PDF не подтверждает поведение Roblox.')
checks=[('TOUCH','16 пэдов видны. Несколько касаний не вызывают scroll, ghost hits и зависание.'),('MUSIC','Play / Record / Stop и квантование объяснимы. Недоступный звук имеет причину.'),('NAVIGATION','Back и PLAY возвращают без потери слота, selected pad и рабочего проекта.'),('SAVE','Overwrite/load требуют подтверждения. Dirty/error/busy честны; rejoin проверяется отдельно.'),('VISUAL','Материалы читаются нейтрально и на закате. В UI нет лишнего шума и нечитаемых labels.'),('DEVICE','Реальный телефон/планшет, gamepad и keyboard проверены с измерениями, а не обещаниями.')]
for j,(title,body) in enumerate(checks):note(64+(j%2)*672,259+(j//2)*184,640,title,body,h=158)

# 34
page('33 / Sources & research receipts','Первичные источники. Датированные выводы.','Официальные материалы просмотрены 23.10.2026. UI-графика производителей не включена в книгу: схемы и экраны MK-I оригинальные.')
sources=[
 ('R1 / AKAI MPC 3 FAQ','https://support.akaipro.com/en/support/solutions/articles/69000857771-mpc3-faq','Новый Main Mode; разделение режимов. Не переносим arranger и сложность целиком.'),
 ('R2 / AKAI MPC 3.6 UI example','https://support.akaipro.com/en/support/solutions/articles/69000860746-akai-pro-mpc-series-changing-the-time-signature','Просмотрены Main и отдельное modal editing; не копируем форму/графику.'),
 ('R3 / ABLETON MOVE MANUAL','https://www.ableton.com/en/move/manual/','Browser / Back / audition. Переносим короткий путь, не hardware microphone или Link SDK.'),
 ('R4 / NOVATION CIRCUIT TRACKS','https://userguides.novationmusic.com/hc/en-gb/articles/26207128061458-Using-Circuit-Tracks-Synths-MIDI-Tracks-and-Drums','Состояния паттернов и различие selection / queued transition.'),
 ('R5 / ELEKTRON DIGITAKT II','https://www.elektron.se/wp-content/uploads/2025/04/Digitakt-2-User-Manual_ENG_OS1.10A_250415.pdf','Раздел 6, стр.18: стабильная contextual organization. Поисковая версия доступна; прямой PDF не выдал файл.'),
]
for j,(title,url,body) in enumerate(sources):
    yy=250+j*106;txt(64,yy,title,18,'teal','Bold');para(64,yy+32,body,1290,17,'ink',max_h=50)
    c.linkURL(url,(64,H-yy-70,1360,H-yy+2),relative=0,thickness=0)
txt(64,798,'Клик по блоку открывает официальный источник. Полные URL и журнал доступны в SOURCE.md.',14,'muted')

# 35
page('34 / Source package & review status','Дизайн, который можно продолжить.','PDF + исходный код верстки + tokens + интерактивный браузерный прототип. Визуальный review не подменяет реализацию.')
note(64,261,635,'Авторские иллюстрации','Hero и material macro созданы imagegen по утверждённому board. Ошибочный первый 12-pad вариант отклонён; в книге используется исправленный 4×4 concept.',h=210)
note(731,261,645,'Детерминированные экраны','Все пэды, UI, схемы и номера собраны векторами. Концепт корпуса не является геометрическим чертежом, texture atlas или art-approved asset.',h=210)
note(64,504,635,'Браузерный прототип','Оригинальные исходные WAV проекта; только локальная демонстрация interaction. Не соединён с Roblox, облачной полкой, permissions или микрофоном.',h=210)
note(731,504,645,'Следующее решение','Посмотреть performance-экран на реальном телефоне/планшете, согласовать композицию и затем реализовать A01-01/A01-02. Никаких скрытых uploads или spend.',h=210)
txt(64,785,'ART DIRECTION v1.0 / APPROVAL PENDING / CANONICAL ASSET CONTRACTS UNCHANGED',13,'teal','Mono')

# 36 / END
page('MK-I / BeatMakka','',dark=True)
image_cover(ROOT/'assets/mk-i-materials.png',0,64,W,778)
rect(64,485,870,292,'ink',18)
txt(96,510,'Музыка начинается',52,'cream','Bold')
txt(96,574,'с одного удара.',52,'cream','Bold')
txt(100,678,'Неподвижные пэды. Понятный экран. Твой район.',23,'cream')
txt(100,735,'ALPHA 01 / MK-I DEVICE ARTBOOK / v1.0',12,'amber','Mono')

c.save()

# Editable text companion and tokens are generated from the exact authored pages.
md=['# BeatMakka / MK-I - Device Artbook - Alpha 01','',
    'Русская редакция, 23 октября 2026. Дизайн-предложение. Не runtime acceptance.','',
    '## Файлы','', '- PDF: BeatMakka_MK-I_Artbook_Alpha01_RU.pdf',
    '- Интерактивный прототип: MK-I_Prototype.html', '- Верстка: build_artbook.py',
    '- Токены: design-tokens.json','', '## Полный текст разворотов','']
for p in page_records:
    md.extend([f"### {p['page']:02} / {p['title'] or 'Обложка'}",'','\n\n'.join(dict.fromkeys(p['text'])),''])
md+=['## Полные ссылки на исследования','']+[f'- {title}: {url}\n  {body}' for title,url,body in sources]
md+=['','## Собственные источники','',
     '- 01_Visual_Artbook.pdf, стр.2–6,10–12; 02_Production_Atlas.pdf, H01/U01–U04.',
     '- Asset_Production_Register.xlsx и data/assets.json: H01 dims6×1.25×4; cap4500tri; texture1024.',
     '- assets/references/needle-quay-approved-style-board.png; SHA-256 сохранён в соседнем JSON.',
     '- src/shared/Theme.luau, Pattern.luau, BeatBook.luau; src/client/WorkshopView.luau.',
     '- docs/MILESTONE_VERIFICATION.md: существующая implementation evidence на 6ed1b00.',
     '- Alpha01 tracker: https://github.com/slafftrosheen/BeatMakka/issues/1','',
     '## Генерация иллюстраций','',
     'Использован встроенный image_gen. Промпты и пути исходных результатов - в image-prompts.json. '
     'Никакие manufacturer screenshots/logos не включены. Первый неверный12-pad render не использован. '
     'Не изменены gameplay sources, asset IDs, реестр и asset acceptance stages.']
(ROOT/'SOURCE.md').write_text('\n'.join(md),encoding='utf-8')
(ROOT/'design-tokens.json').write_text(json.dumps({
    'version':'1.0-design-proposal','palette':P,'space':[8,16,24,32],
    'ui_font':'Gotham / GothamBold','document_fonts':'Segoe UI / Consolas',
    'pad_grid':{'columns':4,'rows':4,'canonical_order':'01 top-left → 16 bottom-right'},
    'minimum_touch_target_authored_px':44,'screens':['PLAY','STEPS','SOUNDS','BEATS'],
    'transport':['STOP','PLAY','RECORD'],'slots':['A','B','C','D'],'shelf_positions':6,
    'H01_contract':{'dimensions_studs':[6,1.25,4],'max_assembled_triangles':4500,'texture_cap':1024},
    'prototype_status':'standalone interaction study, not Roblox runtime evidence',
},indent=2,ensure_ascii=False),encoding='utf-8')

pdf=pdfium.PdfDocument(str(OUT));thumbs=[]
for n in range(len(pdf)):
    im=pdf[n].render(scale=.40).to_pil().convert('RGB')
    thumb=Image.new('RGB',(300,207),'#E8D8B7')
    thumb.paste(ImageOps.fit(im,(288,180)),(6,5));d=ImageDraw.Draw(thumb)
    d.text((8,188),f'{n+1:02}',fill='#162322')
    thumbs.append(thumb)
sheet=Image.new('RGB',(6*300,6*207),'#C9C4B2')
for n,im in enumerate(thumbs):sheet.paste(im,((n%6)*300,(n//6)*207))
sheet.save(ROOT/'previews/contact-sheet.jpg',quality=90)
for n,name in [(0,'cover'),(11,'performance'),(12,'responsive'),(16,'sounds'),(19,'beat-shelf'),(20,'load-dialog'),(31,'handoff')]:
    pdf[n].render(scale=1).to_pil().save(ROOT/f'previews/{name}.png')
(ROOT/'page-index.json').write_text(json.dumps(page_records,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'pdf':str(OUT),'pages':len(pdf),'text_pages':len(page_records)},ensure_ascii=False))
