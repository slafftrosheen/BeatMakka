"""Build/verify a closed Kenney audition package; never bind or upload it.

Official archives must already be downloaded. Only the nine explicit members
below are extracted. --verify is offline and does not rewrite a reviewed package.
"""
from __future__ import annotations

import argparse
from array import array
import base64
import hashlib
import html
import json
import math
from pathlib import Path
import subprocess
import sys
import wave
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "assets/candidates/audio/quay-found-v1"
REVIEW = ROOT / "output/audio-quay-found-v1"
RATE = 44100
PACKS = {
    "impact-sounds": {
        "sha256": "029d734af1582474edf3a694d1b0cebc97c1c152f2f39fa34d4c2bafc5de77f8",
        "url": "https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip",
        "page": "https://kenney.nl/assets/impact-sounds", "version": "1.0",
    },
    "digital-audio": {
        "sha256": "24e6ce28b76a6d8c89cff4d331e0965ff5c3de8a73c612028e9d363cc64e4f06",
        "url": "https://kenney.nl/media/pages/assets/digital-audio/216eac4753-1677590265/kenney_digital-audio.zip",
        "page": "https://kenney.nl/assets/digital-audio", "version": "1.0",
    },
}
# Status is a proposal/category decision, never a claim to have listened.
CHOICES = [
    ("impact-sounds", "impactWood_light_000", "rim", "proposed"),
    ("impact-sounds", "impactWood_light_002", "rim", "alternative"),
    ("impact-sounds", "impactMetal_light_000", "metal_hit", "proposed"),
    ("impact-sounds", "impactMetal_light_002", "metal_hit", "alternative"),
    ("impact-sounds", "impactSoft_heavy_000", "vent_thump", "proposed"),
    ("impact-sounds", "impactPlate_heavy_000", "metal_hit", "excluded-heavy-plate-category"),
    ("digital-audio", "pepSound1", "robot_chirp", "proposed"),
    ("digital-audio", "twoTone1", "robot_chirp", "alternative"),
    ("digital-audio", "laser1", "robot_chirp", "excluded-laser-category"),
]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_wav(path: Path, values: list[float]) -> None:
    if not values or max(abs(x) for x in values) >= 1:
        raise ValueError("Empty or clipping review audio: " + str(path))
    pcm = array("h", (round(x * 32767) for x in values))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(path), "wb") as target:
        target.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        target.writeframes(pcm.tobytes())


def read_wav(path: Path) -> list[float]:
    with wave.open(str(path), "rb") as source:
        if (source.getnchannels(), source.getsampwidth(), source.getframerate()) != (1, 2, RATE):
            raise ValueError("Expected mono PCM16 44100 Hz: " + str(path))
        samples = array("h", source.readframes(source.getnframes()))
    if sys.byteorder != "little":
        samples.byteswap()
    return [x / 32768 for x in samples]


def levels(values: list[float]) -> dict:
    peak = max(abs(x) for x in values)
    rms = math.sqrt(sum(x * x for x in values) / len(values))
    return {"duration_seconds": round(len(values) / RATE, 6),
            "peak_dbfs": round(20 * math.log10(peak), 3) if peak else None,
            "rms_dbfs": round(20 * math.log10(rms), 3) if rms else None,
            "clipped_samples": sum(abs(x) >= 32767 / 32768 for x in values)}


def derive(source: Path, target: Path) -> dict:
    run = subprocess.run(["ffmpeg", "-v", "error", "-i", str(source), "-map", "0:a:0",
                          "-ac", "1", "-ar", str(RATE), "-f", "f32le", "pipe:1"],
                         capture_output=True, check=True)
    floats = array("f", run.stdout)
    if sys.byteorder != "little":
        floats.byteswap()
    if not floats or any(not math.isfinite(x) for x in floats):
        raise ValueError("Invalid decoded audio")
    dc = sum(floats) / len(floats)
    values = [x - dc for x in floats]
    peak = max(abs(x) for x in values)
    if not peak:
        raise ValueError("Silent source")
    active = [i for i, x in enumerate(values) if abs(x) >= peak * 0.001]
    start, end = max(0, active[0] - 88), min(len(values), active[-1] + 442)
    values = values[start:end]
    for i in range(min(22, len(values))):
        values[i] *= i / 22
    for i in range(min(353, len(values))):
        values[-i - 1] *= i / 353
    rms = math.sqrt(sum(x * x for x in values) / len(values))
    gain = min(10 ** (-24 / 20) / rms, 10 ** (-9 / 20) / max(abs(x) for x in values), 4)
    write_wav(target, [x * gain for x in values])
    return {"decode": "FFmpeg mono downmix, 44100 Hz float intermediate",
            "dc_removed": round(dc, 9), "trim_source_frames": [start, end],
            "onset_fade_frames": 22, "tail_fade_frames": 353,
            "gain_db": round(20 * math.log10(gain), 6), "pitch_change": False,
            "output": "mono 44100 Hz PCM16 WAV", "measurements": levels(read_wav(target))}


