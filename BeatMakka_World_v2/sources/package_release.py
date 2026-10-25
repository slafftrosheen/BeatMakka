from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from hashlib import sha256
from datetime import datetime
import json,os
import fitz
from PIL import Image
from xml.etree import ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
PDFS=[ROOT/'BeatMakka_World_Artbook_v2_RU.pdf',ROOT/'BeatMakka_Needle_Quay_Development_Plan_RU.pdf']
expected={PDFS[0].name:32,PDFS[1].name:18}
checks=[]
for f in PDFS:
 with fitz.open(f) as doc:
  assert len(doc)==expected[f.name],(f.name,len(doc))
  assert all(len(p.get_text())>=18 or len(p.get_images(full=True)) for p in doc),(f.name,'blank')
  for i,p in enumerate(doc):
   assert p.rect.width>100 and p.rect.height>100
  checks.append({'file':f.name,'pages':len(doc),'valid':True,'content':'searchable or image-forward, no blank sheets'})
for f in sorted((ROOT/'maps').glob('*')):
 if f.suffix=='.png':
  with Image.open(f) as im:assert im.width>=2000 and im.height>=1000,(f,im.size)
 elif f.suffix=='.svg':ET.parse(f)
# data truth checks
meta=json.loads((ROOT/'docs/district_register.json').read_text('utf-8'))
assert len(meta['districts'])==11
assert set(d['kit'] for d in meta['districts'])=={'Original starter','Trip Hop','Dance','Grunge','Hard Trance','Hip Hop','Industrial','Pop','Reggae','Techno','Trance'}
assert meta['initial_unlocked']==['NQ']
assert len(meta['demo_parking_sites'])==4
# No QA artifacts in shared package.
report={'created_at':'2026-10-24','version':'2.0','pdfs':checks,'district_count':11,'initial_unlocked':['NQ'],'parking_count':4,'maps_png':len(list((ROOT/'maps').glob('*.png'))),'maps_svg':len(list((ROOT/'maps').glob('*.svg'))),'status':'DELIVERED ART DIRECTION ONLY; NO REPOSITORY PUSH, STUDIO BUILD, AUDIO UPLOAD, OR PUBLICATION','limitations':['Existing approved MK-I 36-page PDF remains authoritative for exact device layout; this is an updated world-focused companion.','All new names, maps, van and parkings are design proposal, not Roblox runtime evidence.','Audio and mesh/cloud release gates remain open.']}
(ROOT/'docs/QA_REPORT.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
files=[f for f in ROOT.rglob('*') if f.is_file() and '_qa' not in f.parts and f.name not in {'MANIFEST.sha256'}]
items=[]
for f in sorted(files):
 b=f.read_bytes();items.append((sha256(b).hexdigest(),f.relative_to(ROOT).as_posix(),len(b)))
(ROOT/'MANIFEST.sha256').write_text(''.join(f'{sha}  {name}\n' for sha,name,size in items),encoding='utf-8')
zipfile=ROOT.parent/'BeatMakka_World_v2_Complete_Package.zip'
with ZipFile(zipfile,'w',ZIP_DEFLATED,compresslevel=7) as z:
 for f in sorted([f for f in ROOT.rglob('*') if f.is_file() and '_qa' not in f.parts]):
  z.write(f,arcname='BeatMakka_World_v2/'+f.relative_to(ROOT).as_posix())
with ZipFile(zipfile) as z:
 bad=z.testzip();assert bad is None,bad
print('ZIP',zipfile,'MB',zipfile.stat().st_size/1e6,'entries',len(z.namelist()))
print(json.dumps(report,ensure_ascii=False,indent=2))
