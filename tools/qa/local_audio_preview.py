"""Repeatable source/package guards for 64 pack-native local Studio sounds.

Run from the repository root: python tools/qa/local_audio_preview.py
This verifies data and generated projections, not listening or Studio playback.
"""
from copy import deepcopy
from pathlib import Path
import array
import argparse
import hashlib
import json
import sys
import wave
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import active_content as content

INTAKE = json.loads((ROOT / "assets/production/needle-quay/harbour-pulse-v3/intake-manifest.json").read_text())
EXPECTED = {}
for source in INTAKE["source_pack"]:
    ordinal = int(Path(source["file"]).name.split("_", 1)[0])
    address = "ABCD"[(ordinal - 1) // 16] + f"{(ordinal - 1) % 16 + 1:02d}"
    EXPECTED[address] = Path(source["file"]).name
results = []
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source-only', action='store_true', help='Defer package verification until the root packaging pass.')
args = parser.parse_args()


def check(name, action):
    try:
        action()
        results.append({"name": name, "status": "PASS"})
    except Exception as error:
        results.append({"name": name, "status": "FAIL", "detail": str(error)})


def assert_that(value, message):
    if not value:
        raise AssertionError(message)


def projection(path):
    return json.loads(path.read_text(encoding="utf-8").split("[=[", 1)[1].split("]=]", 1)[0])


def exact_mappings():
    previews = content.preview_audio()
    assert_that({row["address"]: Path(row["file"]).name for row in previews.values()} == EXPECTED,
                "Preview set differs from the user-selected native 01..64 mapping")
    assert_that(not content.load_authority()["musical_audio"], "Auditions acquired runtime admission")
    plan = projection(ROOT / "src/shared/FirstPackSlots.luau")
    assert_that(not plan["admitted"] and plan["previews"] == previews, "Generated admission/preview projection drifted")
    slots = {row["address"]: row for row in plan["slots"]}
    assert_that(len(slots) == 64 and slots["C01"]["label"] == "Needle Quay", "Native vocals are not in C01")
    assert_that(slots["D01"]["label"] == "Lantern Bell D5", "Native D01 bell mapping changed")
    assert_that(all(row["discovery_id"] is None for row in slots.values()), "Free local kit acquired discovery locks")
    assert_that({row["id"] for row in plan["discoveryRoleBindings"]} == {"I01", "I02", "I03"}, "Discovery IDs were lost")
    assert_that(plan["roleBindings"]["closed_hat"] == "nq.harbour.v1.a09", "Hat semantic alias points at wrong instrument")
    assert_that("pluck" not in plan["roleBindings"], "Pluck semantic alias points at a vocal")
    for index, slot in enumerate(plan["slots"], 1):
        assert_that(slot["source_ordinal"] == index == slot["absolute_pad"], "Native ordinal changed canonical address")


def exact_payloads():
    manifest = json.loads((ROOT / "assets/local-demo/install-manifest.json").read_text())
    content.validate_install_manifest(manifest)
    local = projection(ROOT / "src/shared/LocalContent.luau")
    previews = content.preview_audio()
    for identity, row in previews.items():
        relative = "preview-audio/" + identity + ".wav"
        payload = ROOT / "assets/local-demo/content/needle-quay" / relative
        assert_that(hashlib.sha256(payload.read_bytes()).hexdigest() == row["sha256"], "Native WAV bytes changed")
        assert_that(local["PreviewAudio"][identity] == "rbxasset://needle-quay/" + relative, "Preview URI differs")
        assert_that(identity not in local["Audio"], "Preview leaked into admitted audio bindings")


def local_gameplay_roles():
    contract = json.loads((ROOT / "data/studio-local-music-roles.v1.json").read_text(encoding="utf-8"))
    assert_that(contract == projection(ROOT / "src/shared/StudioLocalMusicRoles.luau"),
                "Generated local role adapter drifted from its source contract")
    previews = content.preview_audio()
    expected = {"I01": "A15", "I02": "D10", "I03": "D04"}
    assert_that({row["discovery_id"]: row["address"] for row in contract["bindings"]} == expected,
                "Explicit local discovery source mapping drifted")
    for binding in contract["bindings"]:
        source = previews[binding["sample_id"]]
        assert_that(source["address"] == binding["address"], "Local role changed canonical address")
        assert_that(binding["recording_equivalence"] is False and binding["audio_approved"] is False
                    and binding["runtime_admitted"] is False and binding["listening_review"] == "pending",
                    "Local gameplay source acquired an approval or field-recording equivalence claim")
    assert_that(contract["lesson_roles"]["preview_pluck"] == "nq.harbour.v1.d01",
                "Local tune lesson no longer uses the actual pitched bell")


def rejected(name, change):
    authority = deepcopy(content.load_authority())
    change(authority)
    with patch.object(content, "load_authority", return_value=authority):
        try:
            content.preview_audio()
        except ValueError:
            return
    raise AssertionError("Invalid preview accepted: " + name)


def silent_source_rejected():
    intake = json.loads((ROOT / "assets/production/needle-quay/harbour-pulse-v3/intake-manifest.json").read_text())
    silent = []
    for source in intake["source_pack"]:
        with wave.open(str(ROOT / source["file"]), "rb") as stream:
            samples = array.array("h", stream.readframes(stream.getnframes()))
        if samples and not any(samples):
            silent.append(source)
    assert_that(len(silent) == 7, "Expected seven measured all-zero source files")
    source = next(row for row in silent if row["file"].endswith("01_Drop_Kick_Main.wav"))

    def change(authority):
        row = authority["local_preview_audio"][0]
        row.update({"file": source["file"], "sha256": source["sha256"], "source_kind": "native_supplied_wav"})
        row["source_provenance"]["archive_member"] = source["archive_member"]
    rejected("all-zero WAV", change)


def repair_quality():
    import prepare_pack_native_audio as repair
    rows = content.preview_audio()
    manifest = json.loads((ROOT / "assets/production/needle-quay/harbour-pulse-v3/local-dsp-repairs/manifest.json").read_text())
    assert_that(len(manifest["repairs"]) == 8 + len(repair.ONSET_TRIM), "Expected silence, level and measured onset derivatives")
    assert_that(sum(row["source_kind"] == "native_supplied_wav" for row in rows.values()) == 56 - len(repair.ONSET_TRIM), "Native unchanged count drifted")
    hashes = set()
    for row in rows.values():
        measured = repair.metadata(ROOT / row["file"])
        assert_that(measured["nonzero_pcm_samples"] > 0 and measured["clipped_samples"] == 0, "Unplayable or clipped PCM")
        hashes.add(row["sha256"])
        ordinal = row["source_ordinal"]
        rate, channels, samples = repair.pcm(ROOT / row["file"])
        if ordinal in repair.SILENT:
            regenerated = repair.synthesize(ordinal, len(samples) // channels, rate)
            assert_that(list(samples) == [value for value in regenerated for _ in range(channels)], "DSP repair is not reproducible")
        elif ordinal == 15:
            _, _, original = repair.pcm(ROOT / row["source_provenance"]["original_file"])
            peak = max(map(abs, original))
            target = 32767 * 10 ** (-12 / 20)
            assert_that(list(samples) == [round(value / peak * target) for value in original], "Metal repair changed more than amplitude")
            assert_that(abs(measured["peak_dbfs"] + 12) < 0.01, "Metal derivative is not at -12 dBFS")
        elif ordinal in repair.ONSET_TRIM:
            _, _, original = repair.pcm(ROOT / row["source_provenance"]["original_file"])
            expected, removed, before = repair.onset_trim(original, channels, rate)
            assert_that(samples == expected and removed / rate >= 0.05,
                        "Onset repair changed more than the declared leading PCM slice")
            assert_that(repair.onset(samples, channels, rate)["signal_onset_ms"] <= 2.05,
                        "Trimmed pad still starts late")
    assert_that(len(hashes) == 64, "The native local kit contains duplicate payloads")


check("64 native ordinal mappings; approval separate; discovery IDs preserved", exact_mappings)
check("explicit local gameplay substitutes and lesson source retain pending approval", local_gameplay_roles)
check("64 nonzero unique unclipped WAVs; deterministic repairs, level-only gain and exact onset trims", repair_quality)
if not args.source_only:
    check("exact native WAV package hashes; separate local preview URI namespace", exact_payloads)
else:
    results.append({"name": "package payload verification deferred until packaging", "status": "NOT_RUN"})
check("all seven silent WAVs identified; all-zero kick rejected", silent_source_rejected)
check("duplicate PCM source rejected", lambda: rejected("duplicate", lambda a: a["local_preview_audio"][1].update({
    "file": a["local_preview_audio"][0]["file"], "sha256": a["local_preview_audio"][0]["sha256"]})))
check("approval claim rejected", lambda: rejected("approval", lambda a: a["local_preview_audio"][0].update({"audio_approved": True})))
check("runtime admission claim rejected", lambda: rejected("admission", lambda a: a["local_preview_audio"][0].update({"runtime_admitted": True})))
check("wrong native source ordinal rejected", lambda: rejected("ordinal", lambda a: a["local_preview_audio"][0].update({"source_ordinal": 33})))
check("incomplete local kit rejected", lambda: rejected("missing slot", lambda a: a["local_preview_audio"].pop()))
check("wrong canonical address rejected", lambda: rejected("address", lambda a: a["local_preview_audio"][0].update({"address": "A02"})))
check("changed source hash rejected", lambda: rejected("hash", lambda a: a["local_preview_audio"][0].update({"sha256": "0" * 64})))
print(json.dumps({"scope": "source_and_package_only", "listening_review": "NOT_RUN", "studio_playback": "NOT_RUN", "results": results}, indent=2))
raise SystemExit(1 if any(row["status"] == "FAIL" for row in results) else 0)
