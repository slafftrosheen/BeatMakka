from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.colors import HexColor, Color
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from xml.sax.saxutils import escape
import math
O=Path(__file__).resolve().parents[1]
M=O/'maps';OUT=O/'BeatMakka_World_Artbook_v2_RU.pdf'
W,H=1024,576
P={'dark':'#101C1D','ink':'#162322','teal':'#2F5C58','faded':'#6F9186','amber':'#F3B65F','coral':'#CA7453','paper':'#F5EEDC','cream':'#E8D8B7','white':'#FAF4E6','walnut':'#79513B','stone':'#B79C7E','graphite':'#2C3031','line':'#52645D','mint':'#A8C6B8','fog':'#243536'}
for nm,pth in [('D','/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'),('DB','/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')]:pdfmetrics.registerFont(TTFont(nm,pth))
C=canvas.Canvas(str(OUT),pagesize=(W,H),pageCompression=1)
C.setTitle('BeatMakka — World Artbook v2.0 / Resonance City')
C.setAuthor('BeatMakka creative development package')
COUNT=0;WARN=[]

def fill(hex):C.setFillColor(HexColor(P.get(hex,hex)))
def stroke(hex):C.setStrokeColor(HexColor(P.get(hex,hex)))
def rect(x,y,w,h,bg='fog',radius=14,edge=None,lw=1):
 C.setLineWidth(lw);fill(bg)
 if edge:stroke(edge)
 else:stroke(bg)
 C.roundRect(x,y,w,h,radius,stroke=1 if edge else 0,fill=1)
def txt(s,x,y,size=13,bold=False,color='paper',align='left'):
 C.setFont('DB' if bold else 'D',size);fill(color)
 if align=='center':C.drawCentredString(x,y,s)
 elif align=='right':C.drawRightString(x,y,s)
 else:C.drawString(x,y,s)
def para(s,x,top,w,maxh,size=14,color='cream',leading=None,bold=False):
 """top-down paragraph, return used points. shrink to fit."""
 s=escape(s).replace('\n','<br/>')
 for z in range(int(size*2),19,-1):
  zz=z/2
  st=ParagraphStyle('custom',fontName='DB' if bold else 'D',fontSize=zz,leading=(leading or zz*1.5),textColor=HexColor(P.get(color,color)),spaceAfter=0,wordWrap='CJK' if False else None)
  p=Paragraph(s,st)
  _,hh=p.wrap(w,maxh+500)
  if hh<=maxh+1:break
 if hh>maxh+1:WARN.append((COUNT,'paragraph overflow',hh,maxh,s[:80]))
 p.drawOn(C,x,top-hh)
 return hh

def imagefit(path,x,y,w,h,alpha=1):
 from PIL import Image
 im=Image.open(path);iw,ih=im.size
 scale=min(w/iw,h/ih)
 dw,dh=iw*scale,ih*scale
 C.saveState()
 if alpha<1:C.setFillAlpha(alpha)
 C.drawImage(ImageReader(im),x+(w-dw)/2,y+(h-dh)/2,dw,dh,mask='auto')
 C.restoreState()

def top(kicker,title,subtitle='',dark=True):
 global COUNT
 COUNT+=1
 fill('dark' if dark else 'paper');C.rect(0,0,W,H,fill=1,stroke=0)
 for j in range(24):
  # faint horizontal grid
  stroke('#294344' if dark else '#D9D3BD');C.setLineWidth(.32);C.line(0,j*26+10,W,j*26+10)
 rect(45,510,8,35,'amber',4)
 txt(kicker.upper(),71,548,10,True,'amber' if dark else 'coral')
 txt(title,71,517,29,True,'paper' if dark else 'ink')
 if subtitle:txt(subtitle,70,493,11,False,'mint' if dark else 'teal')
 txt('BEATMAKKA / WORLD v2.0',48,24,9,True,'faded' if dark else 'teal')
 txt(f'{COUNT:02d}',978,24,11,True,'amber' if dark else 'coral',align='right')
def end():C.showPage()
def card(x,y,w,h,heading,body='',accent='amber',bg='fog',bsize=13):
 rect(x,y,w,h,bg,13,edge='#45625B' if bg=='fog' else None,lw=.8)
 rect(x+18,y+h-49,5,24,accent,2)
 txt(heading,x+33,y+h-42,16,True,'paper')
 if body:para(body,x+21,y+h-64,w-43,h-83,size=bsize,color='cream')
def label(x,y,s,color='amber',size=10):
 txt(s,x,y,size,True,color)
def dot_line(x,y,w,title,body,color='amber'):
 fill(color);C.circle(x+9,y+7,7,fill=1,stroke=0)
 txt(title,x+26,y+13,14,True,'paper')
 para(body,x+26,y-3,w-36,37,size=11.8)
def thinpath(points,color='amber',width=3):
 stroke(color);C.setLineWidth(width)
 p=C.beginPath();p.moveTo(*points[0]);
 for x,y in points[1:]:p.lineTo(x,y)
 C.drawPath(p)

