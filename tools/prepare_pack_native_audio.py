"""Apply the user's pack-native 01..64 map and local-only technical audio repair.

No provider calls, uploads or original-source modifications. Seven all-zero
instrument files get explicitly authored deterministic DSP substitutes; one
extremely quiet metallic hit gets a level-only derivative. Thirteen measured
late attacks get exact leading PCM trim derivatives with 2ms pre-roll. Original
sources remain intact; listening/artistic approval remains pending for every file.
"""
from pathlib import Path
import array
import hashlib
import json
import math
import random
import shutil
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/production/needle-quay/harbour-pulse-v3"
ARCHIVE = ROOT / "assets/archive/written-audio-map-v3-2026-10-30"
REPAIR = OUT / "local-dsp-repairs"
SILENT = {1, 9, 10, 17, 30, 31, 32}
# Measured leading silence / subaudible noise before discrete one-shot attacks.
# Swells, risers and the first quieter transient of A07 remain intact.
ONSET_TRIM = {2, 3, 6, 7, 8, 11, 13, 14, 21, 25, 40, 41, 42}
BANKS = ["Drums", "Bass", "MC vocals", "Harbour FX and melodics"]
DECISION = 'also change mapping to the one which came with pack, so all 64 samples are playable'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def pcm(path):
    with wave.open(str(path), "rb") as stream:
        assert stream.getsampwidth() == 2 and stream.getcomptype() == "NONE"
        return stream.getframerate(), stream.getnchannels(), array.array("h", stream.readframes(stream.getnframes()))


def metadata(path):
    rate, channels, values = pcm(path)
    peak = max(map(abs, values), default=0)
    rms = math.sqrt(sum(float(x) * x for x in values) / max(1, len(values)))
    return {"duration_seconds": len(values) / channels / rate, "sample_rate_hz": rate,
            "channels": channels, "pcm_bit_depth": 16, "bytes": path.stat().st_size,
            "peak_dbfs": round(20 * math.log10(peak / 32768), 4) if peak else None,
            "rms_dbfs": round(20 * math.log10(rms / 32768), 4) if rms else None,
            "clipped_samples": sum(x >= 32767 or x <= -32768 for x in values),
            "nonzero_pcm_samples": sum(x != 0 for x in values)}


def onset(values, channels, rate):
    peak = max(map(abs, values), default=0)
    threshold = max(33, round(peak * 0.01))  # at least -60 dBFS, -40 dB relative to peak
    frame_count = len(values) // channels
    first_nonzero = frame_count
    first_signal = frame_count
    for frame in range(frame_count):
        value = max(abs(values[frame * channels + channel]) for channel in range(channels))
        if value and first_nonzero == frame_count:
            first_nonzero = frame
        if value >= threshold:
            first_signal = frame
            break
    return {"first_nonzero_frame": first_nonzero, "signal_onset_frame": first_signal,
            "first_nonzero_ms": round(first_nonzero / rate * 1000, 4),
            "signal_onset_ms": round(first_signal / rate * 1000, 4),
            "threshold_pcm16": threshold}


def onset_trim(values, channels, rate):
    measured = onset(values, channels, rate)
    # Exact contiguous PCM slice: no amplitude, pitch, tail, resampling or fades.
    # Keep two milliseconds of pre-roll before the detected attack.
    removed = max(0, measured["signal_onset_frame"] - round(rate * 0.002))
    return values[removed * channels:], removed, measured