def mix(overrides: dict[str, Path], target: Path) -> dict:
    # Same authored phrase and gain in A/B; no UI cues or ambience in the music mix.
    notes = {"kick": [0, 4, 8, 12], "snare": [4, 12], "closed_hat": list(range(0, 16, 2)),
             "rim": [2, 10], "bass_c": [0, 8], "bass_eb": [4], "bass_g": [12],
             "metal_hit": [6, 14], "vent_thump": [0], "robot_chirp": [15]}
    step = 60 / 96 / 4
    length = round((16 * step * 2 + 3) * RATE)
    result = [0.0] * length
    for key, steps in notes.items():
        values = read_wav(overrides.get(key, ROOT / "assets/production/audio" / (key + ".wav")))
        for bar in range(2):
            for index in steps:
                offset = round((bar * 16 + index) * step * RATE)
                for n, value in enumerate(values):
                    if offset + n < length:
                        result[offset + n] += value * 0.25
    write_wav(target, result)
    return {**levels(read_wav(target)), "bpm": 96, "bars": 2, "mix_gain_db": -12.0412,
            "includes_ui_or_ambience": False, "notes": notes}


def verify() -> dict:
    manifest = json.loads((PACKAGE / "manifest.json").read_text())
    files = {p.relative_to(PACKAGE).as_posix() for p in PACKAGE.rglob("*") if p.is_file()}
    if files != set(manifest["file_hashes"]) | {"manifest.json"}:
        raise ValueError("Package roster changed")
    for name, expected in manifest["file_hashes"].items():
        path = PACKAGE / name
        if not path.resolve().is_relative_to(PACKAGE.resolve()) or path.is_symlink() or digest(path) != expected:
            raise ValueError("Package integrity failed: " + name)
    for name, expected in manifest["canonical_file_hashes"].items():
        path = ROOT / name
        if not path.resolve().is_relative_to(ROOT) or digest(path) != expected:
            raise ValueError("Canonical source/binding changed: " + name)
    for entry in manifest["candidates"]:
        for path_key, hash_key in (("source_file", "source_sha256"), ("derived_file", "derived_sha256"),
                                   ("license_file", "license_sha256")):
            if manifest["file_hashes"].get(entry[path_key]) != entry[hash_key]:
                raise ValueError("Candidate provenance contradicts roster: " + entry["id"])
        measurement = levels(read_wav(PACKAGE / entry["derived_file"]))
        if measurement["clipped_samples"] or measurement["duration_seconds"] > 3:
            raise ValueError("Audio constraints failed: " + entry["id"])
    for name, expected in manifest.get("review_file_hashes", {}).items():
        path = REVIEW / name
        if not path.resolve().is_relative_to(REVIEW.resolve()) or digest(path) != expected:
            raise ValueError("Review artifact changed: " + name)
    if manifest["listening_approved"]:
        selection = json.loads((PACKAGE / manifest["approval_record"]).read_text())
        expected = {entry["canonical_id"]: entry["id"] for entry in manifest["candidates"]
                    if entry.get("listening_status") == "USER_APPROVED"}
        if selection["selected"] != expected or len(expected) != 4:
            raise ValueError("Selection contradicts approved candidate records")
        registry = json.loads((ROOT / "data/audio-source-revisions.json").read_text())
        revision = registry["revisions"]["quay-found-v1"]
        if registry["default"] != "original-synthesis-v1" or revision["runtime_bound"] is not False \
                or set(revision["selected_canonical_ids"]) != set(expected):
            raise ValueError("Revision registry contradicts preserved fallback or selection")
    return {"passed": True, "candidate_count": len(manifest["candidates"]),
            "closed_roster_files": len(manifest["file_hashes"]),
            "canonical_files_preserved": len(manifest["canonical_file_hashes"]),
            "listening_approved": manifest["listening_approved"], "runtime_admitted": False}