def chip(x,y,w,s,color='teal',tc='paper',size=12):
 rect(x,y,w,30,color,9)
 txt(s,x+w/2,y+9,size,True,tc,align='center')

# 01 cover
COUNT+=1
fill('dark');C.rect(0,0,W,H,fill=1,stroke=0)
imagefit(M/'BeatMakka_City_Map_Initial_Locked.png',477,92,540,415,.9)
rect(30,80,480,425,'ink',20)
rect(65,468,12,58,'amber',5)
txt('BEATMAKKA',92,481,28,True,'cream')
txt('WORLD',62,402,62,True,'paper')
txt('ARTBOOK',61,333,62,True,'paper')
txt('V2.0',65,282,35,True,'amber')
para('RESONANCE CITY · мир, который вновь учится создавать.\nИгровая карта · 11 жанров · фургон-студия · демо Needle Quay.',64,243,391,105,size=17,color='cream')
txt('АРТ-ДИРЕКШН + СИСТЕМНЫЙ ДИЗАЙН  ·  24.10.2026',64,102,12,True,'mint')
txt('НЕ ЯВЛЯЕТСЯ УЖЕ СОБРАННОЙ ROBLOX-ЛОКАЦИЕЙ',48,45,12,False,'faded')
txt('01',978,24,11,True,'amber',align='right');end()

# 02 promise
# 02 direction
top('01 / концепция','Главный игровой принцип','Сначала создавай. Затем город начнёт отвечать.')
card(49,220,294,246,'Создавай','Начальный цикл работает за считаные минуты: выбери звук, нажми пэд, включи запись, сохрани первый паттерн. Никто не обязан заранее знать теорию музыки.','amber',bsize=14)
card(365,220,294,246,'Помогай','Каждая остановка фургона содержит локальную историю: услышать проблему, исследовать звуки места, помочь жителю и сделать короткое выступление.','coral',bsize=14)
card(681,220,294,246,'Возвращай жизнь','После действий игрока площадь светлеет, жители выходят на улицу, клуб открывается, радио передаёт первый сигнал в соседние районы.','mint',bsize=14)
rect(50,81,924,103,'teal',16)
txt('МУЛЬТИПЛЕЕР ПО ЖЕЛАНИЮ. ЛИЧНЫЙ ПРОГРЕСС ПО УМОЛЧАНИЮ.',76,139,17,True,'paper')
para('Игра должна быть увлекательной для одиночного путешествия и одновременно давать естественные причины собраться ради живой музыки.',76,122,866,55,14,'cream')
end()

# 03 lore
top('02 / мир и лор','Не катастрофа. Потерянный ритм.','Город разрушило не зло; он постепенно перестал слышать и создавать.')
card(50,286,446,180,'01 · Эпоха Воспроизведения','Удобные системы делали всё за людей. Песни звучали бесконечно, но всё реже кто-то сочинял сам. Улицы переполнил фон, не объединяющий никого.','faded',bsize=13.5)
card(523,286,451,180,'02 · Великая Пауза','Закрылись площадки, кружки, книжные лавки и репетиционные. Работы откладывали, проекты не заканчивали. Город стал блеклым, хотя остался безопасным.','coral',bsize=13.5)
card(50,80,446,180,'03 · Сигнал у набережной','Старый радиоприёмник в LoopVan ловит обрывок мелодии. Mica понимает: сеть городских ретрансляторов реагирует не на прослушивание, а на творческий вклад.','amber',bsize=13.5)
card(523,80,451,180,'04 · Новый резонанс','У каждой остановки собственный звук, у каждой истории — своё продолжение. Появляются сцены, жители и совместные выступления. Город снова становится общим делом.','mint',bsize=13.5)
end()

# 04 philosophy
top('03 / тон истории','Не обвиняем детей','Развивающая часть должна ощущаться следствием хорошей игры.')
card(50,86,445,382,'ЧТО МЫ ГОВОРИМ','«Людям трудно оставаться внимательными в мире мгновенных развлечений. Им не хватает поддержки, возможности ошибаться и совместного дела». Задачи дают безопасные примеры ответственности, заботы о пространстве, слушания и доведения идеи до результата.','amber',bsize=14)
card(518,86,454,382,'ЧЕГО НЕ ДЕЛАЕМ','Нет наказаний за выход из игры. Нет «плохих» детей, лекций о культуре, рейтингов «умный/глупый», социального давления или обязательных домашних заданий. Победа — творческий выбор и вклад в общее место, а не единственный правильный бит.','coral',bsize=14)
chip(70,95,200,'Любопытство','teal');chip(286,95,201,'Сотрудничество','teal');chip(538,95,190,'Самостоятельность','teal');chip(740,95,208,'Удовольствие','teal')
end()

# 05 city full initial (dedicated)
COUNT+=1;fill('dark');C.rect(0,0,W,H,fill=1,stroke=0);imagefit(M/'BeatMakka_City_Map_Initial_Locked.png',20,6,984,565)
txt('05',983,16,12,True,'paper',align='right');end()
# 06 master map
COUNT+=1;fill('dark');C.rect(0,0,W,H,fill=1,stroke=0);imagefit(M/'BeatMakka_City_Map_District_Master.png',20,6,984,565)
txt('06',983,16,12,True,'paper',align='right');end()

