"""Reproducible original material sets, edit masks, UI graphics, and sampler audio.

Uses Pillow/NumPy from the Codex runtime. No provider calls or downloaded media.
Run from the repository root. Existing generated destinations are regenerated;
accepted mesh sources and imported/uploaded assets are never changed.
"""
from pathlib import Path
import hashlib
import json
import math
import wave
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "production"
PALETTE = {
    "teal": "2F5C58", "faded": "6F9186", "cream": "E8D8B7", "coral": "CA7453",
    "amber": "F3B65F", "walnut": "79513B", "stone": "B79C7E", "graphite": "2C3031",
}
SLOTS = [
    ("paint_primary", "teal", .62, 0), ("paint_secondary", "faded", .7, 0),
    ("trim", "cream", .65, 0), ("accent", "coral", .68, 0),
    ("amber", "amber", .46, 0), ("wood", "walnut", .82, 0),
    ("stone", "stone", .92, 0), ("graphite", "graphite", .78, 0),
    ("bare_metal", "stone", .4, 1), ("foliage", "faded", .8, 0),
    ("canvas", "cream", .94, 0), ("rubber", "graphite", .96, 0),
    ("ceramic", "cream", .4, 0), ("leather", "walnut", .84, 0),
    ("cloth", "teal", .96, 0), ("cloth_trim", "coral", .96, 0),
]
SETS = {
    "quay": {"label": "Workshop teal", "primary": "teal", "secondary": "faded", "trim": "cream", "accent": "coral"},
    "chalk": {"label": "Warm cream", "primary": "cream", "secondary": "stone", "trim": "teal", "accent": "amber"},
    "coral": {"label": "Repaired coral", "primary": "coral", "secondary": "cream", "trim": "graphite", "accent": "teal"},
    "afterhours": {"label": "After hours", "primary": "graphite", "secondary": "teal", "trim": "cream", "accent": "amber"},
}
SLOT_CHANNEL = {"paint_primary": "primary", "paint_secondary": "secondary", "trim": "trim", "accent": "accent",
                "cloth": "primary", "canvas": "secondary", "cloth_trim": "accent"}
SETS["chalk"]["materials"] = {"wood": "stone", "leather": "walnut", "ceramic": "cream"}
SETS["coral"]["materials"] = {"wood": "walnut", "leather": "coral", "ceramic": "cream"}
SETS["afterhours"]["materials"] = {"wood": "graphite", "leather": "graphite", "ceramic": "stone"}


def rgb(name):
    return np.array([int(PALETTE.get(name, name)[i:i + 2], 16) for i in (0, 2, 4)])


def write_json(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")


def save_image(path, values, mode="RGB"):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.uint8(np.clip(values, 0, 255)), mode).save(path, optimize=True)


def tile(slot, color, size=256):
    y, x = np.mgrid[0:size, 0:size] / size
    # Periodic, low-amplitude material variation; no baked light or shadows.
    if slot == "wood":
        detail = 5 * np.sin(2 * np.pi * (y * 5 + .24 * np.sin(2 * np.pi * x)))
    elif slot in ("canvas", "cloth", "cloth_trim"):
        detail = 2.5 * np.sin(x * 2 * np.pi * 32) * np.sin(y * 2 * np.pi * 32)
    elif slot == "stone":
        detail = 2 * np.sin(x * 2 * np.pi * 3) * np.cos(y * 2 * np.pi * 5)
    elif slot == "rubber":
        detail = 1.2 * np.cos(x * 2 * np.pi * 48) * np.cos(y * 2 * np.pi * 48)
    else:
        detail = .8 * np.cos(x * 2 * np.pi * 4) * np.sin(y * 2 * np.pi * 4)
    return np.clip(color[None, None, :] + detail[:, :, None], 0, 255)


