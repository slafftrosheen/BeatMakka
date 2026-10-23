"""Inspect the delivered PDF and package file hashes. Not a game test/build."""
from pathlib import Path
import hashlib
import json
import zipfile
import pypdfium2 as pdfium

ROOT=Path(__file__).resolve().parent
pdf=pdfium.PdfDocument(str(ROOT/'BeatMakka_MK-I_Artbook_Alpha01_RU.pdf'))
outside=[]
empty=[]
chars=0
for n,page in enumerate(pdf):
    text=page.get_textpage()
    if not text.get_text_range().strip(): empty.append(n+1)
    for i in range(text.count_chars()):
        if not text.get_text_range(i,1).strip(): continue
        chars+=1
        x0,y0,x1,y1=text.get_charbox(i)
        if x0 < -1 or y0 < -1 or x1 > 1441 or y1 > 901:
            outside.append({'page':n+1,'char_index':i})
assert len(pdf)==36 and not outside and not empty
report={
    'package':'BeatMakka MK-I / Alpha 01 / design proposal v1.0',
    'date':'2026-10-23',
    'source_review_base':'6ed1b00830c2ca243c9d2909261fd9cc9cd7172e',
    'scope':'Document and standalone browser design study; not Roblox acceptance',
    'pdf':{'pages':len(pdf),'visible_characters':chars,'empty_pages':empty,
           'out_of_page_characters':outside,
           'visual_review':'All pages rendered to a contact sheet; key interface spreads inspected at full size; page12 overflow corrected'},
    'browser_review':{
        'method':'Connected in-app browser; UI actions, screenshots, read-only DOM measurements',
        'viewports':[[1280,720],[390,844],[750,381]],
        'performance_document_scroll':'No page overflow at reviewed sizes',
        'pad_count':16,
        'portrait_pad_size_css_px':[81,81],
        'short_landscape_pad_size_css_px':[45.25,45.25],
        'flows_observed':['PLAY → STEPS → enable two steps',
                          'SAVE → save Beat01 → local saved state',
                          'LOAD → confirmation dialog → confirm → restored project',
                          'pad hit → browser audio initialization → PLAY state',
                          'SOUNDS → choose Quay metal → Assign → Back → assigned pad',
                          'portrait STEPS → sixteen separate targets → PLAY restores pads'],
        'phone_steps':'Separate fixed editor; sixteen targets, min-height44 CSS px; no page scroll',
        'console_errors_observed':0,
        'embedded_original_wav_count':19,
        'physical_multitouch_and_latency':'NOT_MEASURED',
        'audio_listening_acceptance':'NOT_CLAIMED',
        'cloud_persistence':'NOT_CONNECTED; browser localStorage only'
    },
    'not_performed':['Roblox app tests/builds','cloud creation','asset uploads',
                     'provider jobs','production asset acceptance'],
    'files':[]
}
for path in sorted(ROOT.rglob('*')):
    if path.is_file() and path.name!='ARTIFACT_REVIEW.json':
        report['files'].append({'path':path.relative_to(ROOT).as_posix(),'bytes':path.stat().st_size,
                                'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(ROOT/'ARTIFACT_REVIEW.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
archive=ROOT.parents[1]/'work/artbook-release/Alpha01_MK-I_Artbook_Package.zip'
archive.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as z:
    for path in sorted(ROOT.rglob('*')):
        if path.is_file():z.write(path,'Alpha01_MK-I/'+path.relative_to(ROOT).as_posix())
print(json.dumps({'pages':len(pdf),'files':len(report['files'])+1,'archive':str(archive),
                  'zip_bytes':archive.stat().st_size,'pdf_out_of_page_chars':len(outside)}))