def synthesize(ordinal, frames, rate):
    rng = random.Random(174000 + ordinal)
    duration = frames / rate
    phase = 0.0
    previous_noise = 0.0
    result = []
    for frame in range(frames):
        t = frame / rate
        attack = min(1.0, t / 0.004)
        release = min(1.0, max(0.0, (duration - t) / 0.025))
        if ordinal == 1:
            hz = 48 + 108 * math.exp(-t / 0.024)
            phase += 2 * math.pi * hz / rate
            value = math.sin(phase) * math.exp(-t / 0.115)
            value += rng.uniform(-1, 1) * math.exp(-t / 0.003) * 0.23
        elif ordinal in (9, 10):
            noise = rng.uniform(-1, 1)
            high = (noise - previous_noise) * 0.48
            previous_noise = noise
            metal = sum(math.sin(2 * math.pi * frequency * t)
                        for frequency in (6127, 8311, 10453, 12347)) / 4
            value = (high * 0.8 + metal * 0.2) * math.exp(-t / (0.032 if ordinal == 9 else 0.024))
        elif ordinal == 17:
            phase += 2 * math.pi * 36.70809598967594 / rate  # authored D1
            value = (math.sin(phase) + 0.30 * math.sin(2 * phase) + 0.12 * math.sin(3 * phase)) * math.exp(-t / 0.48)
        elif ordinal == 30:
            # Authored D2 Reese stab with slightly detuned harmonic oscillators.
            value = sum((math.sin(2 * math.pi * 73.41619197935188 * h * t)
                         + math.sin(2 * math.pi * 73.71 * h * t)) / (2 * h)
                        for h in (1, 2, 3, 4, 5, 6, 7))
            value = math.tanh(value * 1.35) * math.exp(-t / 0.20)
        elif ordinal == 31:
            hz = 36.70809598967594 * (1 + math.exp(-t / 0.11))
            phase += 2 * math.pi * hz / rate
            value = (math.sin(phase) + 0.27 * math.sin(2 * phase)) * math.exp(-t / 0.48)
        elif ordinal == 32:
            phase += 2 * math.pi * 36.70809598967594 / rate
            value = (math.sin(phase) + 0.32 * math.sin(2 * phase) + 0.12 * math.sin(3 * phase)) * math.exp(-t / 0.75)
        else:
            raise ValueError("No authorized silent repair recipe")
        result.append(value * attack * release)
    peak = max(map(abs, result))
    target = 32767 * 10 ** (-6 / 20)
    return [round(value / peak * target) for value in result]


def write_pcm(path, rate, channels, values):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(channels)
        stream.setsampwidth(2)
        stream.setframerate(rate)
        stream.writeframes(array.array("h", values).tobytes())


def label(name):
    return name.split("_", 1)[1].removesuffix(".wav").replace("_", " ").strip()


