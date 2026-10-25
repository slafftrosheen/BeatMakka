from pathlib import Path
import math,cairosvg
O=Path(__file__).resolve().parents[1];D=O/'maps'

def save(name,svg,w,h):
 (D/(name+'.svg')).write_text(svg,encoding='utf-8');cairosvg.svg2png(bytestring=svg.encode('utf-8'),write_to=str(D/(name+'.png')),output_width=w,output_height=h)
head='''<svg xmlns="http://www.w3.org/2000/svg" width="2600" height="1360" viewBox="0 0 2600 1360"><defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#152D2E"/><stop offset="1" stop-color="#1B4545"/></linearGradient><linearGradient id="metal" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#FAF4E6"/><stop offset="1" stop-color="#C6B89B"/></linearGradient><linearGradient id="teal" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#527E72"/><stop offset="1" stop-color="#274D4B"/></linearGradient></defs>'''
S=[head,'<rect width="2600" height="1360" rx="35" fill="url(#bg)"/>','<text x="100" y="126" font-family="DejaVu Sans" font-size="70" font-weight="800" fill="#F5EEDC">LOOPVAN-01</text>',
   '<text x="104" y="178" font-family="DejaVu Sans" font-size="32" fill="#D6C9AC">ДОМ · СТУДИЯ · МОБИЛЬНАЯ СЦЕНА</text>']
# baseline ground
S+=['<path d="M110 1030 H2460" stroke="#C5BCA6" stroke-width="11" stroke-linecap="round"/>',
 '<path d="M255 906 Q245 760 300 680 L475 480 Q555 424 690 424 L1820 424 Q2065 441 2125 653 L2195 766 V915 Z" fill="url(#metal)" stroke="#172E2D" stroke-width="21"/>',
 '<path d="M344 730 L525 501 H731 V730Z" fill="#2E585B" stroke="#2F4E4E" stroke-width="14"/>',
 '<path d="M772 487 H1360 V710 H772Z" fill="#CFE2DB" stroke="#355F5E" stroke-width="18"/>',
 '<path d="M1370 487 H1794 Q1930 495 1990 630 V710 H1370Z" fill="#AEC8C1" stroke="#355F5E" stroke-width="18"/>',
 '<path d="M255 758 H2190 V872 H255 Z" fill="#2F5C58"/>',
 '<path d="M650 775 H2030" stroke="#CA7453" stroke-width="28" stroke-linecap="round"/>',
 '<path d="M2080 758 V880" stroke="#F3B65F" stroke-width="17"/>',
 '<circle cx="603" cy="954" r="148" fill="#1E2528" stroke="#B4A58A" stroke-width="23"/>',
 '<circle cx="603" cy="954" r="80" fill="#879893" stroke="#E8D8B7" stroke-width="23"/>',
 '<circle cx="1813" cy="954" r="148" fill="#1E2528" stroke="#B4A58A" stroke-width="23"/>',
 '<circle cx="1813" cy="954" r="80" fill="#879893" stroke="#E8D8B7" stroke-width="23"/>']
# canopy fold-out
S+=['<path d="M760 435 L1440 300 L1950 348" fill="none" stroke="#F3B65F" stroke-width="22" stroke-linecap="round"/>',
 '<path d="M1440 300 L1375 432" stroke="#FAF4E6" stroke-width="10" stroke-dasharray="15 13"/>',
 '<path d="M1960 349 V710" stroke="#E8D8B7" stroke-width="13"/>',
 '<path d="M1110 904 L1530 904 L1460 1065 L1100 1065Z" fill="#79513B" stroke="#E8D8B7" stroke-width="12"/>']
# side main vinyl identity
S+=['<circle cx="1045" cy="823" r="75" fill="#152F30" stroke="#F3B65F" stroke-width="10"/>',
    '<circle cx="1045" cy="823" r="20" fill="#CA7453"/>',
    '<circle cx="1045" cy="823" r="48" fill="none" stroke="#F5EEDC" stroke-width="4" opacity=".4"/>',
    '<text x="1180" y="831" font-family="DejaVu Sans" font-size="56" font-weight="800" fill="#FAF4E6">BEATMAKKA</text>']
# rooftop modules
S+=['<rect x="950" y="378" width="210" height="54" rx="12" fill="#F3B65F" stroke="#162322" stroke-width="10"/>',
    '<rect x="1520" y="344" width="250" height="77" rx="14" fill="#2C3031" stroke="#E8D8B7" stroke-width="13"/>',
    '<circle cx="1596" cy="383" r="21" fill="#9EB4A7"/>','<circle cx="1688" cy="383" r="21" fill="#9EB4A7"/>',
    '<path d="M1062 372 V288" stroke="#F3B65F" stroke-width="12"/>','<circle cx="1062" cy="283" r="25" fill="#F3B65F"/>']
