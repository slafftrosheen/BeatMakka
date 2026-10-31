"""Inspect and index the requested PNG files without modifying any image bytes."""
from pathlib import Path
import json,hashlib,html
from PIL import Image
O=Path(__file__).resolve().parent
P=json.loads((O/'generation-plan.json').read_text(encoding='utf-8'))
R=Path(P['root']).parents[2]
rows=[];errors=[]
for b in P['buildings']:
 folder=O/b['folder']
 found=sorted(p.name for p in folder.glob('*.png'))
 if found!=['back.png','front.png','left.png','right.png']:errors.append(b['id']+': expected four PNGs, found '+str(found))
 views=[]
 for view in P['views']:
  f=folder/(view+'.png')
  if not f.exists():errors.append(str(f)+' missing');continue
  with Image.open(f) as im:
   im.load();width,height=im.size;mode=im.mode
   alpha=im.getchannel('A').getextrema() if 'A' in im.getbands() else None
   if alpha is None or alpha[0]!=0:errors.append(b['id']+' '+view+': no transparent background')
  size=f.stat().st_size
  if size>=20000000:errors.append(b['id']+' '+view+': exceeds 20 MB')
  receipt=folder/(view+'.provenance.json')
  if not receipt.exists():errors.append(b['id']+' '+view+': missing provenance')
  views.append({'view':view,'file':f.relative_to(O).as_posix(),'width':width,'height':height,'mode':mode,'alpha_extrema':alpha,'bytes':size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'provenance':receipt.relative_to(O).as_posix()})
 source=R/b['reference']
 rows.append({'id':b['id'],'name':b['name'],'folder':b['folder'],'artbook_reference':b['reference'],'artbook_reference_sha256':hashlib.sha256(source.read_bytes()).hexdigest() if source.exists() else None,'views':views})
manifest={'date':'2026-10-29','buildings':rows,'building_count':len(rows),'image_count':sum(len(b['views']) for b in rows),'expected_count':52,'all_files_decode':not errors,'errors':errors,'view_order':['front','left','right','back'],'background':'genuine transparent PNG alpha','projection_convention':P['conventions'],'method':'52 separate built-in image_gen derived architectural concept elevations, referenced to approved artbook and front identity anchors. Not rendered from a single exact reconstructed DCC model.','unseen_details':'Left/rear details not depicted by the artbook are design interpretations. These are concept references, not precision engineering projections.','roblox_uploads':0,'tripo_calls':0,'new_art_approval':False,'assets_inventory_count':6343,'supplied_new_external_materials_used':0}
(O/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
doc=['<!doctype html><html lang="en" data-bg="checker"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Needle Quay · Four views</title><style>body{margin:32px;background:#f4eedf;color:#162322;font:16px/1.5 Arial,sans-serif}h1{font-size:36px}h2{margin-top:48px}nav{position:sticky;top:0;z-index:1;padding:12px;background:#f4eedf;border-bottom:1px solid #cdbda4}button{padding:8px 16px;margin-right:8px;cursor:pointer;border:1px solid #2f5c58;border-radius:4px;background:white;color:#162322}section{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px}figure{margin:0}a{color:#2f5c58}img{display:block;width:100%;height:300px;object-fit:contain;background-color:#e0e0e0;background-image:linear-gradient(45deg,#ccc 25%,transparent 25%),linear-gradient(-45deg,#ccc 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#ccc 75%),linear-gradient(-45deg,transparent 75%,#ccc 75%);background-size:24px 24px;background-position:0 0,0 12px,12px -12px,-12px 0}html[data-bg=white] img{background:white}html[data-bg=dark] img{background:#242424}figcaption{padding:8px 0}small{display:block;color:#625d52}@media(max-width:900px){section{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:500px){section{grid-template-columns:1fr}}</style><h1>Needle Quay · Front / Left / Right / Back</h1><p>13 artbook buildings · 52 separate PNG files · 29 October 2026</p><p>Isolated artbook-derived concept elevations. Rear/unseen details are interpreted; this is not a measured DCC turnaround. Click any image to open its original PNG.</p><nav>Preview background: <button onclick="document.documentElement.dataset.bg=\'checker\'">Checkerboard</button><button onclick="document.documentElement.dataset.bg=\'white\'">White</button><button onclick="document.documentElement.dataset.bg=\'dark\'">Dark</button> <a href="README.md">Readme</a> · <a href="manifest.json">File manifest</a></nav>']
for b in rows:
 doc+=['<h2>'+b['id']+' · '+html.escape(b['name'])+'</h2><section>']
 for v in b['views']:
  path=html.escape(v['file']);doc+=['<figure><a href="'+path+'"><img loading="lazy" alt="'+html.escape(b['name']+' '+v['view'])+'" src="'+path+'"></a><figcaption><b>'+v['view'].upper()+'</b><small>'+str(v['width'])+' × '+str(v['height'])+' · '+str(round(v['bytes']/1000000,2))+' MB</small></figcaption></figure>']
 doc+=['</section>']
doc+=['</html>'];(O/'index.html').write_text(''.join(doc),encoding='utf-8')
readme=['# Needle Quay — four separate views per building','','52 PNG files for all 13 buildings in the approved artbook. Each building has its own folder containing exactly four image files:','','- front.png — camera from -Z, main entrance elevation','- left.png — camera from -X; front end at image right','- right.png — camera from +X; front end at image left','- back.png — camera from +Z, rear elevation','','Open index.html to browse the set on checkerboard, white or dark backgrounds. The original PNGs preserve genuine alpha; preview-only RGB matte colors in fully transparent pixels do not constitute an opaque background. All outputs are below 20 MB. Individual provenance JSON files retain exact prompts, references and original generated-image paths. manifest.json records dimensions, bytes, alpha extrema and SHA-256 hashes.','','These are newly derived, detailed concept elevations matching the artbook designs, not exact camera renders of one reconstructed DCC asset. Small geometry, framing and lighting differences can remain between views. Rear and unseen wall details are interpretations. Historical artbook approval does not automatically approve these new references. No Tripo generation, upload or Roblox publication was performed. Canonical asset dimensions/contracts and original approved sheets were not modified.','','## Buildings','']
for b in rows:readme.append('- '+b['id']+' — '+b['name']+' — '+b['folder']+'/')
(O/'README.md').write_text('\n'.join(readme)+'\n',encoding='utf-8')
print(json.dumps({'buildings':len(rows),'images':manifest['image_count'],'errors':errors,'max_file_bytes':max(v['bytes'] for b in rows for v in b['views']),'total_png_bytes':sum(v['bytes'] for b in rows for v in b['views']),'unique_sha256':len({v['sha256'] for b in rows for v in b['views']})},indent=2))
if errors:raise SystemExit(1)

