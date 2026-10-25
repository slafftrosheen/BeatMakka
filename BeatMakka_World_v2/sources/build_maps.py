from pathlib import Path
import json, random, math, html
from scipy.spatial import Voronoi
from shapely.geometry import Polygon, Point, MultiPoint
from shapely.ops import voronoi_diagram
import cairosvg

OUT = Path(__file__).resolve().parents[1]
MP = OUT/'maps'; MP.mkdir(exist_ok=True)
COL={'ink':'#162322','dark':'#101C1D','screen':'#101B1A','teal':'#2F5C58','faded':'#6F9186','amber':'#F3B65F','coral':'#CA7453','paper':'#F5EEDC','cream':'#E8D8B7','white':'#FAF4E6','walnut':'#79513B','stone':'#B79C7E','graphite':'#2C3031','sea':'#17434B','line':'#91A79A','mute':'#52645D'}
DISTRICTS=[
 {'id':'NQ','number':1,'name':'Needle Quay','ru':'Старая гавань','kit':'Original starter','focus':'Ритм, поиск звука, ответственность','accent':'#F3B65F','xy':[330,1290],'unlock':'START','motif':'⚓'},
 {'id':'VC','number':2,'name':'Velvet Canals','ru':'Бархатные каналы','kit':'Trip Hop','focus':'Тишина, внимательное слушание','accent':'#9D839C','xy':[760,1090],'unlock':'LATER','motif':'◌'},
 {'id':'MS','number':3,'name':'Motion Square','ru':'Площадь движения','kit':'Dance','focus':'Структура, движение и энергия','accent':'#DAA668','xy':[1300,1130],'unlock':'LATER','motif':'◆'},
 {'id':'BA','number':4,'name':'Broken Amp Row','ru':'Улица старых усилителей','kit':'Grunge','focus':'Неидеальность и самовыражение','accent':'#B77D70','xy':[730,620],'unlock':'LATER','motif':'▱'},
 {'id':'HS','number':5,'name':'Hyperspan','ru':'Высотная магистраль','kit':'Hard Trance','focus':'Повторение, темп и концентрация','accent':'#87AFC8','xy':[1760,490],'unlock':'LATER','motif':'⌁'},
 {'id':'RB','number':6,'name':'Rhythm Borough','ru':'Ритм-квартал','kit':'Hip Hop','focus':'Рифма, импровизация и команда','accent':'#CA7453','xy':[1080,760],'unlock':'LATER','motif':'◎'},
 {'id':'IF','number':7,'name':'Iron Bell Works','ru':'Железные мастерские','kit':'Industrial','focus':'Физика звука, механизм и такт','accent':'#B89C73','xy':[320,550],'unlock':'LATER','motif':'⚙'},
 {'id':'SA','number':8,'name':'Starlight Arcade','ru':'Аркада звёздного света','kit':'Pop','focus':'Мелодия, эмоции и выразительность','accent':'#E5A1AD','xy':[1840,1190],'unlock':'LATER','motif':'★'},
 {'id':'SS','number':9,'name':'Sunward Strand','ru':'Солнечный берег','kit':'Reggae','focus':'Offbeat, пространство и дружба','accent':'#D5B76B','xy':[750,1480],'unlock':'LATER','motif':'☀'},
 {'id':'CW','number':10,'name':'Circuit Ward','ru':'Схемный район','kit':'Techno','focus':'Последовательности и системы','accent':'#69B2A7','xy':[1350,440],'unlock':'LATER','motif':'⬡'},
 {'id':'AH','number':11,'name':'Aurora Heights','ru':'Высоты Авроры','kit':'Trance','focus':'Длинная форма и развитие идеи','accent':'#B2A6C9','xy':[1920,230],'unlock':'LATER','motif':'✦'},
]
LAND=Polygon([(180,350),(460,208),(840,229),(1170,160),(1520,182),(1785,190),(2070,355),(2160,680),(2130,1080),(2020,1430),(1740,1590),(1440,1680),(1100,1600),(780,1710),(410,1580),(144,1390),(105,980)])
VOR=voronoi_diagram(MultiPoint([Point(*d['xy']) for d in DISTRICTS]), envelope=LAND.envelope)
for poly in VOR.geoms:
 c=poly.representative_point(); nearest=min(DISTRICTS,key=lambda d:c.distance(Point(*d['xy'])))
 nearest['geom']=poly.intersection(LAND)