# 07 map unlock
top('04 / навигация','Карта открывается сигналами','Все районы видны с первого захода; доступным остаётся только первый.')
for x,t,desc,c in [(50,'LOCKED','Контур и замок. Телепорт отклоняется сервером.','#364849'),(286,'SIGNAL FOUND','Радиоподсказка и короткий музыкальный мотив.','#4C5E5B'),(522,'UNLOCKED','Район доступен; стримятся только необходимые ассеты.','#42675B'),(758,'RESTORED','Персональная история завершена, сцена оживлена.','#8B6846')]:
 rect(x,242,213,207,c,14)
 txt(t,x+17,405,17,True,'paper')
 para(desc,x+18,371,177,117,12,'paper')
 rect(x+70,265,71,25,'teal',9)
 for k in range(3 if t!='LOCKED' else 0):
  fill('amber');C.circle(x+87+k*17,277,4,fill=1,stroke=0)
rect(50,86,924,122,'ink',15)
txt('В ДЕМО',72,168,18,True,'amber')
para('Needle Quay открыт. Другие десять силуэтов существуют только как UI-регистр. Открытие стилевого банка и открытие района — разные права. Проекты и ранее выбранные звуки не пропадают при перемещении.',72,150,875,70,13,'cream')
end()

# District helpers
D=[('01','Needle Quay','Original starter','Старая гавань','Ритм, поиск звука, забота','Краны, дерево, мягкий металл, набережная','amber'),
   ('02','Velvet Canals','Trip Hop','Бархатные каналы','Внимание, пауза, текстура','Каналы, книжные лавки, дождевые крыши','#9883A6'),
   ('03','Motion Square','Dance','Площадь движения','Структура и движение','Павильоны, танцплощадь, световые ленты','#CCAB69'),
   ('04','Broken Amp Row','Grunge','Улица усилителей','Ошибки и самовыражение','Гаражи, постеры, репетиционные','#B57972'),
   ('05','Hyperspan','Hard Trance','Высотная магистраль','Концентрация и темп','Мосты, станции, холодная подсветка','#88A9CB'),
   ('06','Rhythm Borough','Hip Hop','Ритм-квартал','Рифма и совместность','Скейт-дворы, муралы, локальные сцены','coral'),
   ('07','Iron Bell Works','Industrial','Железные мастерские','Физика звука и система','Шестерни, механические ударные','#A9957C'),
   ('08','Starlight Arcade','Pop','Аркада звёздного света','Мелодия и эмоция','Ретро-кинотеатр, магазин, огни','#DB9FAD'),
   ('09','Sunward Strand','Reggae','Солнечный берег','Offbeat и уважение к другим','Пляж, тенистые навесы, мягкая вода','#D1BA79'),
   ('10','Circuit Ward','Techno','Схемный район','Алгоритм и циклы','Энергосети, модули, лупы','#76BAA5'),
   ('11','Aurora Heights','Trance','Высоты Авроры','Длинная форма и развитие','Обсерватория, ступени, утренние огни','#AB9DC9')]
def district_card(x,y,w,h,a):
 num,name,kit,ru,lesson,world,accent=a
 rect(x,y,w,h,'fog',14,edge='#45615B')
 fill(P.get(accent,accent));C.roundRect(x+13,y+14,8,h-28,4,fill=1,stroke=0)
 txt(num,x+38,y+h-44,22,True,accent)
 # Separate title line prevents the district number from colliding with its name.
 txt(name,x+37,y+h-73,13.6,True,'paper')
 txt(kit,x+37,y+h-100,11.8,True,'amber')
 para(ru,x+36,y+h-119,w-60,30,11.5,'mint')
 para(lesson,x+36,y+h-161,w-60,48,11.5,'cream')
 para(world,x+36,y+h-221,w-60,70,11,'cream')
 idx=int(num);base=y+79
 # Each district's own signal texture: wave frequency and envelope, not a literal PCM analysis.
 stroke(accent);C.setLineWidth(1.8)
 pts=[]
 for j in range(62):
  px=x+38+(w-77)*j/61
  env=.5+.5*math.cos((j-30)*math.pi/60)
  py=base+18*env*math.sin(j*(.25+.022*idx))
  pts.append((px,py))
 for j in range(len(pts)-1):C.line(*pts[j],*pts[j+1])
 txt('DISTRICT SIGNAL',x+38,y+36,9,False,'faded')

# 08 01-04
top('05 / атлас районов','Четыре разных голоса','Своя география, один общий визуальный язык.')
for i,x in enumerate((50,286,522,758)):
 district_card(x,85,213,381,D[i])
end()
# 09 05-08
top('06 / атлас районов','От скоростей к мелодии','Музыкальные упражнения живут в архитектуре и историях.')
for i,x in enumerate((50,286,522,758)):
 district_card(x,85,213,381,D[4+i])
end()
# 10 09-11
top('07 / атлас районов','Берег, схемы и небеса','Последние три темы: пространство, алгоритм, музыкальная дуга.')
for i,x in enumerate((72,384,696)):
 district_card(x,124,257,343,D[8+i])
