"""Preserve supplied native audio and measured metadata without admitting or changing it."""
from pathlib import Path, PurePosixPath
import array
from collections import defaultdict
import hashlib
import json
import math
import shutil
import subprocess
import wave
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/supplied/needle-quay-handoff-v3"
OUT = ROOT / "assets/production/needle-quay/harbour-pulse-v3"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def preserve(payload, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and target.read_bytes() != payload:
        raise ValueError("Refusing to overwrite a different production source: " + str(target))
    target.write_bytes(payload)


def wav_metadata(path):
    with wave.open(str(path), "rb") as stream:
        rate, channels, depth, frames = stream.getframerate(), stream.getnchannels(), stream.getsampwidth(), stream.getnframes()
        data = stream.readframes(frames)
        if stream.getcomptype() != "NONE":
            raise ValueError("Unexpected compressed WAV")
    if depth == 2:
        values = array.array("h", data)
    else:
        values = [int.from_bytes(data[i:i+depth], "little", signed=depth != 1) - (128 if depth == 1 else 0)
                  for i in range(0, len(data), depth)]
    full = 2 ** (depth * 8 - 1)
    peak = max((abs(value) for value in values), default=0)
    rms = math.sqrt(sum(float(value) * value for value in values) / max(1, len(values)))
    return {"duration_seconds": frames / rate, "sample_rate_hz": rate, "channels": channels,
            "pcm_bit_depth": depth * 8, "frames": frames,
            "peak_dbfs": round(20 * math.log10(peak / full), 4) if peak else None,
            "rms_dbfs": round(20 * math.log10(rms / full), 4) if rms else None,
            "clipped_samples": sum(value >= full - 1 or value <= -full for value in values)}


def main():
    current_contract = ROOT / "data/first-pack-slots.v3.json"
    if current_contract.exists():
        current = json.loads(current_contract.read_text(encoding="utf-8-sig"))
        if current.get("mapping_revision") == "pack-native-2026-10-30":
            raise SystemExit("Native sources are already preserved. The user-selected pack-native map is active; run tools/prepare_pack_native_audio.py rather than replacing it with the superseded written contract.")
    archive = SOURCE / "Needle_Quay_64_OneShot_Pack_174BPM.zip"
    rows = []
    with zipfile.ZipFile(archive) as opened:
        for entry in opened.infolist():
            if entry.is_dir():
                continue
            member = PurePosixPath(entry.filename)
            if member.is_absolute() or ".." in member.parts:
                raise ValueError("Unsafe archive member")
            target = OUT / "source-pack" / Path(*member.parts)
            preserve(opened.read(entry), target)
            row = {"archive_member": entry.filename, "file": target.relative_to(ROOT).as_posix(),
                   "sha256": digest(target), "bytes": target.stat().st_size,
                   "source_archive": archive.relative_to(ROOT).as_posix(), "source_archive_sha256": digest(archive),
                   "runtime_admitted": False, "audio_approved": False,
                   "canonical_slot": None, "verified_pitch": None,
                   "mapping_status": "unmapped_source_preserved", "listening_review": "pending"}
            if target.suffix.lower() == ".wav":
                row.update(wav_metadata(target))
            rows.append(row)
    song = SOURCE / "Needle Quay Waves.m4a"
    target = OUT / "source-song" / song.name
    preserve(song.read_bytes(), target)
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(target)],
                           capture_output=True, text=True, check=True)
    raw = json.loads(probe.stdout)
    audio = next(row for row in raw["streams"] if row["codec_type"] == "audio")
    song_row = {"file": target.relative_to(ROOT).as_posix(), "source": song.relative_to(ROOT).as_posix(),
                "sha256": digest(target), "bytes": target.stat().st_size,
                "duration_seconds": float(raw["format"]["duration"]), "codec": audio["codec_name"],
                "sample_rate_hz": int(audio["sample_rate"]), "channels": audio["channels"],
                "audio_approved": False, "runtime_admitted": False, "purpose": "production_reference_only"}
    hashes = defaultdict(list)
    for row in rows:
        hashes[row["sha256"]].append(row["archive_member"])
    duplicates = [{"sha256": sha, "members": members} for sha, members in hashes.items() if len(members) > 1]
    manifest = {"schema": 1, "pack_id": "nq_harbour_01", "planning_revision": 3,
                "supplied_provenance": "assets/supplied/needle-quay-handoff-v3/INTAKE_PROVENANCE.json",
                "status": "native_sources_preserved_pending_review", "source_pack": rows, "source_song": song_row,
                "user_mapping_decision": "Keep the written map; leave mismatched slots pending",
                "source_layout": {"Drums": 16, "Bass": 16, "MC_Vocals": 16, "Harbour_FX___Melodics": 16},
                "written_layout": {"A": "Drums", "B": "Bass", "C": "Melody and harmony", "D": "12 harbour and 4 vocals"},
                "admitted_audio": [], "renamed_audio": [], "provider_calls": 0, "uploads": 0,
                "duplicate_source_files": duplicates,
                "review_notes": ["Source ordinals do not grant canonical addresses.",
                                 "No source file was converted, pitch-labelled, relabelled or approved.",
                                 "Filename '16_Break_Fill_2-Bar.wav' requires one-shot review; its filename is not measured musical length.",
                                 "Matching lyric filenames may inform review, but no D13/D14 binding is inferred."]}
    if duplicates:
        manifest["review_notes"].append("The supplied archive has 64 named WAV files but only 63 unique byte contents; duplicate names are preserved and not admitted as separate instrument identities.")
    write_json(OUT / "intake-manifest.json", manifest)
    planned = json.loads((SOURCE / "FIRST_PACK_64_SLOTS.json").read_text(encoding="utf-8-sig"))
    write_json(ROOT / "data/first-pack-slots.v3.json", planned)
    write_json(OUT / "pending-slot-bindings.json", {"schema": 1, "pack_id": "nq_harbour_01",
               "decision": manifest["user_mapping_decision"], "slots": [
                   {"address": row["address"], "sample_id": row["sample_id"], "label": row["label"],
                    "file": None, "audio_approved": False, "runtime_admitted": False,
                    "status": "pending_exact_role_and_approval_review"} for row in planned["slots"]]})
    print(json.dumps({"preserved_wavs": len(rows), "preserved_full_songs": 1, "admitted_audio": 0}))


if __name__ == "__main__":
    main()
