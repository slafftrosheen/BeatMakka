"""Build the consolidated approved-concept artbook with bundled ReportLab.

No image generation, provider calls, tests, uploads or acceptance promotion.
The document separates approved visual designs from unproduced register items.
"""
from pathlib import Path
import json,hashlib
from io import BytesIO
from PIL import Image
from reportlab.lib.utils import ImageReader
from xml.sax.saxutils import escape
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A3,landscape
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph,Table,TableStyle
from reportlab.lib.styles import ParagraphStyle

R=Path(__file__).resolve().parents[1]
D=json.loads((R/'data/needle-quay-environment.v1.json').read_text(encoding='utf-8'))
OUT=R/'output/needle-quay/BeatMakka_Needle_Quay_Environment_Quest_Artbook_Vol01.pdf'
OUT.parent.mkdir(parents=True,exist_ok=True)
pdfmetrics.registerFont(TTFont('Book','C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('BookBold','C:/Windows/Fonts/arialbd.ttf'))
W,H=landscape(A3);M=44
INK=colors.HexColor('#162322');TEAL=colors.HexColor('#2f5c58');CREAM=colors.HexColor('#f4eedf');CORAL=colors.HexColor('#ca7453')
C=canvas.Canvas(str(OUT),pagesize=(W,H))
C.setTitle('BeatMakka — Needle Quay: Buildings, Characters & Street Art, Vol. 01')
C.setAuthor('BeatMakka production / Codex')
# Print embeddings use JPEG to keep the single consolidated PDF below Git limits.
# Original PNG/SVG masters remain byte-for-byte preserved beside the book.
_draw_image=C.drawImage
def print_image(path,*args,**kwargs):
 with Image.open(path) as original:
  im=original.convert('RGBA');im.thumbnail((2400,2400),Image.Resampling.LANCZOS)
  paper=Image.new('RGB',im.size,(244,238,223));paper.paste(im,mask=im.getchannel('A'))
  stream=BytesIO();paper.save(stream,format='JPEG',quality=90,subsampling=0);stream.seek(0)
  kwargs.pop('mask',None)
  return _draw_image(ImageReader(stream),*args,**kwargs)
C.drawImage=print_image
page=0
STYLE=ParagraphStyle('body',fontName='Book',fontSize=13,leading=19,textColor=INK)
SMALL=ParagraphStyle('small',fontName='Book',fontSize=10,leading=14,textColor=INK)

def para(text,x,y,width,style=STYLE):
  p=Paragraph(text,style);_,height=p.wrap(width,H);p.drawOn(C,x,y-height);return y-height-14

def start(title,kicker='APPROVED CONCEPTS / PRODUCTION HANDOFF'):
 global page
 page+=1;C.setFillColor(CREAM);C.rect(0,0,W,H,fill=1,stroke=0)
 C.setFillColor(TEAL);C.rect(M,H-42,38,3,fill=1,stroke=0)
 C.setFont('BookBold',10);C.drawString(M+50,H-43,kicker)
 C.setFillColor(INK);C.setFont('BookBold',28);C.drawString(M,H-88,title)
 C.setStrokeColor(colors.HexColor('#d4c8b4'));C.line(M,39,W-M,39)
 C.setFont('Book',9);C.drawString(M,24,'NEEDLE QUAY  /  VOL. 01  /  25 OCTOBER 2026')
 C.drawRightString(W-M,24,f'{page:02d}  ·  CONCEPT APPROVAL ≠ PRODUCTION / RUNTIME ACCEPTANCE')
 return H-120

def end():C.showPage()

def table(headers,rows,widths,y):
 th=ParagraphStyle('table_head',parent=SMALL,textColor=colors.white,fontName='BookBold')
 data=[[Paragraph(escape(str(v)),th if i==0 else SMALL) for v in row] for i,row in enumerate([headers]+rows)]
 t=Table(data,colWidths=widths,hAlign='LEFT')
 t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),TEAL),('TEXTCOLOR',(0,0),(-1,0),colors.white),('VALIGN',(0,0),(-1,-1),'TOP'),('TOPPADDING',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),8),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor('#eee4d0'),CREAM]),('LINEBELOW',(0,0),(-1,0),1,CORAL)]))
 for cell in data[0]:cell.style=ParagraphStyle('th',parent=SMALL,textColor=colors.white,fontName='BookBold')
 _,height=t.wrap(sum(widths),H)
 if height>y-55:raise ValueError('Table exceeds page; split the authoring group')
 t.drawOn(C,M,y-height)
 return y-height