def build(archives: Path) -> None:
    if PACKAGE.exists() or REVIEW.exists():
        raise ValueError("Existing audition must be verified/reviewed, not overwritten")
    for pack, contract in PACKS.items():
        if digest(archives / (pack + ".zip")) != contract["sha256"]:
            raise ValueError("Unexpected archive digest: " + pack)
    for directory in ("originals", "derived", "licenses"):
        (PACKAGE / directory).mkdir(parents=True, exist_ok=False)
    REVIEW.mkdir(parents=True, exist_ok=False)
    (PACKAGE / "licenses/CC0-1.0.reference.json").write_text(json.dumps({
        "license": "CC0-1.0", "deed": "https://creativecommons.org/publicdomain/zero/1.0/",
        "legal_code": "https://creativecommons.org/publicdomain/zero/1.0/legalcode.en",
        "reviewed_on": "2026-10-23",
        "evidence": "Official creator pages, unmodified archive License.txt files and CC official legal-code page",
        "note": "Direct plain-text retrieval returned HTTP403; no substitute legal text or modified license is supplied",
    }, indent=2) + "\n")
    for pack in PACKS:
        with zipfile.ZipFile(archives / (pack + ".zip")) as archive:
            license_bytes = archive.read("License.txt")
            if b"Creative Commons Zero, CC0" not in license_bytes:
                raise ValueError("Archive license does not match CC0: " + pack)
            (PACKAGE / "licenses" / (pack + ".txt")).write_bytes(license_bytes)
    candidates, overrides = [], {}
    for pack, name, canonical, decision in CHOICES:
        source = PACKAGE / "originals" / (name + ".ogg")
        with zipfile.ZipFile(archives / (pack + ".zip")) as archive:
            source.write_bytes(archive.read("Audio/" + name + ".ogg"))
        derived = PACKAGE / "derived" / (name + ".wav")
        edits = derive(source, derived)
        if decision == "proposed":
            overrides[canonical] = derived
        candidates.append({"id": name, "canonical_id": canonical, "category": "musical-pad",
            "decision": decision, "listening_status": "PENDING", "author": "Kenney Vleugels / Kenney",
            "pack": pack, "pack_version": PACKS[pack]["version"],
            "source_page": PACKS[pack]["page"], "source_archive_url": PACKS[pack]["url"],
            "archive_sha256": PACKS[pack]["sha256"], "archive_member": "Audio/" + name + ".ogg",
            "source_file": source.relative_to(PACKAGE).as_posix(), "source_sha256": digest(source),
            "derived_file": derived.relative_to(PACKAGE).as_posix(), "derived_sha256": digest(derived),
            "license": "CC0-1.0", "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
            "license_file": "licenses/" + pack + ".txt", "license_sha256": digest(PACKAGE / "licenses" / (pack + ".txt")),
            "reviewed_on": "2026-10-23", "credit": "Sounds by Kenney (kenney.nl), edited for Frequency Zero.",
            "rights_assessment": {"repository_redistribution": "permitted by CC0",
                "roblox_hosting": "permitted by CC0; platform moderation/permissions still required",
                "isolated_sampler_use": "permitted by CC0; no isolated-sample restriction stated",
                "evidence": "Official creator page and license inside creator-distributed archive; no endorsement claimed"},
            "edits": edits})
    original_mix = mix({}, REVIEW / "original-pattern.wav")
    candidate_mix = mix(overrides, REVIEW / "candidate-pattern.wav")
    canonical = [ROOT / "data/content-ids.json", ROOT / "src/shared/ContentIds.luau",
                 ROOT / "src/shared/SampleCatalog.luau", ROOT / "assets/production/upload-manifest.json"]
    canonical.extend(sorted((ROOT / "assets/production/audio").glob("*")))
    manifest = {"schema": 1, "revision": "quay-found-v1-candidate", "stage": "candidate",
                "listening_approved": False, "runtime_admitted": False, "candidates": candidates,
                "fallback": "Original synthesized 24-file library; no source or binding changed",
                "mix_comparison": {"original": original_mix, "candidate": candidate_mix},
                "canonical_file_hashes": {p.relative_to(ROOT).as_posix(): digest(p) for p in canonical if p.is_file()},
                "file_hashes": {p.relative_to(PACKAGE).as_posix(): digest(p) for p in sorted(PACKAGE.rglob("*")) if p.is_file()}}
    (PACKAGE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    review_page(manifest)
    manifest["review_file_hashes"] = {p.relative_to(REVIEW).as_posix(): digest(p)
                                     for p in sorted(REVIEW.rglob("*")) if p.is_file()}
    (PACKAGE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def review_page(manifest: dict) -> None:
    def player(path: Path) -> str:
        return '<audio controls preload="none" src="data:audio/wav;base64,' + base64.b64encode(path.read_bytes()).decode() + '"></audio>'
    cards = []
    for entry in manifest["candidates"]:
        name, canonical = entry["id"], entry["canonical_id"]
        status = "Selected after user listening review." if entry.get("listening_status") == "USER_APPROVED" else "Not selected." if manifest["listening_approved"] else "Listening decision pending."
        decision = "selected" if entry.get("listening_status") == "USER_APPROVED" else entry["decision"]
        cards.append('<article><h2>' + html.escape(name) + '</h2><p>' + html.escape(canonical + ' · ' + decision) + '</p><div class="compare"><section><h3>A · Original synthesis</h3>' + player(ROOT / "assets/production/audio" / (canonical + ".wav")) + '</section><section><h3>B · Edited CC0 candidate</h3>' + player(PACKAGE / entry["derived_file"]) + '</section></div><p>CC0-1.0 · Kenney · ' + html.escape(str(entry["edits"]["measurements"]["duration_seconds"])) + ' seconds. ' + status + '</p></article>')
    document = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Quay Found Sounds — audition</title><style>
body{margin:0;background:#f5eedc;color:#162322;font:16px/1.6 system-ui,sans-serif}main{max-width:1000px;margin:auto;padding:32px 20px}h1{font-size:clamp(28px,5vw,48px);line-height:1.1}h2{font-size:20px;overflow-wrap:anywhere}h3{font-size:15px}article{border-top:1px solid #b79c7e;padding:24px 0}.compare{display:grid;grid-template-columns:1fr 1fr;gap:24px}audio{width:100%;max-width:440px}a{color:#2f5c58}.note{border-left:4px solid #ca7453;padding:12px 18px;background:#e8d8b7}button{padding:12px 18px;background:#2f5c58;color:#faf4e6;border:0;border-radius:6px;font:inherit;cursor:pointer}button:focus-visible,a:focus-visible,audio:focus-visible{outline:3px solid #ca7453;outline-offset:4px}@media(max-width:620px){.compare{grid-template-columns:1fr}}@media(prefers-reduced-motion:reduce){*{scroll-behavior:auto}}
</style><main><p>FREQUENCY ZERO / SOURCE AUDITION / 23 OCT 2026</p><h1>A small sound family for the quay.</h1><p class="note">Candidate review only. Four proposed replacements, three alternatives, two category exclusions. The original bank stays intact. Begin at a comfortable volume. This page does not upload or approve any sound.</p><button id="stop" type="button">Stop all previews</button><h2>The same pattern, two source revisions</h2><p>96 BPM, two bars, identical arrangement and −12.04 dB mix gain. No UI cues or ambience. Both mixes passed the sample-peak clipping check; listening and Roblox acceptance remain separate.</p><div class="compare"><section><h3>A · Original bank</h3>''' + player(REVIEW / "original-pattern.wav") + '''</section><section><h3>B · Four proposed CC0 replacements</h3>''' + player(REVIEW / "candidate-pattern.wav") + '''</section></div>''' + ''.join(cards) + '''<footer><p>Sources: <a href="https://kenney.nl/assets/impact-sounds">Kenney Impact Sounds</a> · <a href="https://kenney.nl/assets/digital-audio">Kenney Digital Audio</a> · <a href="https://creativecommons.org/publicdomain/zero/1.0/">CC0 1.0</a></p><p>Credit: Sounds by Kenney (kenney.nl), edited for Frequency Zero. No endorsement implied. Keep musical pads separate from UI cues and ambience.</p></footer></main><script>
const previews=[...document.querySelectorAll('audio')];for(const current of previews){current.addEventListener('play',()=>{for(const other of previews){if(other!==current){other.pause();other.currentTime=0}}})}document.getElementById('stop').addEventListener('click',()=>{for(const sound of previews){sound.pause();sound.currentTime=0}});
</script></html>'''
    if manifest["listening_approved"]:
        document = document.replace("Candidate review only. Four proposed replacements", "User listening selection approved. Four selected replacements")
        document = document.replace("B · Four proposed CC0 replacements", "B · Four selected CC0 replacements")
        document = document.replace("This page does not upload or approve any sound.", "No Roblox upload, moderation or runtime acceptance is implied.")
    (REVIEW / "index.html").write_text(document, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archives", type=Path)
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if not args.verify:
        if not args.archives:
            parser.error("Build requires --archives; no network fetching is implicit")
        build(args.archives)
    print(json.dumps(verify(), indent=2))


if __name__ == "__main__":
    main()