def esc(s):return html.escape(str(s),quote=True)
def polystr(geom):
 if geom.is_empty:return ''
 if geom.geom_type=='MultiPolygon':
  geom=max(geom.geoms,key=lambda p:p.area)
 return ' '.join(f'{x:.1f},{y:.1f}' for x,y in geom.exterior.coords)
def lines_for_shape(geom):return '<polygon points="'+polystr(geom)+'"/>'
def svghead(w,h):
 return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
 <defs>
 <linearGradient id="sea" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#254E54"/><stop offset="1" stop-color="#091F27"/></linearGradient>
 <linearGradient id="base" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#1A3438"/><stop offset="1" stop-color="#102224"/></linearGradient>
 <linearGradient id="active" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#31645B"/><stop offset=".62" stop-color="#2F5C58"/><stop offset="1" stop-color="#6B5840"/></linearGradient>
 <pattern id="lines" width="24" height="24" patternUnits="userSpaceOnUse" patternTransform="rotate(35)"><path d="M0 0 L0 24" stroke="#94B3A6" stroke-opacity=".14" stroke-width="6"/></pattern>
 <pattern id="grid" width="90" height="90" patternUnits="userSpaceOnUse"><path d="M90 0 H0 V90" fill="none" stroke="#D8E1CA" stroke-opacity=".05" stroke-width="2"/></pattern>
 <filter id="glow"><feGaussianBlur stdDeviation="5"/></filter>
 </defs>
 '''

def city_svg(initial=True):
 W,H=3200,1950
 s=[svghead(W,H)]
 s+=['<rect width="3200" height="1950" fill="#0E1B1E"/>', '<rect x="20" y="190" width="2170" height="1620" rx="35" fill="url(#sea)"/>']
 # water contour and wave lines
 for i in range(47):
  x=70+((i*113)%2010); y=250+((i*71)%1490)
  s.append(f'<path d="M{x} {y} q24 -8 50 0" fill="none" stroke="#8CC5C0" opacity="{.06+.05*(i%3):.2f}" stroke-width="3"/>')
 s.append(f'<polygon points="{polystr(LAND)}" fill="#1C3334" stroke="#98B7A7" stroke-width="8"/>')
 for d in DISTRICTS:
  g=d['geom'];pts=polystr(g); active=(d['number']==1)
  fill='url(#active)' if active else ('#253638' if initial else d['accent'])
  op=1 if (active or initial) else .7
  s+= [f'<clipPath id="district_{d["id"]}"><polygon points="{pts}"/></clipPath>',
       f'<polygon points="{pts}" fill="{fill}" fill-opacity="{op}" stroke="#8CAEA2" stroke-opacity=".56" stroke-width="7"/>',
       f'<g clip-path="url(#district_{d["id"]})">']
  rand=random.Random(1000+d['number'])
  # city fabric
  for j in range(95):
   x,y=d['xy'];px=x+rand.uniform(-350,350);py=y+rand.uniform(-300,300)
   ww=rand.choice([21,28,33,42,60]);hh=rand.choice([15,22,28,37,52])
   fill='#8FAE9B' if active else ('#617577' if initial else '#2C4140')
   s.append(f'<rect x="{px:.0f}" y="{py:.0f}" width="{ww}" height="{hh}" rx="3" fill="{fill}" opacity="{.09+rand.random()*.17:.2f}" transform="rotate({rand.choice([0,0,0,-12,12])} {px+ww/2:.0f} {py+hh/2:.0f})"/>')
  if not active and initial:s.append(f'<rect x="0" y="180" width="2200" height="1580" fill="url(#lines)" opacity=".4"/>')
  s.append('</g>')
 # city arterial loops paths
 roads=["M170 1220 C600 1200 760 1020 1070 800 S1750 470 2080 430",
        "M360 420 C680 510 930 610 1070 800 S1570 1280 1960 1410",
        "M340 1530 C700 1330 1000 1220 1280 1100 S1800 900 2130 820",
        "M1410 220 C1320 460 1260 710 1280 1100 S1400 1500 1690 1610"]
 for p in roads:
  s.append(f'<path d="{p}" fill="none" stroke="#0B1A1E" stroke-width="23" stroke-linecap="round" opacity=".85"/>')
  s.append(f'<path d="{p}" fill="none" stroke="#87958C" stroke-width="6" stroke-dasharray="9 15" stroke-linecap="round" opacity=".43"/>')
 # sound relay rails
 s.append('<path d="M330 1290 C400 1060 640 1030 760 1090 C1000 1150 1110 880 1080 760" fill="none" stroke="#F3B65F" stroke-width="7" stroke-dasharray="20 20" opacity=".85"/>')
 # white fog overlay per polygon w transparent cover
 for d in DISTRICTS:
  if initial and d['number']>1:
   s.append(f'<polygon points="{polystr(d["geom"])}" fill="#0F1D21" opacity=".26"/>')
 # city landmark simplified icons
 for d in DISTRICTS:
  x,y=d['xy'];
  if d['id']=='AH': x,y=1940,320  # display icon within top map frame; Voronoi seed unchanged
  active=d['number']==1; c='#F3B65F' if active else ('#ADB6AA' if initial else '#132625')
  s.append(f'<circle cx="{x}" cy="{y}" r="73" fill="#0F1C1E" fill-opacity=".85" stroke="{c}" stroke-width="{8 if active else 3}" stroke-opacity="{1 if active else .7}"/>')
  if active:
   s.append(f'<circle cx="{x}" cy="{y}" r="87" fill="none" stroke="#F3B65F" stroke-opacity=".24" stroke-width="12"/>')
  else:
   s.append(f'<rect x="{x-15}" y="{y-3}" width="30" height="25" rx="5" stroke="{c}" stroke-width="5" fill="none"/>')
   s.append(f'<path d="M{x-10} {y-3}v-14 a10 10 0 0 1 20 0v14" fill="none" stroke="{c}" stroke-width="5"/>')
  s.append(f'<text x="{x}" y="{y+15 if active else y+48}" text-anchor="middle" fill="{c}" font-size="{59 if active else 31}" font-weight="800" font-family="DejaVu Sans">{d["number"]:02d}</text>' if active else '')
  # labels below icon
  labely=y+105
  s.append(f'<rect x="{x-137}" y="{labely-25}" width="274" height="70" rx="12" fill="#101B1D" opacity=".85"/>')
  s.append(f'<text x="{x}" y="{labely+3}" text-anchor="middle" font-size="23" font-weight="800" fill="{COL["paper"] if active else "#CED5CC"}" font-family="DejaVu Sans">{esc(d["name"])}</text>')
  s.append(f'<text x="{x}" y="{labely+33}" text-anchor="middle" font-size="20" fill="{COL["amber"] if active else "#8F9D95"}" font-family="DejaVu Sans">{esc(d["kit"])}</text>')
 # background ui header
 s += ['<rect x="30" y="22" width="3140" height="154" rx="18" fill="#182E30" stroke="#37524E" stroke-width="2"/>',
       '<text x="72" y="88" font-family="DejaVu Sans" font-size="59" font-weight="800" fill="#FAF4E6">RESONANCE CITY</text>',
       '<text x="72" y="133" font-family="DejaVu Sans" font-size="28" fill="#E8D8B7">КАРТА СИГНАЛОВ  /  11 РАЙОНОВ  /  ЧЕРЕЗ МУЗЫКУ — К ЖИЗНИ</text>',
       '<rect x="2260" y="208" width="902" height="1600" rx="24" fill="#1B2A2A" stroke="#59756D" stroke-width="3"/>',
       '<text x="2303" y="270" font-family="DejaVu Sans" font-size="32" font-weight="800" fill="#F5EEDC">РАЙОНЫ И ЗВУКОВЫЕ БАНКИ</text>']
 for i,d in enumerate(DISTRICTS):
  y=301+i*130
  active=d['number']==1
  bg='#355651' if active else '#203233'
  s.append(f'<rect x="2285" y="{y}" width="850" height="117" rx="15" fill="{bg}" stroke="{d["accent"] if active or not initial else "#455A59"}" stroke-opacity="{1 if active else .4}" stroke-width="{3 if active else 1}"/>')
  s.append(f'<circle cx="2346" cy="{y+56}" r="30" fill="{d["accent"] if active else "#52625F"}"/>')
  s.append(f'<text x="2346" y="{y+67}" text-anchor="middle" font-family="DejaVu Sans" font-size="27" font-weight="800" fill="#162322">{d["number"]:02d}</text>')
  s.append(f'<text x="2400" y="{y+50}" font-family="DejaVu Sans" font-size="29" font-weight="800" fill="#F5EEDC">{esc(d["name"])}</text>')
  s.append(f'<text x="2400" y="{y+85}" font-family="DejaVu Sans" font-size="24" fill="#AFC2B7">{esc(d["kit"])}  /  {"ДОСТУПЕН" if active else "ЗАКРЫТ" if initial else "КОНЦЕПТ"}</text>')
 s.append('<rect x="30" y="1840" width="3140" height="80" rx="15" fill="#182E30"/>')
 s.append(f'<text x="70" y="1890" font-family="DejaVu Sans" font-size="27" fill="#FAF4E6">{"НА СТАРТЕ: 01 открыт · 02–11 под туманом сигнала · жанровые основы доступны отдельно от районов" if initial else "АРТ-ДИРЕКШН: полный план города · индивидуальные жанры · общая материальная эстетика"}</text>')
 s.append('<text x="2070" y="1740" text-anchor="end" font-family="DejaVu Sans" font-size="21" fill="#BCD3CB">СХЕМАТИЧЕСКАЯ КАРТА · НЕ ГЕЙМПЛЕЙНЫЙ УРОВЕНЬ</text>')
 s.append('</svg>')
 return '\n'.join(s)

for initial,name in [(True,'BeatMakka_City_Map_Initial_Locked'),(False,'BeatMakka_City_Map_District_Master')]:
 svg=city_svg(initial)
 (MP/(name+'.svg')).write_text(svg,encoding='utf-8')
 cairosvg.svg2png(bytestring=svg.encode(),write_to=str(MP/(name+'.png')), output_width=3200,output_height=1950)
 print(name,len(svg))

# Detailed demo map
SITES=[
 {'id':'P1','en':'DOCKSIDE EXCHANGE','ru':'Портовый обмен','lesson':'Ритм и забота об инструментах','xy':(440,1260),'sound':'I01 · metal_hit','badge':'01'},
 {'id':'P2','en':'REPAIR ALLEY','ru':'Переулок мастерских','lesson':'Исследование звука и причин','xy':(970,620),'sound':'I02 · vent_thump','badge':'02'},
 {'id':'P3','en':'VINYL MARKET','ru':'Виниловый рынок','lesson':'Сотрудничество и структура','xy':(1840,950),'sound':'доп. звуки · Trip Hop','badge':'03'},
 {'id':'P4','en':'BREAKWATER STEPS','ru':'Ступени волнореза','lesson':'Слушание и вариации','xy':(1370,1510),'sound':'I03 · robot_chirp','badge':'04'},
]
def demo_svg():
 W,H=3200,1950
 s=[svghead(W,H),'<rect width="3200" height="1950" fill="#0E1B1E"/>','<rect x="22" y="190" width="2160" height="1630" rx="25" fill="url(#sea)"/>',
 '<path d="M155 330 Q770 190 1160 350 Q1750 230 2030 500 L2070 1150 Q1840 1430 1790 1760 L330 1710 Q70 1410 155 330" fill="#48635B" stroke="#B7B498" stroke-width="7"/>']
 # roads
 roads=["M400 1250 Q570 870 970 620 Q1350 470 1840 950 Q1660 1270 1370 1510", "M970 620 Q1260 340 1840 450"]
 for p in roads:
  s.append(f'<path d="{p}" fill="none" stroke="#223537" stroke-width="86" stroke-linecap="round"/>')
  s.append(f'<path d="{p}" fill="none" stroke="#B7A88C" stroke-opacity=".65" stroke-width="6" stroke-dasharray="28 23"/>')
 # bottom pier wooden
 for i in range(9):
  x=230+i*120
  s.append(f'<rect x="{x}" y="1530" width="75" height="340" rx="7" fill="#76533E" opacity=".6"/>')
 # buildings
 rnd=random.Random(22)
 for i in range(190):
  x=rnd.uniform(220,1910);y=rnd.uniform(300,1580)
  w=rnd.choice([20,38,52,75]);h=rnd.choice([22,37,50,73]);
  # avoid important node labels and roads approximated
  if any(math.hypot(x-p['xy'][0],y-p['xy'][1])<180 for p in SITES):continue
  if abs(y - (1250-(x-400)*.7))<90:continue
  s.append(f'<rect x="{x:.0f}" y="{y:.0f}" width="{w}" height="{h}" rx="4" fill="{rnd.choice(["#2F5C58","#516F62","#6B5B47","#765B47"])}" stroke="#789186" stroke-opacity=".5" stroke-width="2"/>')
 # piers, lighthouse, shops visual
 s += ['<rect x="148" y="890" width="170" height="350" rx="10" fill="#7B5C43"/>','<rect x="195" y="790" width="76" height="200" rx="7" fill="#8A724F"/>',
       '<circle cx="1890" cy="440" r="103" fill="#DCC69D" stroke="#F3B65F" stroke-width="12"/>',
       '<path d="M1865 385 h45 l14 120 h-75 Z" fill="#F5EEDC"/>','<path d="M1852 382 l35 -65 l35 65z" fill="#CA7453"/>',
       '<circle cx="1887" cy="315" r="23" fill="#F3B65F"/>']
 # path arrows
 for idx,p in enumerate(SITES):
  x,y=p['xy'];s.append(f'<circle cx="{x}" cy="{y}" r="85" fill="#143C40" stroke="#F3B65F" stroke-width="10"/>')
  s.append(f'<text x="{x}" y="{y+24}" text-anchor="middle" font-family="DejaVu Sans" font-size="62" font-weight="800" fill="#FAF4E6">{idx+1}</text>')
  ly=y-115
  s.append(f'<rect x="{x-187}" y="{ly-70}" width="374" height="74" rx="12" fill="#152B2C" opacity=".95"/>')
  s.append(f'<text x="{x}" y="{ly-23}" text-anchor="middle" font-family="DejaVu Sans" font-size="27" font-weight="800" fill="#F5EEDC">{p["en"]}</text>')
 # intro van
 s += ['<rect x="346" y="1360" width="180" height="73" rx="19" fill="#E8D8B7" stroke="#F3B65F" stroke-width="6"/>',
       '<rect x="405" y="1341" width="70" height="40" rx="8" fill="#CA7453"/>',
       '<circle cx="390" cy="1438" r="22" fill="#162322" stroke="#E8D8B7" stroke-width="6"/>','<circle cx="479" cy="1438" r="22" fill="#162322" stroke="#E8D8B7" stroke-width="6"/>']
 # finale club marker
 s+=['<circle cx="1887" cy="440" r="170" fill="none" stroke="#F3B65F" stroke-width="9" stroke-dasharray="13 13"/>',
     '<rect x="1620" y="605" width="550" height="75" rx="15" fill="#152729"/>',
     '<text x="1895" y="652" text-anchor="middle" font-family="DejaVu Sans" font-weight="800" font-size="33" fill="#F3B65F">ФИНАЛ  ·  THE LANTERN ROOM</text>']
 # header + sidebar
 s+=['<rect x="30" y="24" width="3140" height="140" rx="18" fill="#1A3435" stroke="#59756D" stroke-width="2"/>',
     '<text x="70" y="87" font-family="DejaVu Sans" font-size="58" font-weight="800" fill="#FAF4E6">NEEDLE QUAY / СТАРАЯ ГАВАНЬ</text>',
     '<text x="70" y="133" font-family="DejaVu Sans" font-size="27" fill="#E8D8B7">ДЕМО-РАЙОН · 4 ПАРКОВКИ · 1 КЛУБ · ФУРГОН-СТУДИЯ</text>',
     '<rect x="2240" y="200" width="924" height="1610" rx="25" fill="#1C2D2D" stroke="#5C7770" stroke-width="3"/>']
 s.append('<text x="2292" y="270" font-family="DejaVu Sans" font-size="36" font-weight="800" fill="#F5EEDC">СЦЕНАРИЙ ДЕМО</text>')
 for i,p in enumerate(SITES):
  y=320+i*280
  s.append(f'<rect x="2274" y="{y}" width="856" height="241" rx="17" fill="#253B3B" stroke="#55766B" stroke-width="2"/>')
  s.append(f'<circle cx="2337" cy="{y+64}" r="38" fill="#F3B65F"/>')
  s.append(f'<text x="2337" y="{y+78}" text-anchor="middle" font-family="DejaVu Sans" font-weight="800" font-size="32" fill="#152323">{i+1}</text>')
  s.append(f'<text x="2398" y="{y+61}" font-family="DejaVu Sans" font-size="31" font-weight="800" fill="#FAF4E6">{esc(p["en"])}</text>')
  s.append(f'<text x="2308" y="{y+121}" font-family="DejaVu Sans" font-size="27" fill="#E8D8B7">{esc(p["ru"])}</text>')
  s.append(f'<text x="2308" y="{y+164}" font-family="DejaVu Sans" font-size="25" fill="#9DB9AD">{esc(p["lesson"])}</text>')
  s.append(f'<text x="2308" y="{y+206}" font-family="DejaVu Sans" font-size="24" fill="#F3B65F">{esc(p["sound"])}</text>')
 s+=['<rect x="2280" y="1480" width="844" height="280" rx="18" fill="#375C54"/>',
 '<text x="2313" y="1533" font-family="DejaVu Sans" font-size="32" font-weight="800" fill="#F5EEDC">ФИНАЛЬНЫЙ КЛУБ</text>',
 '<text x="2313" y="1590" font-family="DejaVu Sans" font-size="27" fill="#F3B65F">The Lantern Room</text>',
 '<text x="2313" y="1640" font-family="DejaVu Sans" font-size="24" fill="#FAF4E6">Собери сет · позови жителей · зажги маяк</text>',
 '<text x="2313" y="1690" font-family="DejaVu Sans" font-size="24" fill="#FAF4E6">6 музыкальных фаз · сюжетный NPC</text>']
 s+=['<rect x="30" y="1840" width="3140" height="82" rx="15" fill="#1A3435"/>',
 '<text x="70" y="1893" font-family="DejaVu Sans" font-size="27" fill="#F5EEDC">МАРШРУТ: знакомство → сбор → запись → мини-сцены → восстановление клуба. Порядок парковок в демо направляемый.</text>',
 '</svg>']
 return '\n'.join(s)
svg=demo_svg();(MP/'BeatMakka_Needle_Quay_Demo_Map.svg').write_text(svg,encoding='utf-8');cairosvg.svg2png(bytestring=svg.encode(),write_to=str(MP/'BeatMakka_Needle_Quay_Demo_Map.png'),output_width=3200,output_height=1950)
# machine-readable manifest only new conceptual map, no claim existing implementation
for d in DISTRICTS:
 d['design_stage']='CONCEPT'
 d['coords_illustrative']=d.pop('xy')
 d['polygon_illustrative']=[[round(x,1),round(y,1)] for x,y in (max(d['geom'].geoms,key=lambda z:z.area) if d['geom'].geom_type=='MultiPolygon' else d['geom']).exterior.coords]
 del d['geom']
meta={'version':'world-artbook-v2-concept','city':'Resonance City','game':'Frequency Zero / BeatMakka','district_count':11,'sound_bank_count':11,'kits_per_district_rule':'16 base pads per source bank, district rewards add to optional library without overwriting canonical IDs','initial_unlocked':['NQ'],'districts':DISTRICTS,'demo_parking_sites':SITES,'status':'ART-DIRECTION ONLY; not imported or shipped'}
(OUT/'docs'/'district_register.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
print('demo and manifest ready')