y=start('Needle Quay','BEATMAKKA / ENVIRONMENT & QUEST ARTBOOK')
C.setFillColor(TEAL);C.setFont('BookBold',40);C.drawString(M,y-30,'Buildings, Characters & Street Art')
y=para('VOL. 01 · Production Register v1.0 · consolidated concept package',M,y-58,W-2*M)
y=para('<b>13 building sheets · 4 parking venues · 7 NPC identities · 13 quest briefs · 12 material families · 61 graphic specifications</b>',M,y,W-2*M)
C.drawImage(str(R/'assets/references/needle-quay-approved-style-board.png'),M,105,width=620,height=460,preserveAspectRatio=True,anchor='c')
para('Визуальные материалы и все 13 building concepts одобрены пользователем 25 октября 2026.<br/><br/>Документ объединяет утверждённое направление, строительные карточки и производственные реестры. Добавлены шесть новых NPC design sheets, шесть моделей с 15-bone rigid rigs, существующий Mica/H04, 61 графический дизайн и 12 материальных источников. Это локальные production candidates; игровое исполнение квестов не подтверждено.<br/><br/>Исходный XLSX и 74 canonical package IDs сохранены. H06 использует canonical 32×16×24 в blockout. Производственный вариант сохраняет 32×16×24 и предлагает clear interior 30×14; несовместимое legacy 24×20 не переносится.',710,560,W-754)
end()

y=start('Как читать этот том / Acceptance ledger')
for text in [
'<b>Одобрено человеком:</b> предыдущие артбуки и 13 сохранённых concept PNG. Receipt фиксирует точные SHA-256 файлов: docs/needle-quay/ART_APPROVAL_2026-10-25.json.',
'<b>Произведено локально:</b> machine-readable environment register, 13 concept sheets, deterministic blockout source и отдельный native Studio scene. Исторический Studio Edit receipt подтверждает открытие сцены, а не runtime acceptance.',
'<b>Дополнено производством:</b> 13 building GLB/Blender candidates с ортографическими рендерами; шесть новых NPC sources/rigs + existing H04; 61 графический дизайн, 8 faded variants; 12 procedural material swatches; полные design contracts Q00–Q12. Final UV/material bake, animation clips, Studio import и runtime acceptance остаются отдельными gates.',
'<b>Стадии отдельно:</b> concept art-approved → deterministic production/DCC-clean → production art approval → Studio-imported → runtime-verified. Approval рисунка не перескакивает последующие стадии.',
'<b>Исходные задачи 1–3:</b> реестр, visual sheets и начало blockout. Этот том консолидирует их. Полный production register содержит дополнительное производство и игровую интеграцию, статус которых указан явно.',
'<b>Авторские ограничения:</b> габариты, бюджеты и grid — проектные требования, не Roblox platform limits. Billable Tripo batches и Roblox uploads/publishing не выполнялись. User requested scoped Git preservation of this package.'
]:y=para(text,M,y,W-2*M)
end()

y=start('Здания / Building register')
rows=[]
for b in D['buildings']:
 rows.append([b['id'],b['name'],'×'.join(map(str,b['proposed_dimensions_wdh_studs'])),'×'.join(map(str,b['blockout_dimensions_wdh_studs'])),b['tier'],', '.join(b['npc_names']) or '—'])
table(['ID','Building','Concept W/D/H','Blockout W/D/H','Tier','NPC links'],rows,[100,270,150,150,110,W-2*M-780],y)
end()