def materials():
    base = OUT / "materials"
    if (base / "revision.json").exists():
        raise SystemExit("Approved material revision is active; use tools/apply_approved_finishes.py instead of overwriting it")
    roughness = np.zeros((1024, 1024))
    metalness = np.zeros((1024, 1024))
    masks = {name: np.zeros((1024, 1024)) for name in ("primary", "secondary", "trim", "accent")}
    slots = []
    for index, (name, color, rough, metal) in enumerate(SLOTS):
        x, y = index % 4 * 256, index // 4 * 256
        roughness[y:y + 256, x:x + 256] = rough * 255
        metalness[y:y + 256, x:x + 256] = metal * 255
        mask = SLOT_CHANNEL.get(name)
        if mask:
            masks[mask][y:y + 256, x:x + 256] = 255
        slot_mask = np.zeros((1024, 1024))
        slot_mask[y:y + 256, x:x + 256] = 255
        save_image(base / "masks/slots" / (name + ".png"), slot_mask, "L")
        slots.append({"index": index, "name": name, "color": rgb(color).tolist(), "roughness": rough, "metalness": metal,
                      "rect_px": [x, y, 256, 256], "gutter_px": 8})
        save_image(base / "tiles" / (name + "_basecolor.png"), tile(name, rgb(color), 512))
        save_image(base / "tiles" / (name + "_roughness.png"), np.full((512, 512), rough * 255), "L")
    save_image(base / "shared" / "atlas_roughness.png", roughness, "L")
    save_image(base / "shared" / "atlas_metalness.png", metalness, "L")
    for name in ("atlas_roughness", "atlas_metalness"):
        image = Image.open(base / "shared" / (name + ".png"))
        image.resize((512, 512), Image.Resampling.NEAREST).save(base / "shared" / (name + "_512.png"), optimize=True)
    for name, values in masks.items():
        save_image(base / "masks" / (name + ".png"), values, "L")
    save_image(base / "masks" / "tint_rgb.png", np.stack([masks["primary"], masks["secondary"], masks["accent"]], axis=-1))
    for set_id, spec in SETS.items():
        atlas = np.zeros((1024, 1024, 3))
        for index, (name, color, _, _) in enumerate(SLOTS):
            channel = SLOT_CHANNEL.get(name)
            if channel:
                color = spec[channel]
            color = spec.get("materials", {}).get(name, color)
            x, y = index % 4 * 256, index // 4 * 256
            atlas[y:y + 256, x:x + 256] = tile(name, rgb(color))
        save_image(base / "sets" / set_id / "atlas_basecolor.png", atlas)
        Image.open(base / "sets" / set_id / "atlas_basecolor.png").resize((512, 512), Image.Resampling.LANCZOS).save(base / "sets" / set_id / "atlas_basecolor_512.png", optimize=True)
    write_json(base / "layout.json", {"id": "FZ_MaterialAtlas_v1", "size_px": 1024, "grid": 4, "slots": slots,
              "uv_origin": "bottom-left; PNG rectangles are top-left", "sets": SETS,
              "runtime": "Swap precomposed ColorMap by set; masks are offline authoring inputs, not a Roblox shader.",
              "entity_slots": {"device": ["paint_primary", "paint_secondary", "trim", "accent", "rubber", "bare_metal"],
                               "item": ["wood", "stone", "ceramic", "leather", "bare_metal"],
                               "character_clothing": ["canvas", "cloth", "cloth_trim", "leather", "bare_metal"]},
              "character_note": "Reusable clothing tiles only. A specific character needs its own UVs, skin/face maps and rig; none are implied by this library."})