rect(90,72,844,39,'teal',9)
txt('Ключ: не строить эти районы до завершённого playable vertical slice Needle Quay.',112,85,11.5,False,'paper')
end()

# 11 accurate pack table
top('08 / звуковые стили','11 банков · 16 пэдов каждый','Музыкальная карта — это культурный алфавит города, не список обязательных DLC.')
from itertools import zip_longest
rows=[('Original starter','—','обычный старт'),('Trip Hop','Am · 90','Velvet Canals'),('Dance','Am · 140','Motion Square'),('Grunge','Dm · 90','Broken Amp Row'),('Hard Trance','Am · 140','Hyperspan'),('Hip Hop','Am · 90','Rhythm Borough'),('Industrial','Am · 140','Iron Bell Works'),('Pop','D · 90','Starlight Arcade'),('Reggae','Am · 90','Sunward Strand'),('Techno','Am · 140','Circuit Ward'),('Trance','Am · 140','Aurora Heights')]
for i,(nm,key,zone) in enumerate(rows):
 column=0 if i<6 else 1;line=i if column==0 else i-6;x=52+column*467;y=414-line*53
 rect(x,y,437,51,'fog',9)
 txt(nm,x+18,y+27,13.5,True,'paper');txt(key,x+214,y+29,12,True,'amber')
 txt(zone,x+215,y+11,10,'faded')
rect(52,63,920,75,'teal',12)
para('Реальная граница на 24.10: 160 подготовленных жанровых WAV → 100 имеют Roblox IDs, 60 ожидают; 24 оригинальных аудиофайла ещё не привязаны в приватной experience. Появление имени банка не означает готовность hosted playback.',75,125,871,56,12.5,'paper')
end()

# 12 palette
top('09 / визуальная грамматика','Один материальный язык','Нынешние дизайн-токены MK-I сохранены; районы получают только тематические акценты.')
colors=[('PAPER','#F5EEDC'),('CREAM','#E8D8B7'),('TEAL','#2F5C58'),('FADED','#6F9186'),('AMBER','#F3B65F'),('CORAL','#CA7453'),('WALNUT','#79513B'),('STONE','#B79C7E'),('GRAPHITE','#2C3031'),('SCREEN','#101B1A')]
for i,(nm,hx) in enumerate(colors):
 col=i%5;row=i//5;x=50+col*188;y=306-row*141
 rect(x,y,176,120,'fog',10)
 rect(x+8,y+43,160,67,hx,8)
 txt(nm,x+10,y+24,13,True,'paper')
 txt(hx,x+105,y+24,11,False,'cream')
rect(50,95,924,42,'ink',10)
txt('ATLAS 4×4 / 16 ROLES     ·     UV: FZ_MaterialAtlas_v1     ·     MAPS: 1024 / 512',71,109,12,True,'amber')
end()

# 13 style rules
top('10 / арт-система','Изменяется район, не продукт','Тематичность — в силуэте и освещении, а не в бесконечном количестве текстур.')
card(51,279,441,190,'Общая архитектура','Округлённые уголки и массивный деревянный каркас. Порталы по модульной сетке 4/8 studs. В общественных местах — читаемые зоны подхода и широкие проходы.','amber',bsize=13)
card(517,279,453,190,'Разные жанры','Reggae: пальмы и тень; Industrial: крановые фермы; Hip Hop: яркие муралы; Techno: повторяющиеся световые панели; Trance: горизонт и дальние огни. Без жанровых стереотипов о жителях.','coral',bsize=12.8)
card(51,74,441,181,'Свет без принуждения','Никогда не передавать сюжетную информацию только свечением. При Effects OFF остаются вывеска, цвет, NPC-поза, статические состояния. Низкий графический пресет — полноценная игра.','mint',bsize=12.8)
card(517,74,453,181,'Текст остаётся в UI','Интерактивные лейблы, язык и статусы native. Не запекать мелкий текст в albedo. Все 16 пэдов фиксированы, на мобильных экранах музыкальные органы управления не уезжают при свайпе.','amber',bsize=12.8)
end()

# 14 restoration
COUNT+=1;fill('dark');C.rect(0,0,W,H,fill=1,stroke=0);imagefit(M/'BeatMakka_Restoration_States.png',22,38,980,482)
txt('14  /  PERSONAL WORLD STATE — ART DIRECTION ONLY',61,24,11,True,'amber');end()

# 15 van concept
COUNT+=1;fill('dark');C.rect(0,0,W,H,fill=1,stroke=0);imagefit(M/'BeatMakka_LoopVan_Concept.png',22,40,980,515)
txt('15  /  LOOPVAN-01 — ART CONCEPT. НЕ ИГРОВАЯ MESH.',61,20,11,True,'amber');end()