def prepare():
    for relative in ("data/first-pack-slots.v3.json", "data/active-content.json",
                     "assets/production/needle-quay/harbour-pulse-v3/pending-slot-bindings.json",
                     "data/world-districts.v1.json"):
        target = ARCHIVE / relative
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
    intake = json.loads((OUT / "intake-manifest.json").read_text(encoding="utf-8"))
    sources = {int(Path(row["file"]).name.split("_", 1)[0]): row for row in intake["source_pack"]}
    assert set(sources) == set(range(1, 65)), "Native source ordinals must be exactly 01..64"
    contract = json.loads((ARCHIVE / "data/first-pack-slots.v3.json").read_text(encoding="utf-8"))
    active = json.loads((ROOT / "data/active-content.json").read_text(encoding="utf-8"))
    active["local_preview_audio"] = []
    repair_rows = []
    mapping_rows = []
    onset_audit = []
    recipes = {1: "Main drop kick: decaying pitch-swept sine with deterministic click",
               9: "Closed DnB hi-hat 1: high-passed deterministic noise and metallic partials",
               10: "Closed DnB hi-hat 2: distinct shorter noise/metal transient",
               17: "Drop sub D1: authored D1 fundamental with bounded harmonics",
               30: "Mid Reese stab 2: authored D2 detuned harmonic stab",
               31: "Low sub glide: authored D2-to-D1 exponential glide",
               32: "Sustained bass tail: authored D1 harmonic decay"}
    for ordinal in range(1, 65):
        source = sources[ordinal]
        original = ROOT / source["file"]
        assert digest(original) == source["sha256"], "Preserved native source changed"
        rate, channels, values = pcm(original)
        selected = original
        kind = "native_supplied_wav"
        if ordinal in SILENT:
            assert not any(values), "Silence repair may only replace an all-zero instrumental source"
            selected = REPAIR / original.name
            mono = synthesize(ordinal, len(values) // channels, rate)
            write_pcm(selected, rate, channels, [value for value in mono for _ in range(channels)])
            kind = "deterministic_dsp_silence_repair"
        elif ordinal == 15:
            peak = max(map(abs, values))
            selected = REPAIR / "level-only" / original.name
            target = 32767 * 10 ** (-12 / 20)
            write_pcm(selected, rate, channels, [round(value / peak * target) for value in values])
            kind = "level_only_normalization"
        elif ordinal in ONSET_TRIM:
            trimmed, removed, before = onset_trim(values, channels, rate)
            assert removed / rate >= 0.05, "Only measured long leading silence may be trimmed"
            selected = REPAIR / "onset-trim" / original.name
            write_pcm(selected, rate, channels, trimmed)
            kind = "leading_silence_trim"
        measured = metadata(selected)
        assert measured["nonzero_pcm_samples"] > 0 and measured["clipped_samples"] == 0
        bank, pad = "ABCD"[(ordinal - 1) // 16], (ordinal - 1) % 16 + 1
        address = f"{bank}{pad:02d}"
        identity = f"nq.harbour.v1.{address.lower()}"
        provenance = {"intake_manifest": "assets/production/needle-quay/harbour-pulse-v3/intake-manifest.json",
                      "archive_member": source["archive_member"], "source_archive": source["source_archive"],
                      "source_archive_sha256": source["source_archive_sha256"],
                      "original_file": source["file"], "original_sha256": source["sha256"]}
        if selected != original:
            repair_row = {"ordinal": ordinal, "file": selected.relative_to(ROOT).as_posix(),
                                "sha256": digest(selected), "kind": kind, "original_file": source["file"],
                                "original_sha256": source["sha256"], "recipe": recipes.get(ordinal,
                                    "Exact PCM onset slice with 2ms pre-roll; no amplitude, pitch, resampling or tail edit"
                                    if ordinal in ONSET_TRIM else "Peak-only amplitude scaling to -12 dBFS; no retuning or time editing"),
                                "generator": "tools/prepare_pack_native_audio.py", "seed": 174000 + ordinal if ordinal in SILENT else None,
                                "generator_sha256": digest(Path(__file__)),
                                "audio_approved": False, "listening_review": "pending", **measured}
            if ordinal in ONSET_TRIM:
                repair_row.update({"removed_leading_frames": removed,
                                   "removed_leading_ms": round(removed / rate * 1000, 4),
                                   "pre_roll_ms": 2, "before_onset": before,
                                   "after_onset": onset(trimmed, channels, rate)})
            repair_rows.append(repair_row)
            provenance["repair_manifest"] = "assets/production/needle-quay/harbour-pulse-v3/local-dsp-repairs/manifest.json"
        row = {"id": identity, "address": address, "source_ordinal": ordinal,
               "file": selected.relative_to(ROOT).as_posix(), "sha256": digest(selected),
               "source_label": original.stem, "source_kind": kind,
               "mapping_basis": "User-selected pack-native numeric order 01..64; canonical identity preserved",
               "preview_status": "local_personal_preview_pending_listening", "technical_local_ready": True,
               "audio_approved": False, "runtime_admitted": False, "listening_review": "pending",
               "verified_pitch": None, "source_provenance": provenance, **measured}
        active["local_preview_audio"].append(row)
        _, _, selected_values = pcm(selected)
        onset_audit.append({"address": address, "source_ordinal": ordinal,
                            "source_file": source["file"], "source_sha256": source["sha256"],
                            "selected_file": row["file"], "selected_sha256": row["sha256"],
                            "before": onset(values, channels, rate),
                            "after": onset(selected_values, channels, rate),
                            "removed_leading_ms": round(removed / rate * 1000, 4) if ordinal in ONSET_TRIM else 0})
        slot = contract["slots"][ordinal - 1]
        assert slot["sample_id"] == identity and slot["address"] == address
        slot.update({"label": label(original.name), "category": BANKS[(ordinal - 1) // 16],
                     "planned_filename": original.name, "planned_pitch": None,
                     "planned_choke_group": "hats" if ordinal in (9, 10, 11) else ("mono_bass" if bank == "B" else None),
                     "semantic_role": "tutorial_kick" if ordinal == 1 else ("tutorial_closed_hat" if ordinal == 9 else None),
                     "discovery_id": None, "status": "local_preview_pending_listening", "audio_approved": False,
                     "file": row["file"], "sha256": row["sha256"], "source_ordinal": ordinal,
                     "source_provenance": provenance, "approval": None, "verified_pitch": None,
                     "source_kind": kind, **measured})
        slot.pop("planned_vocal", None)
        mapping_rows.append({"ordinal": ordinal, "address": address, "sample_id": identity,
                             "label": slot["label"], "file": row["file"], "sha256": row["sha256"], "source_kind": kind})
    assert len({row["sha256"] for row in active["local_preview_audio"]}) == 64, "Playable sources must not duplicate bytes"
    contract.update({"schema_version": 3, "kind": "pack_native_local_studio_contract",
                     "mapping_revision": "pack-native-2026-10-30", "status": "64_local_previews_pending_listening",
                     "active": False, "local_studio_active": True,
                     "mapping_decision": "assets/production/needle-quay/harbour-pulse-v3/pack-native-decision.json",
                     "banks": [{"id": bank, "label": BANKS[index], "count": 16} for index, bank in enumerate("ABCD")],
                     "role_bindings": {"kick": "nq.harbour.v1.a01", "preview_kick": "nq.harbour.v1.a01",
                                       "tutorial_kick": "nq.harbour.v1.a01", "closed_hat": "nq.harbour.v1.a09",
                                       "preview_closed_hat": "nq.harbour.v1.a09", "tutorial_closed_hat": "nq.harbour.v1.a09",
                                       "bell": "nq.harbour.v1.d01"},
                     "discovery_role_bindings": [
                         {"id": "I01", "role": "dock_metal", "candidate_sample_id": "nq.harbour.v1.a15", "status": "candidate_pending_listening_approval"},
                         {"id": "I02", "role": "vent_pulse", "candidate_sample_id": None, "status": "no_exact_supplied_role_match"},
                         {"id": "I03", "role": "helper_radio_reply", "candidate_sample_id": None, "status": "no_exact_supplied_role_match"}]})
    active["revision"] = "handoff-v3-pack-native-local64"
    active["policy"] = "User-selected native 01..64 kit is technically playable throughout local Studio creation, Finished Song saves, listening, jams and performances. Human listening/art approval and Roblox runtime admission remain pending; local play never grants upload or publishing permission or invents missing discovery-role bindings."
    write_json(REPAIR / "manifest.json", {"schema": 1, "repairs": repair_rows,
               "generator": "tools/prepare_pack_native_audio.py", "generator_sha256": digest(Path(__file__)),
               "synthetic_silence_replacements": 7, "level_only_derivatives": 1,
               "leading_silence_derivatives": len(ONSET_TRIM),
               "original_sources_modified": False, "provider_calls": 0, "uploads": 0,
               "listening_review": "pending", "source_counterpart_audit": "assets/production/needle-quay/harbour-pulse-v3/counterpart-audit.json"})
    write_json(OUT / "pack-native-decision.json", {"schema": 1, "user_request": DECISION,
               "supersedes": "Keep the written map; leave mismatched slots pending",
               "archived_contract": (ARCHIVE / "data/first-pack-slots.v3.json").relative_to(ROOT).as_posix(),
               "archived_contract_sha256": digest(ARCHIVE / "data/first-pack-slots.v3.json"),
               "canonical_sample_ids_preserved": True, "original_sources_preserved": True,
               "layout": BANKS, "source_order": "native numeric filename prefix 01..64",
               "repair_authority": "Local deterministic instrumental silence repair, level-only source15 normalization, and conservative onset trim derivatives authorized for responsive all-64 local playback",
               "human_listening_approval": False, "runtime_admitted": False})
    write_json(OUT / "pack-native-manifest.json", {"schema": 1, "pack_id": contract["pack_id"],
               "mapping_revision": contract["mapping_revision"], "mapping": mapping_rows,
               "technical_local_ready_count": 64, "audio_approved_count": 0, "runtime_admitted_count": 0,
               "native_unchanged_count": 56 - len(ONSET_TRIM), "dsp_silence_repair_count": 7,
               "level_only_count": 1, "leading_silence_trim_count": len(ONSET_TRIM)})
    write_json(OUT / "onset-audit.json", {"schema": 1, "generator": "tools/prepare_pack_native_audio.py",
               "threshold": "max(-60 dBFS PCM16, -40 dB relative to each source peak)",
               "pre_roll_ms": 2, "original_sources_modified": False, "sources": onset_audit})
    write_json(ROOT / "data/first-pack-slots.v3.json", contract)
    write_json(ROOT / "data/active-content.json", active)
    write_json(OUT / "pending-slot-bindings.json", {"schema": 2, "decision": DECISION,
               "mapping_revision": contract["mapping_revision"], "approval_status": "all_pending_listening",
               "technical_local_ready": 64, "bindings": mapping_rows})
    districts = json.loads((ROOT / "data/world-districts.v1.json").read_text(encoding="utf-8"))
    districts["canonicalKitEvidence"] = "data/first-pack-slots.v3.json"
    districts["kitPolicy"] = "User-selected pack-native order: A drums, B bass, C MC vocals, D harbour FX/melodics. All 64 sounds support local Studio creation and performance; listening/art approval and Roblox runtime admission remain pending."
    bindings = {"P1": "I01 discovery ID preserved; native A15 metal candidate pending listening/approval; no D01 bell-as-metal binding",
                "P2": "I02 discovery ID preserved; no exact native vent-pulse role supplied; binding pending",
                "P4": "I03 discovery ID preserved; no exact native helper/radio-reply role supplied; binding pending"}
    for stop in districts["firstDistrictStops"]:
        if stop["id"] in bindings:
            stop["existingBinding"] = bindings[stop["id"]]
    write_json(ROOT / "data/world-districts.v1.json", districts)
    print(json.dumps({"mapped_local_slots": 64, "native_unchanged": 56 - len(ONSET_TRIM), "silent_dsp_replacements": 7,
                      "level_only_derivatives": 1, "leading_silence_trim_derivatives": len(ONSET_TRIM),
                      "approved": 0, "uploads": 0}))


if __name__ == "__main__":
    prepare()
