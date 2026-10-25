from pathlib import Path
from html import escape
from weasyprint import HTML
import mistune
O=Path(__file__).resolve().parents[1];MD=O/'docs/DEMO_DEVELOPMENT_PLAN_RU.md'
md=MD.read_text(encoding='utf-8')
renderer=mistune.HTMLRenderer(escape=True)
markdown=mistune.create_markdown(renderer=renderer,plugins=['table','strikethrough'])
body=markdown(md)
# localized relative image in special cover
cover=str((O/'maps/BeatMakka_Needle_Quay_Demo_Map.png').absolute())
html=f'''<!doctype html><html lang="ru"><head><meta charset="utf-8"><title>BeatMakka — Needle Quay Implementation Plan</title>
<style>
@font-face{{font-family:D;src:url('file:///usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')}}
@font-face{{font-family:D;src:url('file:///usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf');font-weight:700}}
@page{{size:A4;margin:20mm 18mm 20mm 18mm;@top-left{{content:'BEATMAKKA  /  WORLD v2';color:#53736b;font-family:D;font-size:8pt;font-weight:700}}@top-right{{content:'NEEDLE QUAY  /  DEMO PLAN';color:#53736b;font-family:D;font-size:8pt}}@bottom-right{{content:'PAGE ' counter(page);color:#49665e;font-family:D;font-size:8pt}}@bottom-left{{content:'DESIGN SPEC  ·  24 OCT 2026';color:#49665e;font-family:D;font-size:8pt}}}}
*{{box-sizing:border-box}}
body{{font-family:D,Arial,sans-serif;font-size:9.7pt;color:#162322;line-height:1.58;background:#fff}}
.cover{{page-break-after:always;position:relative;min-height:242mm;background:#142B2D;border-radius:15px;padding:22mm 16mm;color:#F5EEDC;overflow:hidden;}}
.cover h1{{font-size:34pt;line-height:1.06;color:#F5EEDC;letter-spacing:-1px;margin:20mm 0 5mm}}
.cover .sub{{font-size:16pt;color:#F3B65F;font-weight:700}}
.cover .desc{{font-size:12.5pt;color:#E8D8B7;max-width:134mm;line-height:1.6}}
.cover .pill{{display:inline-block;border:1px solid #68897c;border-radius:25px;padding:4px 13px;font-size:8.7pt;margin-right:9px;background:#284744}}
.cover .foot{{position:absolute;bottom:13mm;left:16mm;font-size:9pt;color:#a4b9ad}}
.cover img{{width:100%;margin-top:12mm;border-radius:10px;border:1px solid #809a89}}
h1{{font-size:23pt;line-height:1.17;color:#2F5C58;margin-top:0;letter-spacing:-.4px}}
h2{{font-size:16pt;line-height:1.26;margin:13mm 0 4mm;color:#2F5C58;page-break-after:avoid;border-bottom:1.5pt solid #E0D5B9;padding-bottom:2mm}}
h3{{font-size:11.8pt;line-height:1.3;margin:8mm 0 2.5mm;color:#895A41;page-break-after:avoid}}
p{{margin:0 0 4mm;orphans:3;widows:3;}}
strong{{color:#1c4341}}
a{{color:#B35E49;text-decoration:none}}
blockquote{{background:#E9F0E9;border-left:5px solid #F3B65F;padding:4mm 5mm;margin:6mm 0;border-radius:5px;page-break-inside:avoid}}
blockquote p{{margin:0;color:#253f3d;font-weight:700}}
table{{border-collapse:collapse;width:100%;margin:5mm 0 6mm;font-size:8pt;table-layout:fixed}}
th{{background:#2F5C58;color:#F5EEDC;padding:3mm 2.1mm;text-align:left;line-height:1.4;overflow-wrap:anywhere}}
td{{border-bottom:1px solid #D9E0D8;padding:2.6mm 2.1mm;vertical-align:top;line-height:1.45;overflow-wrap:anywhere}}
tr:nth-child(even) td{{background:#F2F4EF}}
tr{{page-break-inside:avoid}} thead{{display:table-header-group}}
ul,ol{{margin:1.5mm 0 5mm 7mm;padding-left:5mm}}
li{{margin-bottom:1.5mm;orphans:2;widows:2}}
code{{font-family:'DejaVu Sans Mono',monospace;font-size:8.4pt;color:#BD5D42;background:#F7F5EF;padding:0.5pt 2pt;border-radius:2px;overflow-wrap:anywhere}}
pre{{background:#172D30;color:#E9EEE7;border-radius:9px;padding:4mm;white-space:pre-wrap;overflow-wrap:anywhere;font-size:7.9pt;line-height:1.35;page-break-inside:avoid}}
pre code{{font-size:7.9pt;color:#F5EEDC;background:transparent;padding:0}}
hr{{border:0;border-top:1px solid #c8d6cb;margin:9mm 0}}
.first h1{{display:none}}
.status{{background:#ECF0EB;border-left:4px solid #CA7453;padding:3mm 4mm;font-size:8.2pt;border-radius:5px}}
</style></head><body>
<section class="cover"><div class="pill">ALPHA 01 CONTINUATION</div><div class="pill">DISTRICT NQ</div><h1>NEEDLE QUAY</h1><p class="sub">Подробный план следующей разработки демо-района</p><p class="desc">Один живой район. Фургон-студия. Четыре парковки и настоящий игровой путь от первого бита к финальному концерту — с личным прогрессом и добровольным мультиплеером.</p><img src="file://{cover}" alt="Схема первого района"/><p class="foot">World Design v2.0 · 24 октября 2026 · концепт и техническое планирование, не код-релиз</p></section>
<section class="first">{body}</section>
</body></html>'''
(O/'docs/DEMO_DEVELOPMENT_PLAN_RU.html').write_text(html,encoding='utf-8')
PDF=O/'BeatMakka_Needle_Quay_Development_Plan_RU.pdf'
HTML(string=html,base_url=str(O)).write_pdf(str(PDF))
print('plan pdf',PDF.stat().st_size)
