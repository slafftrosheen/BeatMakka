"""Inspect the existing audio batch and optionally write a local audition reel.

No uploads, network calls, binding changes, regeneration, or asset-stage promotion.
"""
import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import sys
import wave

from configure_content import manifest_keys, read_json, validate_mapping

ROOT = Path(__file__).resolve().parents[1]


def inspect_batch(audition=None):
    upload = read_json(ROOT / "assets/production/upload-manifest.json")
    bindings = validate_mapping(read_json(ROOT / "data/content-ids.json"), manifest_keys(upload))
    source = read_json(ROOT / "assets/production/audio/manifest.json")
    samples = source["samples"]
    ids = [entry["id"] for entry in samples]
    if len(ids) != len(set(ids)) or set(ids) != {entry["key"] for entry in upload["audio"]}:
        raise ValueError("Source and upload manifests must have identical unique audio keys")
    upload_paths = {entry["key"]: entry["file"] for entry in upload["audio"]}
    rows, chapters = [], []
    reel = array("h", [0]) * 22050
    for entry in samples:
        relative = entry["file"]
        path = (ROOT / relative).resolve()
        if not path.is_relative_to(ROOT) or upload_paths[entry["id"]] != relative:
            raise ValueError("Unsafe or inconsistent source path: " + relative)
        raw = path.read_bytes()
        with wave.open(str(path), "rb") as audio:
            rate, channels, width = audio.getframerate(), audio.getnchannels(), audio.getsampwidth()
            frames = audio.getnframes()
            pcm = audio.readframes(frames)
            compression = audio.getcomptype()
        if compression != "NONE" or width != 2 or channels != 1 or rate != 44100:
            raise ValueError("Expected this project's mono 44.1-kHz PCM16 source: " + relative)
        if len(pcm) != frames * channels * width or not frames:
            raise ValueError("Truncated or empty source: " + relative)
        values = array("h")
        values.frombytes(pcm)
        if sys.byteorder != "little":
            values.byteswap()
        peak = max(abs(value) for value in values)
        rms = math.sqrt(sum(value * value for value in values) / len(values))
        duration = frames / rate
        peak_db = 20 * math.log10(peak / 32768) if peak else None
        rms_db = 20 * math.log10(rms / 32768) if rms else None
        meets_import_format = len(raw) < 20_000_000 and duration < 420 and rate <= 48000
        metadata_matches = (
            entry["sample_rate"] == rate and entry["channels"] == channels
            and abs(entry["duration_seconds"] - duration) <= 1 / rate
            and peak_db is not None and abs(entry["peak_dbfs"] - peak_db) <= 0.05
            and rms_db is not None and abs(entry["rms_dbfs"] - rms_db) <= 0.05
        )
        rows.append({
            "key": entry["id"], "file": relative, "sha256": hashlib.sha256(raw).hexdigest(),
            "proposed_name": "Frequency Zero - " + entry["id"].replace("_", " "),
            "bytes": len(raw), "frames": frames, "sample_rate": rate, "channels": channels,
            "sample_width_bytes": width, "duration_seconds": round(duration, 6),
            "peak_dbfs": round(peak_db, 3) if peak_db is not None else None,
            "rms_dbfs": round(rms_db, 3) if rms_db is not None else None,
            "clipped_samples": sum(value in (-32768, 32767) for value in values),
            "import_format_pass": meets_import_format, "authored_metadata_matches": metadata_matches,
            "rights_as_recorded": entry.get("rights"),
            "existing_asset_id": bindings["Audio"].get(entry["id"]),
            "upload_receipt": None, "moderation_verified": False, "experience_permission_verified": False,
        })
        if audition:
            start = len(reel) / rate
            reel.extend(int(value * 0.5) for value in values)
            chapters.append({"key": entry["id"], "start_seconds": round(start, 3),
                             "end_seconds": round(len(reel) / rate, 3)})
            reel.extend([0] * 11025)
    if audition:
        audition.parent.mkdir(parents=True, exist_ok=True)
        if sys.byteorder != "little":
            reel.byteswap()
        with wave.open(str(audition), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(44100)
            output.writeframes(reel.tobytes())
    return {
        "schema": 1, "scope": "Local source inspection only; not an upload or listening acceptance",
        "source_count": len(rows), "bound_audio_count": len(bindings["Audio"]),
        "preserved_image_binding_count": len(bindings["Images"]),
        "all_formats_pass": all(row["import_format_pass"] for row in rows),
        "all_authored_metadata_matches": all(row["authored_metadata_matches"] for row in rows),
        "clipped_samples": sum(row["clipped_samples"] for row in rows),
        "total_bytes": sum(row["bytes"] for row in rows),
        "destination_owner": None, "destination_universe_id": None,
        "submission_authorized": False, "upload_route_verified": False,
        "audio": rows,
        "audition": {"gain_db": round(20 * math.log10(0.5), 3), "chapters": chapters} if audition else None,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Write an inspection/batch JSON; otherwise print it")
    parser.add_argument("--audition", type=Path, help="Write a separate half-amplitude local review WAV")
    args = parser.parse_args()
    report = inspect_batch(args.audition)
    encoded = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
        print(json.dumps({key: report[key] for key in (
            "source_count", "bound_audio_count", "preserved_image_binding_count", "all_formats_pass",
            "all_authored_metadata_matches", "clipped_samples", "total_bytes",
        )}, indent=2))
    else:
        print(encoded, end="")
    return 0 if report["all_formats_pass"] and report["all_authored_metadata_matches"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
