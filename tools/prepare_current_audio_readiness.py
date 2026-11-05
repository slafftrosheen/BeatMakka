"""Inventory current audio sources and recorded bindings without contacting Roblox.

This complements the historical prepare_audio_acceptance.py receipt. It never
changes sources, content bindings, approval flags, upload receipts or asset stages.
An absent binding/receipt means unrecorded locally, not proof an upload is missing.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import wave

from active_content import active_audio, load_authority, preview_audio
from configure_content import read_json, render_luau

ROOT = Path(__file__).resolve().parents[1]
RECEIPTS = (
    "docs/evidence/a01-05/authorized-original-batch.json",
    "docs/evidence/style-starters/roblox-uploads.json",
)
INPUTS = (
    "data/active-content.json", "data/first-pack-slots.v3.json",
    "data/content-ids.json", "src/shared/ContentIds.luau",
    "src/shared/LocalContent.luau", "assets/local-demo/install-manifest.json",
    "assets/production/audio/manifest.json",
)


def repository_file(relative: str) -> Path:
    path = (ROOT / relative).resolve()
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError("Expected an existing repository file: " + relative)
    return path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pcm_values(raw: bytes, width: int):
    if width == 1:
        return (value - 128 for value in raw)
    if width in (2, 4):
        return (value[0] for value in struct.iter_unpack("<h" if width == 2 else "<i", raw))
    if width == 3:
        return (int.from_bytes(raw[index:index + 3], "little", signed=True)
                for index in range(0, len(raw), 3))
    raise ValueError("Unsupported PCM sample width: " + str(width))


def inspect_wav(relative: str) -> dict:
    path = repository_file(relative)
    with wave.open(str(path), "rb") as stream:
        frames, rate = stream.getnframes(), stream.getframerate()
        channels, width = stream.getnchannels(), stream.getsampwidth()
        compression = stream.getcomptype()
        raw = stream.readframes(frames)
    if compression != "NONE" or frames <= 0 or len(raw) != frames * channels * width:
        raise ValueError("Expected complete, nonempty uncompressed PCM: " + relative)
    peak, square_sum, nonzero, clipped = 0, 0, 0, 0
    full_scale = 2 ** (width * 8 - 1)
    for value in pcm_values(raw, width):
        peak = max(peak, abs(value))
        square_sum += value * value
        nonzero += value != 0
        clipped += value in (-full_scale, full_scale - 1)
    count = frames * channels
    rms = math.sqrt(square_sum / count)
    return {
        "file": relative, "sha256": digest(path), "bytes": path.stat().st_size,
        "frames": frames, "sample_rate_hz": rate, "channels": channels,
        "pcm_bit_depth": width * 8, "compression": compression,
        "duration_seconds": frames / rate,
        "peak_dbfs": round(20 * math.log10(peak / full_scale), 4) if peak else None,
        "rms_dbfs": round(20 * math.log10(rms / full_scale), 4) if rms else None,
        "nonzero_pcm_samples": nonzero, "clipped_samples": clipped,
        "measurement_boundary": "All interleaved channels; file measurements, not listening acceptance",
    }


def recorded_uploads():
    rows, sources = [], []
    for relative in RECEIPTS:
        path = repository_file(relative)
        receipt = read_json(path)
        entries = receipt.get("audio", receipt.get("assets", []))
        if not isinstance(entries, list):
            raise ValueError("Unexpected historical audio receipt: " + relative)
        with_ids = 0
        for entry in entries:
            identity = entry.get("key")
            asset_id = entry.get("asset_id", entry.get("existing_asset_id"))
            if type(asset_id) is int and 0 < asset_id < 2 ** 53:
                rows.append({
                    "receipt": relative, "recorded_key": identity,
                    "source_sha256": entry.get("sha256"), "asset_id": asset_id,
                    "recorded_stage": entry.get("stage"),
                    "current_permissions_verified": False,
                })
                with_ids += 1
        sources.append({"file": relative, "sha256": digest(path),
                        "recorded_entries": len(entries), "entries_with_asset_ids": with_ids,
                        "scope": "Historical local receipt; no current owner/permission verification"})
    return rows, sources


def inspect_current() -> dict:
    authority = load_authority()
    plan = read_json(repository_file(authority["planned_contract"]))
    admitted, previews = active_audio(), preview_audio()
    bindings = read_json(repository_file("data/content-ids.json"))
    local_source = repository_file("src/shared/LocalContent.luau").read_text(encoding="utf-8")
    payload = re.search(r"JSONDecode\(\[=\[(.*)\]=\]\)", local_source, re.DOTALL)
    if not payload:
        raise ValueError("Expected the generated LocalContent JSON projection")
    local_content = json.loads(payload.group(1))
    install = read_json(repository_file("assets/local-demo/install-manifest.json"))
    package_rows = {row["file"]: row for row in install["files"]}
    history, receipt_sources = recorded_uploads()
    source_manifest = read_json(repository_file("assets/production/audio/manifest.json"))
    source_rows = {row["id"]: row for row in source_manifest["samples"]}
    errors = []
    if set(bindings) != {"Audio", "Images"}:
        errors.append("Canonical binding sections differ from Audio/Images")
    if repository_file("src/shared/ContentIds.luau").read_text(encoding="utf-8") != render_luau(bindings):
        errors.append("Runtime ContentIds projection differs from canonical content-ids.json")
    for identity, asset_id in bindings.get("Audio", {}).items():
        if identity not in admitted or type(asset_id) is not int or not 0 < asset_id < 2 ** 53:
            errors.append("Invalid or inactive canonical Audio binding: " + identity)
    slots = plan["slots"]
    expected_addresses = [f"{bank}{pad:02}" for bank in "ABCD" for pad in range(1, 17)]
    if (len(slots) != 64 or len({row["sample_id"] for row in slots}) != 64
            or [row["address"] for row in slots] != expected_addresses):
        errors.append("Expected 64 unique musical identities in canonical A01..D16 order")

    def row_for(identity, source, musical, slot=None):
        measured = inspect_wav(source["file"])
        metadata = dict(source_rows.get(identity, {}))
        metadata.update(source)
        mismatch = []
        for key in ("sha256", "bytes", "channels", "pcm_bit_depth", "nonzero_pcm_samples", "clipped_samples"):
            if key in metadata and measured[key] != metadata[key]:
                mismatch.append(key)
        for key, alias in (("sample_rate_hz", "sample_rate"),):
            authored = metadata.get(key, metadata.get(alias))
            if authored is not None and measured[key] != authored:
                mismatch.append(key)
        for key, tolerance in (("duration_seconds", 1 / measured["sample_rate_hz"]),
                               ("peak_dbfs", 0.05), ("rms_dbfs", 0.05)):
            if key in metadata:
                expected, actual = metadata[key], measured[key]
                if ((expected is None) != (actual is None)
                        or expected is not None and abs(expected - actual) > tolerance):
                    mismatch.append(key)
        preview = identity in previews
        section = "PreviewAudio" if preview else "Audio"
        packaged = ("preview-audio/" if preview else "audio/") + identity + ".wav"
        expected_uri = "rbxasset://needle-quay/" + packaged
        local_uri = local_content.get(section, {}).get(identity)
        packaged_path = repository_file("assets/local-demo/content/needle-quay/" + packaged)
        packaged_sha = digest(packaged_path)
        package_entry = package_rows.get(packaged)
        package_matches = bool(package_entry and package_entry["sha256"] == measured["sha256"]
                               and package_entry["bytes"] == measured["bytes"]
                               and packaged_sha == measured["sha256"])
        if mismatch:
            errors.append(identity + ": source metadata mismatch: " + ", ".join(mismatch))
        if local_uri != expected_uri or not package_matches:
            errors.append(identity + ": generated local binding/package differs from source")
        matching = [entry for entry in history if entry["source_sha256"] == measured["sha256"]]
        asset_id = bindings.get("Audio", {}).get(identity)
        pending = ["intended_owner_and_destination_not_recorded",
                   "current_moderation_and_experience_permissions_unverified",
                   "intended_experience_loading_and_audible_playback_unobserved"]
        if asset_id is None:
            pending.append("canonical_remote_binding_not_recorded")
        if musical and source.get("audio_approved") is not True:
            pending.append("musical_listening_approval_pending")
        if musical and source.get("runtime_admitted") is not True:
            pending.append("runtime_admission_pending")
        return {
            "id": identity, "address": slot["address"] if slot else None,
            "label": slot["label"] if slot else identity,
            "category": slot["category"] if slot else source["category"],
            "state_as_recorded": "local_preview_pending_listening" if preview
                else "admitted_musical_source" if musical else "retained_nonmusical_source",
            "measured": measured, "authored_metadata_mismatches": mismatch,
            "source_provenance_as_recorded": source.get("source_provenance"),
            "rights_as_recorded": metadata.get("rights"),
            "audio_approved_as_recorded": source.get("audio_approved"),
            "runtime_admitted_as_recorded": source.get("runtime_admitted"),
            "approval_receipt_as_recorded": source.get("approval"),
            "current_canonical_asset_id": asset_id,
            "local_binding_section": section, "local_binding_uri": local_uri,
            "local_package_file": packaged, "local_package_matches_source": package_matches,
            "recorded_historical_hash_matches": matching,
            "reconciliation": {
                "local_source_reusable": not mismatch and package_matches,
                "recorded_remote_candidate": "bound_id_requires_review" if asset_id else
                    "historical_hash_match_requires_review" if matching else "not_recorded_locally",
                "genuinely_missing_upload": "unknown_until_authorized_inventory_reconciliation",
                "pending": pending,
                "next_action": "Review the final source/version, then reconcile the authorized intended owner's inventory and unknown outcomes before any named submission; verify exact hash and destination permissions before reuse.",
            },
        }

    musical = []
    for slot in slots:
        identity = slot["sample_id"]
        source = previews.get(identity) or admitted.get(identity)
        if not source:
            raise ValueError("Musical identity lacks a current local source: " + identity)
        musical.append(row_for(identity, source, True, slot))
    nonmusical = [row_for(row["id"], row, False) for row in authority["nonmusical_audio"]]
    if set(local_content.get("Audio", {})) != set(admitted):
        errors.append("LocalContent.Audio differs from the active admitted/nonmusical inventory")
    if set(local_content.get("PreviewAudio", {})) != set(previews):
        errors.append("LocalContent.PreviewAudio differs from the explicit preview inventory")
    auxiliary = []
    for relative, recorded in sorted(package_rows.items()):
        if (Path(relative).suffix.lower() not in (".wav", ".mp3", ".ogg")
                or relative.startswith(("audio/", "preview-audio/"))):
            continue
        path = repository_file("assets/local-demo/content/needle-quay/" + relative)
        sha = digest(path)
        matches = sha == recorded["sha256"] and path.stat().st_size == recorded["bytes"]
        if not matches:
            errors.append("Auxiliary packaged audio differs from install manifest: " + relative)
        auxiliary.append({"file": relative, "sha256": sha, "bytes": path.stat().st_size,
                          "matches_install_manifest": matches,
                          "scope": "Separate ambience/voice payload; excluded from 64 musical samples and five retained Audio bindings; no listening/permission claim"})
    all_rows = musical + nonmusical
    return {
        "schema": 1, "generated_utc": datetime.now(timezone.utc).isoformat(),
        "scope": "Offline source/binding/receipt reconciliation only; no network, upload, binding change, source repair, listening approval or stage promotion",
        "pack": {"id": plan["pack_id"], "authority_revision": authority["revision"],
                 "mapping_revision": plan["mapping_revision"],
                 "planned_status": plan["status"],
                 "approved_final_pack_version": None,
                 "version_boundary": "Current local technical source set is pinned by the input/source hashes; final listening approval remains pending"},
        "inputs": [{"file": relative, "sha256": digest(repository_file(relative))} for relative in INPUTS],
        "historical_receipts": receipt_sources,
        "destination": {"owner": None, "place_id": None, "universe_id": None,
                        "deployment_authorized": False, "submission_authorized": False},
        "summary": {
            "musical_identities": len(musical), "local_preview_sources": len(previews),
            "admitted_musical_sources": sum(row["id"] in admitted for row in musical),
            "retained_nonmusical_sources": len(nonmusical),
            "additional_packaged_ambience_voice_payloads": len(auxiliary),
            "canonical_audio_bindings": len(bindings.get("Audio", {})),
            "preserved_image_bindings": len(bindings.get("Images", {})),
            "matching_recorded_historical_uploads": sum(len(row["recorded_historical_hash_matches"]) for row in all_rows),
            "source_bytes": sum(row["measured"]["bytes"] for row in all_rows),
            "source_clipped_pcm_samples": sum(row["measured"]["clipped_samples"] for row in all_rows),
            "local_inventory_consistent": not errors,
            "final_musical_approval_established": False,
            "hosted_permissions_or_audible_playback_established": False,
            "release_ready": False,
        },
        "errors": errors,
        "musical_samples": musical, "retained_nonmusical_audio": nonmusical,
        "additional_packaged_ambience_and_voices": auxiliary,
        "runtime_observation_plan": {
            "observations_still_required": ["Final source listening and musical-usefulness review",
                "Authorized owner/place/universe and current exact-content permissions",
                "Selected identities with mixed configured/unconfigured/invalid/denied availability",
                "Intended-experience failure/mixed-access/late-ready audible playback",
                "Rapid hits, stop/mute and teardown on actual target clients/devices"],
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Write this local inventory JSON; otherwise print it")
    args = parser.parse_args()
    try:
        report = inspect_current()
    except (OSError, ValueError, wave.Error) as exc:
        parser.error(str(exc))
    encoded = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        target = args.output.resolve()
        if (not target.is_relative_to(ROOT / "docs/evidence")
                and not target.is_relative_to(ROOT / "work")):
            parser.error("Output must be under docs/evidence or work; source/binding paths are never outputs")
        if target.exists():
            parser.error("Refusing to overwrite an existing receipt; choose a new dated output path")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(encoded, encoding="utf-8")
        print(json.dumps(report["summary"], indent=2))
    else:
        print(encoded, end="")
    return 0 if report["summary"]["local_inventory_consistent"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