for b in D['buildings']:
 y=start(b['id']+' — '+b['name'],'USER-APPROVED CONCEPT / ORIGINAL SHEET')
 C.drawImage(str(R/b['concept_sheet']),M,55,width=W-2*M,height=y-65,preserveAspectRatio=True,anchor='c')
 end()
 y=start(b['id']+' / Production card')
 dims=' × '.join(map(str,b['blockout_dimensions_wdh_studs']))
 rows=[['Canonical / environment',b.get('canonical_asset_id','Environment-specific building')+' / '+b['id']],['Art status','Concept approved by user; production geometry acceptance pending'],['Layout envelope',dims+' studs W×D×H; floor-center layout pivot; front -Z'],['Canonical pivot',b.get('canonical_pivot','Exact asset pivot to be authored; layout proxy is not a DCC acceptance receipt')],['Access',b['access']],['Position X / Z',str(b['blockout_center_xz_studs'])+'; proposed district placement'],['NPC',', '.join(b['npc_names']) or 'No new named NPC assigned'],['Quest links',', '.join(b['quest_ids']) or 'Supporting facade / local interaction only'],['Graphics',b['sign_id']+'; independent PNG/SVG export in graphics library'],['Optimization','Reuse shared palette/material families and modules. Simple collision proxies; decorative detail non-collidable. Triangle budgets not invented.'],['Moving / light state','Before/After uses the same shell with separate lights/dressing. Exact door/fan/antenna targets require deterministic construction.'],['Deliverable boundaries','Concept + local native blockout + Blender/GLB + front/side/top/neutral renders. See full production candidate pages below. LOD device profiling, final UV bake, Studio/runtime acceptance pending.']]
 table(['Contract field','Production handoff'],rows,[210,W-2*M-210],y)
 end()

y=start('Четыре стоянки / Four authored parking venues')
rows=[[s['existing_parking_id']+' / '+s['id'],s['name'],', '.join(s['building_ids']),', '.join(s['npcs']),', '.join(s['sample_bindings']) or 'Music sorting / shelf'] for s in D['stops']]
y=table(['ID','Venue','Building links','NPC','Discovery'],rows,[145,205,260,180,W-2*M-790],y)-25
y=para('Парковочный clearance 28×18 studs; LoopVan proxy 22×9×10 (длина/ширина/высота). Свободный путь минимум 6 studs — цель для avatar review. Финальный клуб NQ-BLD-01 входит в 13 зданий; он не четырнадцатое здание и не пятая парковка.',M,y,W-2*M)
para('Никакой новой физики автомобиля, VanService, владения, переходов или сохранения профилей этот blockout не реализует. Музыкальные станции и старые ProfileStore contracts сохраняются.',M,y,W-2*M)
end()