def graphics():
    base = OUT / "graphics"
    base.mkdir(parents=True, exist_ok=True)
    icons = ["play", "stop", "record", "pause", "save", "restore", "volume", "mute",
             "collect", "collected", "locked", "headphones", "wave", "robot", "settings", "close"]
    atlas = Image.new("RGBA", (1024, 1024))
    rects = {}
    for index, name in enumerate(icons):
        icon = Image.new("RGBA", (256, 256))
        d = ImageDraw.Draw(icon)
        c = (255, 255, 255, 255)
        primitives = []
        def line(points, width=16):
            d.line(points, fill=c, width=width, joint="curve")
            primitives.append('<polyline points="' + ' '.join(f'{x},{y}' for x, y in points) + f'" fill="none" stroke="white" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')
        def rect(box):
            d.rounded_rectangle(box, radius=8, fill=c)
            primitives.append(f'<rect x="{box[0]}" y="{box[1]}" width="{box[2]-box[0]}" height="{box[3]-box[1]}" rx="8" fill="white"/>')
        def circle(box):
            d.ellipse(box, fill=c)
            primitives.append(f'<ellipse cx="{(box[0]+box[2])/2}" cy="{(box[1]+box[3])/2}" rx="{(box[2]-box[0])/2}" ry="{(box[3]-box[1])/2}" fill="white"/>')
        if name == "play":
            d.polygon([(86, 58), (204, 128), (86, 198)], fill=c)
            primitives.append('<path d="M86 58L204 128L86 198Z" fill="white"/>')
        elif name == "stop": rect((65, 65, 191, 191))
        elif name == "record": circle((62, 62, 194, 194))
        elif name == "pause": rect((65, 58, 108, 198)); rect((148, 58, 191, 198))
        elif name == "save":
            line([(54, 54), (202, 54), (202, 202), (54, 202), (54, 54)])
            line([(84, 54), (84, 108), (172, 108), (172, 54)])
            line([(88, 196), (88, 150), (168, 150), (168, 196)])
        elif name == "restore":
            line([(68, 96), (100, 60), (170, 60), (202, 100), (202, 170), (168, 202), (98, 202)])
            line([(56, 52), (56, 108), (112, 108)])
        elif name in ("volume", "mute"):
            line([(50, 104), (82, 104), (128, 64), (128, 192), (82, 152), (50, 152), (50, 104)])
            if name == "mute": line([(164, 100), (210, 156)]); line([(210, 100), (164, 156)])
            else: line([(160, 90), (183, 128), (160, 166)]); line([(194, 65), (224, 128), (194, 191)])
        elif name == "collected": line([(57, 132), (108, 183), (205, 72)], 22)
        elif name == "collect": line([(128, 60), (128, 196)]); line([(60, 128), (196, 128)])
        elif name == "locked":
            line([(82, 116), (82, 66), (174, 66), (174, 116)])
            line([(62, 116), (194, 116), (194, 202), (62, 202), (62, 116)])
        elif name == "headphones":
            line([(58, 160), (58, 94), (92, 56), (164, 56), (198, 94), (198, 160)])
            rect((48, 133, 88, 200)); rect((168, 133, 208, 200))
        elif name == "wave":
            line([(44 + i * 8, 128 + math.sin(i * math.pi / 4) * 55) for i in range(22)], 12)
        elif name == "robot":
            line([(50, 72), (206, 72), (206, 190), (50, 190), (50, 72)])
            rect((76, 115, 115, 135)); rect((141, 115, 180, 135))
        elif name == "settings":
            for x, y in ((70, 92), (128, 158), (186, 112)):
                line([(x, 48), (x, 208)], 10); circle((x - 18, y - 18, x + 18, y + 18))
        else: line([(68, 68), (188, 188)]); line([(188, 68), (68, 188)])
        (base / (name + ".svg")).write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">' + ''.join(primitives) + '</svg>\n', encoding="utf-8")
        x, y = index % 4 * 256, index // 4 * 256
        atlas.paste(icon, (x, y))
        rects[name] = {"offset": [x, y], "size": [256, 256]}
    atlas.save(base / "G03_G04_icons.png", optimize=True)
    for name, size, radius in (("device_face_mask", (512, 256), 28), ("display_mask", (512, 256), 20),
                               ("pad_mask", (256, 256), 28), ("panel_9slice", (64, 64), 16)):
        mask = Image.new("RGBA", size)
        ImageDraw.Draw(mask).rounded_rectangle((2, 2, size[0] - 3, size[1] - 3), radius=radius, fill="white")
        mask.save(base / (name + ".png"), optimize=True)
    sleeves = Image.new("RGBA", (1024, 1024))
    d = ImageDraw.Draw(sleeves)
    colors = [tuple(rgb(name)) for name in ("teal", "cream", "coral", "amber", "walnut", "faded")]
    for index in range(16):
        x, y = index % 4 * 256, index // 4 * 256
        d.rectangle((x + 8, y + 8, x + 247, y + 247), fill=colors[index % 6])
        for ring in range(3):
            r = 22 + ring * 27
            d.ellipse((x + 128 - r, y + 128 - r, x + 128 + r, y + 128 + r), outline=colors[(index + 2) % 6], width=8)
        d.line((x + 34, y + 214, x + 214, y + 42), fill=colors[(index + 3) % 6], width=15)
    sleeves.save(base / "G01_record_sleeves.png", optimize=True)
    # G02 original neighborhood artwork, with editable vectors and no essential text.
    posters = Image.new("RGBA", (1024, 1024))
    pd = ImageDraw.Draw(posters)
    svg = []
    for index in range(4):
        x, y = index % 2 * 512, index // 2 * 512
        color = colors[(index * 2) % len(colors)]
        csscolor = '#' + ''.join(f'{int(v):02x}' for v in color)
        pd.rounded_rectangle((x+16,y+16,x+496,y+496),radius=24,fill=color)
        svg.append(f'<rect x="{x+16}" y="{y+16}" width="480" height="480" rx="24" fill="{csscolor}"/>')
        for row in range(5):
            points=[(x+48+i*16,y+100+row*64+math.sin(i*.6+index)*20) for i in range(27)]
            pd.line(points,fill=colors[(index+2)%len(colors)],width=8)
            svg.append('<polyline points="'+' '.join(f'{a:.2f},{b:.2f}' for a,b in points)+'" fill="none" stroke="#E8D8B7" stroke-width="8"/>')
    posters.save(base / "G02_neighborhood.png", optimize=True)
    (base / "G02_neighborhood.svg").write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'+''.join(svg)+'</svg>\n')
    write_json(base / "ui-layout.json", {"icons": rects, "atlas_px": [1024, 1024], "essential_text_baked": False,
               "panel_slice_center": [18, 18, 46, 46], "mask_usage": "Alpha authoring masks. UI clips with UICorner and ClipsDescendants even without uploads."})