# annotations
for (x1,y1,x2,y2,tx,ty,lab) in [(1050,286,790,241,384,235,'Радиомачта: сюжетный ретранслятор'),(1660,350,1980,275,1960,226,'Быстрая концертная установка'),(1480,985,1840,1165,1850,1198,'Откидная мини-сцена'),(850,680,520,1080,278,1160,'Рабочее место MK-I внутри'),(1820,505,2170,454,2190,451,'Обзорный отсек')]:
 S+= [f'<path d="M{x1} {y1} L{x2} {y2}" stroke="#F3B65F" stroke-width="5" stroke-dasharray="16 10" fill="none"/>',f'<text x="{tx}" y="{ty}" font-family="DejaVu Sans" font-size="29" fill="#FAF4E6">{lab}</text>']
S += ['<text x="110" y="1310" font-family="DejaVu Sans" font-size="24" fill="#AFC7B9">ART CONCEPT · STOP-TO-STOP TRAVEL IN DEMO · NOT A PHYSICS-DRIVEN CAR</text>','</svg>']
save('BeatMakka_LoopVan_Concept','\n'.join(S),2600,1360)

# progression triptych
H=1280;W=2600
s=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
 '<rect width="2600" height="1280" fill="#101C1E"/>','<text x="70" y="105" font-family="DejaVu Sans" font-size="63" font-weight="800" fill="#F5EEDC">ГОРОД ОТВЕЧАЕТ НА ТВОРЧЕСТВО</text>',
 '<text x="70" y="153" font-family="DejaVu Sans" font-size="28" fill="#8DA79D">Один и тот же угол района: заглушён → пробуждается → снова живёт</text>']
states=[('01 / QUIET','#233B3B',0,'Свет есть, но улица пуста'),('02 / RECONNECT','#3A5952',1,'Появляются звуки и лица'),('03 / RESONATE','#4F7160',2,'Жители выходят и творят')]
for i,(title,color,stage,note) in enumerate(states):
 ox=70+i*830
 s.append(f'<rect x="{ox}" y="225" width="785" height="915" rx="26" fill="{color}" stroke="#6E8C80" stroke-width="4"/>')
 s.append(f'<text x="{ox+42}" y="{290}" font-family="DejaVu Sans" font-size="42" font-weight="800" fill="#F5EEDC">{title}</text>')
 # building skyline silhouettes
 for j in range(9):
  x=ox+55+j*75;bh=[340,420,375,480,300,390,440,320,375][j]
  s.append(f'<rect x="{x}" y="{880-bh}" width="58" height="{bh}" rx="8" fill="#142729" stroke="#82998A" stroke-width="3"/>')
  for wy in range(int((900-bh)//1)+42,855,53):
   if wy>900: break
   wc='#F3B65F' if stage>0 and (j+wy//53)%(3-stage)==0 else '#2F4645'
   s.append(f'<rect x="{x+15}" y="{wy}" width="18" height="27" rx="3" fill="{wc}"/>')
 # signal lines
 if stage>0:
  for k in range(stage+1):
   s.append(f'<path d="M{ox+100} {900-k*35} Q{ox+380} {690-k*45} {ox+700} {900-k*35}" fill="none" stroke="#F3B65F" stroke-width="{6+k*3}" opacity=".8"/>')
 if stage==2:
  for j in range(5):
   xx=ox+175+j*110
   s.append(f'<circle cx="{xx}" cy="955" r="20" fill="#F3B65F"/>')
   s.append(f'<path d="M{xx} 982 v64" stroke="#E8D8B7" stroke-width="13"/>')
 s.append(f'<rect x="{ox+28}" y="{1040}" width="730" height="74" rx="13" fill="#142729"/>')
 s.append(f'<text x="{ox+45}" y="{1085}" font-family="DejaVu Sans" font-size="29" fill="#F5EEDC">{note}</text>')
s+=['<text x="70" y="1220" font-family="DejaVu Sans" font-size="24" fill="#A6B3AB">Состояние мира принадлежит игроку и его прогрессу; публичные совместные концерты — отдельные временные события.</text>','</svg>']
save('BeatMakka_Restoration_States','\n'.join(s),2600,1280)
print('diagram png/svg files written')