y=start('Семь NPC / Identity and silhouette briefs')
table(['Name','Location','Silhouette / role','Production status'],[[n['name'],n['location'],n['silhouette']+'; '+n['role'],'Existing H04 identity; no redesign' if n['canonical_asset_id'] else 'Design + 15-bone rigid candidate; animation/import pending'] for n in D['npcs']],[125,200,500,W-2*M-825],y)
end()
y=start('Квестовый production register / Q00–Q12')
table(['ID','Quest','NPC','Result'],[[q['id'],q['name'],q['npc'],q['result']] for q in D['quests']],[85,240,180,W-2*M-505],y)
end()
y=start('Texture & material families / Shared atlas mapping')
table(['ID','Material family','Atlas slot','Mapping / missing production'],[[m['id'],m['name'],m['atlas_slot'],m['mapping_status']] for m in D['materials']],[85,230,170,W-2*M-485],y)
end()
for heading,kinds in [('Signs & wayfinding',['sign','wayfinding']),('Posters & street art',['poster','transparent_graffiti']),('Service decal packs',['service_decal'])]:
 rows=[[g['id'],g['kind'],g['subject'],'Local master/PNG candidate; see visual gallery'] for g in D['graphics'] if g['kind'] in kinds]
 for offset in range(0,len(rows),16):
  suffix=' / '+str(offset//16+1) if len(rows)>16 else ''
  y=start('Graphic Bible / '+heading+suffix)
  table(['ID','Type','Subject','Current deliverable'],rows[offset:offset+16],[150,180,420,W-2*M-750],y)
  end()
y=start('Blockout / Studio Edit reference')
C.drawImage(str(R/'assets/blockouts/needle-quay/studio-plan.png'),M,180,width=W-2*M,height=490,preserveAspectRatio=True,anchor='c')
para('Native source: assets/blockouts/needle-quay/NeedleQuayEnvironmentBlockout.rbxmx<br/>Local scene: output/needle-quay/NeedleQuayEnvironmentBlockout-v1.rbxlx<br/>Historical Edit receipt: 13 buildings, 4 parking models, 270 Parts, PlaceId 0. NPC are location markers. No production meshes or runtime quests accepted.',M,145,W-2*M)
end()
y=start('Открытые construction decisions / Next production')
for text in [
'<b>H06:</b> preserve canonical 32×16×24 and front-left floor-grid pivot. Proposed 24×18×19 is a visual alternative; the legacy 24×20 usable interior is incompatible with 16 depth. Approval of artbooks does not resolve the arithmetic. Do not silently resize the existing shop or its modules.',
'<b>Morrow Repairs:</b> locate one accessible P16/I02 attachment and give the sliding leaf an explicit clear travel zone. The facade fan is a visual wrapper, not an automatic replacement of the canonical discovery mesh.',
'<b>Signal House:</b> choose one exact external-console face in construction; production proposal fixes the console on front -Z, right side. Preserve 26 total height including antenna.',
'<b>Market:</b> retain four stalls, open central aisle and separate performance nook. Coordinate roof/canopies/service bay in one exact authored plan.',
'<b>Supporting facades:</b> closed shells and short exterior interactions. Include rooftop equipment in total height. Site bases/ramps and dressing are separate elements, not hidden changes to authored envelopes.',
'<b>Production acceptance remaining:</b> final UV consolidation and material baking on approved geometry, articulation/animation review, art approval of new candidates, device LOD profiling and executable quest/restoration integration. Local candidate files and full design contracts are included below.'
]:y=para(text,M,y,W-2*M)
end()
P=json.loads((R/'assets/production/needle-quay/building-cards.json').read_text(encoding='utf-8'))
N=json.loads((R/'assets/production/needle-quay/npcs/npc-manifest.json').read_text(encoding='utf-8'))
G=json.loads((R/'assets/production/needle-quay/graphics/graphics-manifest.json').read_text(encoding='utf-8'))
T=json.loads((R/'assets/production/needle-quay/materials/material-manifest.json').read_text(encoding='utf-8'))
Q=json.loads((R/'assets/production/needle-quay/quest-world-contracts.json').read_text(encoding='utf-8'))

y=start('Full district / Local assembly','PRODUCTION CANDIDATES / NO ROBLOX UPLOADS')
C.drawImage(str(R/'assets/production/needle-quay/site/after.png'),M,145,width=W-2*M,height=540,preserveAspectRatio=True,anchor='c')
para('13 authored building sources assembled at register coordinates. Signs are separate graphic planes. LoopVan remains a layout proxy. Full local source: assets/production/needle-quay/site/NeedleQuayDistrict.blend. This is a design review assembly; no production meshes were uploaded to Roblox.',M,130,W-2*M)
end()
y=start('Restoration / Same geometry, local light presentation')
for j,state in enumerate(('before','after')):
 C.drawImage(str(R/f'assets/production/needle-quay/site/{state}.png'),M+j*(W-2*M)/2,260,width=(W-2*M)/2-10,height=400,preserveAspectRatio=True,anchor='c')
 para(state.upper()+' / amber inserts '+('off' if j==0 else 'on'),M+j*(W-2*M)/2,240,(W-2*M)/2-20)
para('Rendered evidence shows light insert changes only. Per-building dressing and personal quest states are specified in the following cards. Runtime authority remains server-owned; client presentation must never grant rewards or mutate another player’s district.',M,185,W-2*M)
end()
for b in P['buildings']:
 m=b['model'];y=start(b['id']+' / Authored 3D + orthographic views','LOCAL MODEL CANDIDATE / MEASURED SOURCE')
 for j,label in enumerate(('neutral','front','side','top')):
  x=M+j*(W-2*M)/4;path=next(p for p in m['previews'] if p.endswith('/'+label+'.png'))
  C.drawImage(str(R/path),x,430,width=(W-2*M)/4-12,height=250,preserveAspectRatio=True,anchor='c');para(label.upper(),x,420,250,SMALL)
 rows=[['Core W/D/H',str(b['dimensions_wdh_studs'])+' studs; '+str(m['triangles'])+' triangles; '+str(m['mesh_objects'])+' mesh objects'],['Measured dressing bounds',str([round(v,3) for v in m['bounds_xyz_blender']])+' Blender X/Y/Z; exterior trim can exceed core footprint'],['Source / export',m['source']+' / '+m['glb']],['Module reuse',', '.join(b['modules'])],['Material families',', '.join(b['materials'])],['Facade graphic plan',b['graphics']['sign']+' front -Z; '+b['graphics']['poster']+' front-side notice panel; '+b['graphics']['graffiti']+' right wall'],['Collision / LOD',b['collision']+' '+b['lod']]]
 table(['Production field','Authored candidate / review boundary'],rows,[170,W-2*M-170],385)
 end()
 y=start(b['id']+' / Placement & restoration design')
 # Authored top-plan diagram. Dimensions and anchors use the register, not image arrows.
 x0=M+60;y0=390;pw=350;ph=220;C.setFillColor(colors.HexColor('#e8d8b7'));C.rect(x0,y0,pw,ph,fill=1,stroke=1)
 C.setStrokeColor(TEAL);C.setLineWidth(4);C.line(x0+pw*.4,y0,x0+pw*.6,y0);C.setLineWidth(1)
 C.setFillColor(INK);C.setFont('BookBold',14);C.drawCentredString(x0+pw/2,y0+ph+17,str(b['dimensions_wdh_studs'][0])+' studs W');C.drawString(x0+pw+12,y0+ph/2,str(b['dimensions_wdh_studs'][1])+' D')
 C.drawCentredString(x0+pw/2,y0-25,'FRONT -Z / entrance / sign')
 for cx,col,caption in [(x0+pw*.3,CORAL,'NPC'),(x0+pw*.7,TEAL,'Sound / interaction')]:
  C.setFillColor(col);C.circle(cx,y0-45,7,fill=1,stroke=0);C.setFont('Book',10);C.drawCentredString(cx,y0-65,caption)
 para('<b>Site placement X/Z:</b> '+str(next(d['blockout_center_xz_studs'] for d in D['buildings'] if d['id']==b['id']))+'<br/><b>Entry / NPC / sound / interaction coordinates:</b><br/>'+escape(str(b['anchors_studs']))+'<br/><br/><b>Interaction layout:</b> '+b['interaction'],M+590,650,W-2*M-590,SMALL)
 # Before/After state plates are deliberately diagrams, not invented engine screenshots.
 for j,state in enumerate(('before','after')):
  x=M+j*(W-2*M)/2;C.setFillColor(TEAL);C.rect(x,210,400,80,fill=1,stroke=0);C.setFillColor(colors.HexColor('#524e43') if j==0 else colors.HexColor('#f3b65f'));C.rect(x+165,240,70,24,fill=1,stroke=0)
  para('<b>'+state.upper()+' · schematic state plate</b><br/>'+b[state],x,195,(W-2*M)/2-35,SMALL)
 para('Sources retain separate shell, graphic planes, fixture inserts and role targets. Material IDs and layout are production proposals. Dressing deltas above are authored design states; the district render demonstrates insert lighting only. No animation, persistence or runtime acceptance is inferred.',M,100,W-2*M,SMALL)
 end()

for n in N['npcs']:
 y=start(n['name']+' / Character design & model candidate')
 if n['design']:
  C.drawImage(str(R/n['design']),M,250,width=710,height=410,preserveAspectRatio=True,anchor='c')
  C.drawImage(str(R/n['model']['previews'][0]),800,280,width=310,height=350,preserveAspectRatio=True,anchor='c')
 else:
  C.drawImage(str(R/'assets/cleaned/H04/H04_maintenance_helper_robot_surface_repaired_preview.png'),M,260,width=650,height=390,preserveAspectRatio=True,anchor='c')
  para('Mica / H04 is reused unchanged. The canonical Blender and atlas GLB remain the source authority.',770,610,340)
 rows=[['Identity / place',n['silhouette']+' / '+n['location']],['Rig / motion contract',n['rig_scope']+'; '+', '.join(n['animation_contract'])],['Source / export',n['model']['source']+' / '+n['model']['glb']],['Acceptance','New design and rigid model are candidates; animation clips, Humanoid import, art approval and runtime checks pending. Existing H04 retains its historical evidence.']]
 table(['Field','Character production handoff'],rows,[170,W-2*M-170],235)
 end()

for offset in range(0,len(T['materials']),6):
 y=start('Material Bible / '+str(offset//6+1))
 for j,m in enumerate(T['materials'][offset:offset+6]):
  x=M+(j%3)*(W-2*M)/3;yy=425-(j//3)*285
  C.drawImage(str(R/m['preview']),x,yy,width=260,height=230,preserveAspectRatio=True,anchor='c');para('<b>'+m['id']+' '+m['name']+'</b><br/>Atlas: '+m['atlas_slot'],x,yy-5,330,SMALL)
 para('Source: assets/production/needle-quay/materials/NeedleQuayMaterialLibrary.blend. Ten atlas families reused; brick and oxidized brass have new procedural DCC finishes. These are material source candidates, not twelve heavy independent PBR sets. Bake on approved final UVs before engine acceptance.',M,95,W-2*M,SMALL)
 end()
for offset in range(0,len(G['base_designs']),8):
 y=start('Graphic Bible / Export gallery '+str(offset//8+1))
 for j,g in enumerate(G['base_designs'][offset:offset+8]):
  x=M+(j%4)*(W-2*M)/4;yy=435-(j//4)*290
  C.drawImage(str(R/g['png']),x,yy,width=255,height=220,preserveAspectRatio=True,anchor='c',mask='auto');para('<b>'+g['id']+'</b> '+escape(g['subject'])+'<br/>'+str(g['width'])+'×'+str(g['height'])+' / '+g['stage'],x,yy-5,250,SMALL)
 end()
for offset in range(0,len(Q['quests']),4):
 y=start('Quest / world contracts '+str(offset//4+1),'DESIGN CONTRACTS / EXECUTABLE RUNTIME INTEGRATION PENDING')
 for q in Q['quests'][offset:offset+4]:
  text='<b>'+q['id']+' — '+q['name']+'</b> / '+q['npc']+'<br/>Complete: '+q['completion_contract']+'<br/>Geometry: '+q['geometry_anchor']+'<br/>Sound: '+q['sound_contract']
  if q.get('concert_phases'):text+='<br/>Six phases: '+' → '.join(q['concert_phases'])
  y=para(text,M,y,W-2*M,SMALL)-16
 para('All progress is personal and server-authoritative. Cancel/rejoin retains committed steps; presentation must be idempotent. Optional performances do not gate progress. Existing samples/Beat Shelf contracts are retained. New chain implementation and runtime verification are not claimed.',M,110,W-2*M,SMALL)
 end()
y=start('Delivery / Acceptance ledger')
for text in ['<b>Compiled local package:</b> 13 approved building concepts + 13 Blender/GLB candidates with four views each; 6 new character designs and 15-bone rigid candidates + canonical Mica/H04; 12 material sources/swatches; 61 graphic base designs + 8 faded poster variants; 13 quest/world design contracts; district assembly and native Part blockout.', '<b>Integrity:</b> SHA-256 production file manifest and game-dev package verification receipts. CLI static validation is separate from project art approval, topology cleanup, performance profiling and engine/runtime acceptance. Generic CLI limits are not Roblox limits or newly authored project budgets.', '<b>Local-only:</b> no Roblox uploads/publishing, no billable Tripo work. Current testing account is not used for deployment. Future adult-account deployment needs fresh explicit instruction.', '<b>Review gates:</b> final UV/material baking and palette consolidation; detail fidelity to approved concepts; rig articulation/animation; final building/pivot/collision acceptance; local Studio import and personal quest/audio runtime verification. Candidate files do not bypass these gates.', '<b>Source of truth:</b> data/needle-quay-environment.v1.json; assets/production/needle-quay/delivery-manifest.json; building-cards.json; graphics/graphics-manifest.json; npcs/npc-manifest.json; materials/material-manifest.json; quest-world-contracts.json. Browse output/needle-quay/index.html for every visual/source link.']:
 y=para(text,M,y,W-2*M)
end()
C.save()
receipt={'date':'2026-10-25','pdf':str(OUT.relative_to(R)).replace('\\','/'),'pages':page,'bytes':OUT.stat().st_size,'sha256':hashlib.sha256(OUT.read_bytes()).hexdigest(),'approved_concept_sheets':len(D['buildings']),'npc_models_produced_by_book':6,'standalone_graphics_produced_by_book':61,'approval_receipt':'docs/needle-quay/ART_APPROVAL_2026-10-25.json','source_register':'data/needle-quay-environment.v1.json','runtime_acceptance':False}
(R/'docs/needle-quay/ARTBOOK_BUILD_RECEIPT.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt))
