"""Contact sheets of actual material-source images and exported model previews."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/evidence"
font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 20)
small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 15)
title_font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 32)
report = json.loads((OUT / "optimized-assets.json").read_text())
sheet = Image.new("RGB", (1500, 1420), "#182322")
d = ImageDraw.Draw(sheet)
d.text((28, 18), "FREQUENCY ZERO  /  ATLAS VARIANTS", font=title_font, fill="#E8D8B7")
d.text((28, 64), "Actual Blender color/UV previews. Geometry preserved; Studio PBR review remains pending.", font=font, fill="#B79C7E")
for i, asset in enumerate(report["assets"]):
    x, y = 20 + i % 5 * 296, 108 + i // 5 * 320
    image = Image.open(ROOT / asset["preview"]).convert("RGBA").resize((288, 288))
    sheet.paste(image, (x, y), image)
    d.text((x + 8, y + 276), f'{asset["id"]}   {asset["after"]["triangles"]} tris / {asset["after"]["mesh_objects"]} parts', font=small, fill="#E8D8B7")
sheet.save(OUT / "optimized-assets-contact.png", optimize=True)
materials = ROOT / "assets/production/materials"
layout = json.loads((materials / "layout.json").read_text())
sheet = Image.new("RGB", (1280, 820), "#182322")
d = ImageDraw.Draw(sheet)
d.text((24, 16), "SHARED FINISHES / MATERIALS / UI MASKS", font=title_font, fill="#E8D8B7")
d.text((24, 64), "Four precomposed finishes, one UV layout. Editable masks and SVG icon sources.", font=font, fill="#B79C7E")
for i, (set_id, spec) in enumerate(layout["sets"].items()):
    x = 24 + i * 314
    image = Image.open(materials / "sets" / set_id / "atlas_basecolor.png").resize((288, 288))
    sheet.paste(image, (x, 120))
    d.text((x, 420), spec["label"], font=font, fill="#E8D8B7")
icons = Image.open(ROOT / "assets/production/graphics/G03_G04_icons.png").resize((300, 300))
sheet.paste(icons, (24, 480), icons)
d.text((350, 490), "16 text-free transport / discovery icons", font=font, fill="#E8D8B7")
d.text((350, 530), "Device paint / trim / rubber / metal", font=font, fill="#B79C7E")
d.text((350, 565), "Items: wood / stone / ceramic / leather", font=font, fill="#B79C7E")
d.text((350, 600), "Character clothing: canvas / cloth / trim", font=font, fill="#B79C7E")
for i, name in enumerate(("device_face_mask", "display_mask", "pad_mask", "panel_9slice")):
    image = Image.open(ROOT / "assets/production/graphics" / (name + ".png"))
    image.thumbnail((180, 90))
    sheet.paste(image, (350 + i * 224, 675), image)
    d.text((350 + i * 224, 776), name.replace("_mask", ""), font=small, fill="#E8D8B7")
sheet.save(OUT / "material-sets-contact.png", optimize=True)
print("Wrote optimized-assets-contact.png and material-sets-contact.png")