def audio():
    """Preserve active sources. This tool no longer synthesizes musical samples."""
    from active_content import active_audio
    current = json.loads((OUT / "audio/manifest.json").read_text(encoding="utf-8"))
    allowed = active_audio()
    current["samples"] = [row for row in current["samples"] if row["id"] in allowed]
    current["active_content_authority"] = "data/active-content.json"
    write_json(OUT / "audio/manifest.json", current)


if __name__ == "__main__":
    materials()
    graphics()
    audio()
    audio_manifest = json.loads((OUT / "audio/manifest.json").read_text())
    uploads = {"audio": [{"key": s["id"], "file": s["file"], "asset_id": None} for s in audio_manifest["samples"]], "images": []}
    for set_id in SETS:
        for size in (512, 1024):
            suffix = "_512" if size == 512 else ""
            uploads["images"].append({"key": f"atlas.{set_id}.basecolor.{size}", "file": f"assets/production/materials/sets/{set_id}/atlas_basecolor{suffix}.png", "asset_id": None})
    for channel in ("roughness", "metalness"):
        for size in (512, 1024):
            suffix = "_512" if size == 512 else ""
            uploads["images"].append({"key": f"atlas.{channel}.{size}", "file": f"assets/production/materials/shared/atlas_{channel}{suffix}.png", "asset_id": None})
    for key, file in {"ui.icons": "G03_G04_icons.png", "ui.panel": "panel_9slice.png", "ui.padmask": "pad_mask.png", "ui.displaymask": "display_mask.png", "ui.deviceface": "device_face_mask.png", "records.sleeves": "G01_record_sleeves.png"}.items():
        uploads["images"].append({"key": key, "file": "assets/production/graphics/" + file, "asset_id": None})
    uploads["policy"] = "Upload once per shared map to the experience owner. Masks/SVGs are source graphics; runtime UI can use native clipping without them. Assign only real permission-checked IDs."
    write_json(OUT / "upload-manifest.json", uploads)
    files = [{"path": p.relative_to(ROOT).as_posix(), "bytes": p.stat().st_size,
              "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(OUT.rglob("*")) if p.is_file() and p.name != "source-manifest.json"]
    write_json(OUT / "source-manifest.json", {"generator": "tools/build_content_sources.py", "palette_authority": "01_Visual_Artbook.pdf page 4",
               "provenance": "Deterministic local original pixel/vector/audio generation; no external media or provider charges.",
               "files": files})
    print(json.dumps({"files": len(files), "sets": list(SETS), "audio": len(audio_manifest["samples"]), "output": str(OUT)}))