# 16 van modes
top('11 / мобильный дом','Фургон — игровая система','Не второе меню и не декоративный транспорт.')
for i,(nm,head,body) in enumerate([
 ('01','TRAVEL','Между отмеченными парковками — короткий cinematic переход. Физическая управляемая машина не входит в демо.'),
 ('02','HOME','Внутри остаются MK-I, 4 паттерна, Beat Shelf, звукобиблиотека и личный каталог косметики.'),
 ('03','SAMPLE LAB','Превью игрового звука, сравнение timbre и gain, назначение на пэд. Без записи микрофона.'),
 ('04','MINI STAGE','Откидной тент, сцена и добровольное прослушивание. Используем один StageQueue/ListeningSession.')]):
  x=50+(i%2)*470;y=278-(i//2)*196
  rect(x,y,448,176,'fog',16)
  chip(x+20,y+120,48,nm,'teal')
  txt(head,x+82,y+129,17,True,'paper')
  para(body,x+24,y+95,390,85,13,'cream')
end()

# 17 blueprint
# 17 van space model
top('12 / пространственный контракт','Внутренность и парковка','Габариты ниже — авторское предложение для whitebox, не финальная Roblox-сборка.')
rect(49,84,566,387,'fog',14)
# parked van plan, schematic
rect(108,158,390,226,'cream',35)
rect(126,178,100,186,'teal',20)
txt('CAB',171,275,15,True,'paper',align='center')
rect(248,288,176,63,'teal',10)
txt('MK-I / 16 PAD',337,312,15,True,'paper',align='center')
rect(248,213,176,55,'walnut',10)
txt('SHELF / SOUNDS',336,232,13,True,'paper',align='center')
rect(436,201,44,150,'coral',8)
rect(503,201,50,150,'teal',8)
txt('СЦЕНА',528,177,10,True,'cream',align='center')
# Dimension lines
thinpath([(110,406),(496,406)],'amber',2)
txt('~22 STUDS — ПРОВЕРИТЬ КАМЕРОЙ',302,419,11,True,'amber',align='center')
thinpath([(84,166),(84,380)],'amber',2)
txt('~9',63,281,12,True,'amber')
card(639,278,334,194,'ПАРКОВКА','Четыре fixed sockets. В демо только teleport/fade между точками, а не непрерывная физика транспорта. Проверить clearance для персонажа и сцену без блокировки прохода.','amber',bsize=12)
card(639,85,334,172,'INTERIOR / RIGHTS','Сохраняется личная косметика и музыкальные проекты; вход только владельцу в первом демо. Shared workshop H06 остаётся общественной локацией.','coral',bsize=12)
end()

# 18 neighborhood map
COUNT+=1;fill('dark');C.rect(0,0,W,H,fill=1,stroke=0);imagefit(M/'BeatMakka_Needle_Quay_Demo_Map.png',20,6,984,565)
txt('18',983,16,12,True,'paper',align='right');end()

# 19 parking P1 and P2
top('13 / playable stop I','Первая пара парковок','Каждый запрос даёт конкретное творческое действие, новую находку и мини-публику.')
card(49,253,443,215,'P1 · DOCKSIDE EXCHANGE','Место: причал и деревянные ящики. Тори просит упорядочить инструменты и «включить» ритм погрузки. Игрок открывает I01 metal_hit, собирает 4 удара и доводит цикл до конца. Мир отвечает светом киоска и NPC.','amber',bsize=12.8)
card(514,253,459,215,'P2 · REPAIR ALLEY','Место: вентиляция и ремзона. Иво показывает простую цепочку: удар → колебание → звук. Игрок находит I02 vent_thump и делает вариацию из уже сохранённого A. Мир отвечает работающей мастерской и механическими световыми акцентами.','coral',bsize=12.8)
rect(49,91,924,126,'teal',13)
txt('ПРОГРЕСС НЕ ЗА ЗРИТЕЛЕЙ',73,178,17,True,'paper')
para('Достаточно проверенной последовательности действий и сохранения результата. Если на мини-концерт никто не пришёл, локальные NPC слушают, а награда остаётся доступной. Нельзя выдать звук простым клиенским запросом.',73,160,866,64,13.2,'paper')
end()

# 20 P3 and P4
top('14 / playable stop II','Вторая пара парковок','Система остаётся понятной в одиночку; совместное творчество добавляет радость.')
card(49,253,443,215,'P3 · VINYL MARKET','Место: рынок пластинок и сообщество коллекционеров. Ная помогает рассортировать 16 пэдов по ролям: ритм, бас, мелодия. Задание — сделать A/B-версию, сохранить beat shelf и не потерять исходник. Слышится небольшой Trip Hop-тизер.','amber',bsize=12.8)
card(514,253,459,215,'P4 · BREAKWATER STEPS','Место: волнорез и приглушённый маяк. Mica даёт знакомый I03 robot_chirp. Игрок собирает музыкальный вопрос/ответ между паттернами, слушает паузу и готовит финальный сет. Загорается локальный радиоретранслятор.','mint',bsize=12.8)
rect(49,91,924,126,'teal',13)
txt('СИЛЬНАЯ СВЯЗЬ С МУЗЫКОЙ',73,178,17,True,'paper')
para('Сортировка → тембры. Вариации → форма. Паузы → композиция. Совместная очередь → уважение чужого выступления. Эти знания возникают из действий, а не из отдельного экзамена.',73,159,866,64,13.3,'paper')
end()

# 21 finale
top('15 / сюжетный концерт','THE LANTERN ROOM','Не «финальный босс игры», а возвращение одного района к жизни.')
card(50,254,407,210,'Хранитель Паузы','Смотритель клуба давно перестал приглашать музыкантов: многие обещали и не доводили дела до конца. Игрок показывает уже собранные звуки, подготовленный сет и возвращённых жителей. Смотритель не злодей — он снова учится доверять.','coral',bsize=12.3)
card(481,254,490,210,'Шесть фаз (reuse)','1. Подготовка / 2. Ударные / 3. Бас / 4. Вариация / 5. Реакция жителей / 6. Финальный подъём. Фазы привязаны к освоенным действиям и сохранённым паттернам, без единственного правильного трека.','amber',bsize=13.2)
rect(50,85,921,126,'teal',14)
txt('РАЙОН ОТКРЫТ. ГОРОД ЕЩЁ ЖДЁТ.',75,170,19,True,'paper')
para('В конце вспыхивает маяк, открывается The Lantern Room, личный статус Needle Quay становится Restored, а карта начинает показывать следующий «сигнал». Другие десять районов пока остаются закрытыми для перемещения.',75,150,870,70,13,'paper')
end()

# 22 sounds
top('16 / игровые звуки','Где звук рождается, там и история','Микрофон не нужен для хорошей детской музыкальной игры.')
items=[('ИССЛЕДУЙ','Слышен предмет: знак, труба, робот.'),('ПРОВЕРЬ','Есть безопасное Preview и происхождение.'),('СОБЕРИ','Сервер отмечает находку и право на звук.'),('ИГРАЙ','Выбери пэд и запиши собственный паттерн.')]
for i,(t,b) in enumerate(items):
 x=46+i*247
 card(x,213,226,254,t,b,['amber','coral','mint','amber'][i],bsize=13.7)
 if i<3:txt('→',x+229,321,24,True,'amber')
rect(49,82,924,105,'ink',12)
para('Визуальный «рекордер» выбирает только подготовленные игровые звуки. Он не захватывает голос/PCM ребёнка, не обещает сохранение WAV и не требует загрузки через внешний сайт. Любая физическая запись — новый research после появления платформенной поддержки и правил модерации.',70,163,882,69,13,'cream')
end()

# 23 sound lab
# 23 laboratory
top('17 / развивающий инструмент','Sound Lab без лекций','Простые органы управления. Причина и слышимое следствие.')
rect(49,219,580,249,'fog',16)
txt('Громкость / Огибающая / Высота',71,426,18,True,'paper')
# oscilloscope baseline
stroke('faded');C.setLineWidth(1);C.line(81,308,601,308)
for j in range(11):
 x=83+j*50
 stroke('#405C56');C.line(x,274,x,367)
coords=[]
for j in range(200):
 x=80+j*2.6;pos=j/199
 env=min(1,pos*9) * math.exp(-3.8*pos)
 y=308+env*44*math.sin(pos*math.pi*22)
 coords.append((x,y))
for i in range(len(coords)-1):thinpath([coords[i],coords[i+1]],'amber',1.7)
txt('SOURCE',83,254,12,True,'mint');txt('ATTACK',245,254,12,True,'mint');txt('DECAY',495,254,12,True,'mint')
card(656,285,316,182,'PLAYBACK MODIFIERS','Для демо — preview заранее подготовленных файлов и доступные в Roblox регуляторы playback. Показывать отдельно, что tempo/pitch и новый звук не одно и то же.','amber',bsize=12.6)
rect(49,82,923,110,'teal',13)
para('Не обещаем полноценный синтезатор или экспорт нового аудиофайла с клиента, пока нет платформенной реализации. Визуальная волна и спектр демонстрационные, если они не вычислены из реального PCM. Настоящие звуковые операции отмечаются соответствующими API и тестами.',72,171,866,71,13,'paper')
end()

# 24 systems learning
top('18 / обучающая прогрессия','Навык спрятан в творческом процессе','Три масштаба прогресса: микро, локальный, городской.')
card(49,265,294,200,'МИКРО · 1–3 минуты','Услышать разницу между kick и snare; вернуть паузу; поставить четыре шага; сравнить два тембра; записать короткую вариацию. Вознаграждается открытие, а не идеальная оценка.','amber',bsize=12.7)
card(365,265,294,200,'ЛОКАЛЬНО · парковка','Помочь NPC закончить дело, найти особый звук, сыграть небольшой сет. Мир наглядно меняется: вывеска, свет, жители, новая возможность.','coral',bsize=12.8)
card(681,265,294,200,'МЕТА · район','Вернуть клуб, подключить радиосигнал, открыть следующий контур города. У игрока остаются фургон, музыка, навыки и личные выборы.','mint',bsize=12.8)
rect(49,86,924,145,'ink',14)
txt('НАСТОЯЩАЯ ПЕДАГОГИКА БЕЗ ШКОЛЬНОЙ ОБОЛОЧКИ',72,187,16.5,True,'amber')
para('Внимание → различение звуков; повторение → устойчивый метр; завершение → ответственность; совместный сет → умение слушать другого; вариация → творческое мышление. Не нужно встраивать оценки IQ, тесты, штрафы или таймеры наказаний.',72,165,869,72,13.2,'cream')
end()

# 25 multiplayer architecture
top('19 / social + solo','Один район, разные судьбы','Город общий; глава, музыка и личный фургон принадлежат каждому.')
rect(51,245,920,222,'fog',16)
chip(84,407,266,'SERVER AUTHORITY','teal')
chip(390,407,230,'PUBLIC SCENE','teal')
chip(662,407,256,'PERSONAL CLIENT','teal')
para('Завершение миссий, право на звук, парковка, очереди и версии сохранений.',88,381,257,98,12.4,'cream')
para('Площади, NPC, сцены, доступные подсказки, присутствие игроков.',394,381,222,98,12.4,'cream')
para('Вариации музыки, стейт района, звук, доступный микс и FX.',663,381,246,98,12.4,'cream')
for x in [355,626]:txt('↔',x,340,24,True,'amber')
card(51,82,445,139,'SOLO','NPC аудитория всегда доступна. Никаких обязательных слушателей, друзей или чата.','amber',bsize=12.3)
card(518,82,453,139,'MULTIPLAYER','Opt-in слушание, ограниченная очередь мини-концертов, mute/leave сразу. Независимый jam — будущая отдельная feature.','coral',bsize=12.3)
end()

# 26 Map UI mock
top('20 / карта игрока','Управление без бесконечных меню','Стартовая карта и информационная карточка выбранного района.')
rect(50,82,561,378,'fog',18)
# mini map stylized circles
for (x,y,label_,col) in [(159,330,'01','amber'),(294,376,'02','faded'),(396,265,'03','faded'),(176,190,'04','faded'),(505,350,'05','faded'),(467,159,'06','faded')]:
 fill(col);C.circle(x,y,30,fill=1,stroke=0)
 txt(label_,x,y-5,12,True,'dark',align='center')
for (p1,p2) in [((159,330),(294,376)),((294,376),(396,265)),((159,330),(176,190)),((396,265),(505,350)),((396,265),(467,159))]:thinpath([p1,p2],'faded',1.2)
rect(643,82,328,378,'ink',18)
chip(662,412,79,'01','amber','dark')
txt('NEEDLE QUAY',757,419,14.3,True,'paper')
para('Старая гавань. Первый район. Портовая история, четыре парковки и клуб The Lantern Room.',670,385,278,106,12.5,'cream')
chip(669,213,273,'ПОЕХАТЬ К ПАРКОВКЕ','teal','paper',11.2)
chip(669,170,273,'ПОСМОТРЕТЬ НАХОДКИ','teal','paper',11.1)
chip(669,127,273,'ЗАКРЫТЬ КАРТУ','graphite','paper',11.2)
txt('В макете остальные районы не доступны.',664,95,9.5,False,'faded')
end()

# 27 asset crosswalk
top('21 / производственный реестр','74 существующих ID не выбрасываем','Новые концепты фургона получают собственную namespace V01–V09.')
rows=[('H01–H06','MK-I, speakers, records, Mica, lights, workshop'),('M01–M18','модульные стены, проходы, roof, railings'),('P01–P16','мебель, racks, plants, vent, cables'),('I01–I05','доступные звуки, восстановление, podium'),('W01–W04','courtyard, вода, skyline, bridge'),('T01–T04 + G01–G04','материалы и графика'),('A01–A05 + F01–F04','анимации, свет, эффекты'),('U01–U04 + S01–S04','native UI и аудио-библиотеки')]
for i,(a,b) in enumerate(rows):
 y=427-i*43
 rect(51,y,920,38,'fog',8)
 txt(a,72,y+12,12.3,True,'amber')
 txt(b,290,y+12,12,False,'cream')
rect(50,61,923,55,'teal',10)
para('Pipeline: CANDIDATE → DCC-CLEAN → ART-APPROVED → STUDIO-IMPORTED → RUNTIME-VERIFIED. SVG/PNG и этот артбук не являются импортом в Roblox.',69,103,872,43,11.6,'paper')
end()

# 28 migration / schema
top('22 / совместимость','Не переписывать работающий продукт','Фургон вводится адаптером вокруг MK-I, ProfileStore и StageQueue.')
card(49,286,440,182,'СОХРАНЯЕМ','4 паттерна A–D · 6 проектов shelf · 16×16 шагов · I01/I02/I03 · текущие audio/image IDs · оригинальные room finishes · персональный Mica quest · существующие prompts.','amber',bsize=13)
card(517,286,456,182,'ДОБАВЛЯЕМ','DistrictRegistry · CityMapView · VanService · parking anchors · episodic quest recipes · map progression · van appearance renderer · четвёрку мини-сцен и Lantern Room.','coral',bsize=13)
card(49,87,440,175,'ПРОФИЛЬ / CLOUD','Существующий room → новый vanAppearance через версионированную миграцию. Не теряем прежние байты, проверяем future schema, конфликт сохранений и возврат старого билда.','mint',bsize=12.8)
card(517,87,456,175,'STUDIO / HARDWARE','Только реальная приватная experience подтверждает cloud rejoin; только импортированный mesh, сохранённый и переоткрытый, становится Studio accepted. Симулятор не заменяет физический multitouch.','amber',bsize=12.8)
end()

# 29 batches
top('23 / dev roadmap','Рабочие батчи B0–B8','Большие связные изменения → целевая проверка → итоговая сборка.')
B=[('B0','Freeze contracts','P0'),('B1','Map / 11 locked IDs','P0'),('B2','LoopVan + room adapter','P0'),('B3','Four parking stages','P0'),('B4','P1 + P2 / sound lab','P0'),('B5','P3 + P4 / restoration','P1'),('B6','Lantern Room finale','P1'),('B7','Hosted audio / cloud / meshes','GATE'),('B8','Physical UX / acceptance','GATE')]
for i,(bid,body,tier) in enumerate(B):
 col=i%3;row=i//3;x=49+col*314;y=361-row*124
 rect(x,y,293,110,'fog',10)
 txt(bid,x+18,y+60,23,True,'amber')
 txt(tier,x+236,y+68,12,True,'mint')
 para(body,x+19,y+47,250,45,12.5,'cream')
end()

# 30 blockers
top('24 / технические риски','Не выдавать прототип за релиз','Честная граница проекта на 24 октября 2026.')
card(51,293,446,173,'HOSTED AUDIO','100/160 genre IDs есть у владельца, но private-experience permissions не подтверждены. Остальные 60 и 24 исходных WAV ещё ждут. Звуковую драматургию без слышимого аудио принимать нельзя.','coral',bsize=12.5)
card(521,293,450,173,'PERSISTENCE / CLOUD','Текущий локальный PlaceId/UniverseId = 0 по последнему аудиту. Сценарии save/conflict проверяли session/injected storage. Нужен настоящий private rejoin и rollback.','amber',bsize=12.5)
card(51,95,446,174,'NATIVE ART','Оптимизированные GLB и temporary previews не доказывают постоянный импорт. Проверить pivot/atlas/rig/collision и сохранение после reopen.','mint',bsize=12.5)
card(521,95,450,174,'KIDS / RIGHTS / TIMING','Нет доказанных physical touch latency budgets или независимого разрешения freeware на sampler redistribution. AudioRecorder у Roblox не включён. Никаких ложных обещаний.','coral',bsize=12.5)
end()

# 31 QA
top('25 / готовность демо','Definition of Done','Не закрывать этап по количеству строк кода или красивому рендеру.')
checks=[('01','Первый бит слышен без помощи разработчика.'),('02','Четыре парковки и финал проходят соло.'),('03','Фургон меняет место; личные A–D/shelf целы.'),('04','Чужие игроки не меняют progress и home.'),('05','Нет микрофона, свободного WAV и обязательного чата.'),('06','Cloud rejoin прошёл на приватной experience.'),('07','Статусы assets подтверждены native import/reopen.'),('08','Телефон, gamepad/keyboard и эффекты OFF проверены.')]
for i,(n,t) in enumerate(checks):
 x=53+(i//4)*472;y=422-(i%4)*85
 rect(x,y,438,70,'fog',10)
 chip(x+11,y+21,51,n,'teal')
 para(t,x+79,y+55,340,48,12.1,'cream')
end()

# 32 credits/status
top('26 / пакет передачи','Документировать. Создавать. Проверять.','World Artbook v2.0 — новая концептуальная редакция, дополнение к утверждённому MK-I.')
card(50,263,445,206,'В ПАКЕТЕ','Карта города: 11 районов / начальные замки. Полная мастер-карта. Карта демо Needle Quay. Концепт LoopVan-01 и визуальные состояния восстановления. District registry JSON, SVG-исходники и подробный технический план.','amber',bsize=12.9)
card(520,263,454,206,'ЕЩЁ НЕ СДЕЛАНО В ROBLOX','Новая география 11 районов, физическая сцена фургона, весь content лицензирования/hosted audio, cloud rejoin, постоянный mesh import и human mobile playtest. Это задачи следующего этапа, а не результат PDF.','coral',bsize=12.9)
rect(50,84,924,146,'teal',14)
txt('ИСТОЧНИКИ',74,190,18,True,'paper')
para('BeatMakka/main: README, Visual Artbook v0.2, Production Atlas v0.2, MK-I Alpha 01 (36 страниц), approved Needle Quay style board, docs/STYLE_STARTER_PACKS.md, docs/IMPLEMENTATION_COVERAGE.md, docs/MATERIAL_CUSTOMIZATION.md и PENDING_VERIFICATION_2026-10-24.md. Подробные прямые ссылки приведены в плане.',74,168,871,83,11.5,'paper')
end()

C.save()
print('artbook pages',COUNT, 'warnings',len(WARN))
for w in WARN[:50]:print('WARN',w)
print('PDF',OUT,OUT.stat().st_size)
