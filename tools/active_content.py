"""The explicit, local active audio graph. Historical manifests never grant admission."""
from pathlib import Path
import hashlib
import json
import array
import wave

ROOT = Path(__file__).resolve().parents[1]
AUTHORITY = ROOT / "data/active-content.json"


def load_authority():
    authority = json.loads(AUTHORITY.read_text(encoding="utf-8"))
    if authority.get("schema") != 1:
        raise ValueError("Unsupported active-content authority")
    return authority


def active_audio():
    authority = load_authority()
    planned = json.loads((ROOT / authority["planned_contract"]).read_text(encoding="utf-8"))
    slots = {row["sample_id"]: row for row in planned["slots"]}
    result = {}
    for row in authority["nonmusical_audio"]:
        if row["category"] not in ("ui-cue", "ambience", "voice"):
            raise ValueError("Nonmusical audio category required")
        result[row["id"]] = dict(row)
    for row in authority["musical_audio"]:
        identity = row["id"]
        if identity not in slots or identity in result:
            raise ValueError("Unknown/duplicate active musical identity")
        if row.get("audio_approved") is not True or row.get("runtime_admitted") is not True:
            raise ValueError("Musical admission requires explicit approval and admission")
        if not isinstance(row.get("approval"), dict) or not row["approval"].get("identity"):
            raise ValueError("Musical admission requires an approval receipt")
        if row.get("address") != slots[identity]["address"]:
            raise ValueError("Admission must preserve the written slot map")
        result[identity] = dict(row)
    for identity, row in result.items():
        validate_audio_source(identity, row)
    return result


def validate_audio_source(identity, row):
    source = (ROOT / row["file"]).resolve()
    if not source.is_relative_to(ROOT) or not source.is_file():
        raise ValueError("Audio must be a repository file: " + identity)
    if hashlib.sha256(source.read_bytes()).hexdigest() != row["sha256"]:
        raise ValueError("Audio source hash changed: " + identity)
    return source


def preview_audio():
    """Explicit Studio personal auditions; never grants musical admission."""
    authority = load_authority()
    planned = json.loads((ROOT / authority["planned_contract"]).read_text(encoding="utf-8"))
    slots = {row["sample_id"]: row for row in planned["slots"]}
    active = active_audio()
    used_hashes = {row["sha256"] for row in active.values()}
    result = {}
    for row in authority.get("local_preview_audio", []):
        identity = row["id"]
        slot = slots.get(identity)
        if not slot or identity in active or identity in result:
            raise ValueError("Unknown/duplicate local preview identity")
        if row.get("address") != slot["address"]:
            raise ValueError("Local previews must preserve the active canonical slot map")
        ordinal = row.get("source_ordinal")
        if (planned.get("mapping_revision") != "pack-native-2026-10-30"
                or ordinal != slot.get("source_ordinal") or ordinal != slot["absolute_pad"]
                or row.get("technical_local_ready") is not True):
            raise ValueError("Local preview must use the user-selected native numeric order")
        if (row.get("audio_approved") is not False or row.get("runtime_admitted") is not False
                or row.get("listening_review") != "pending" or row.get("verified_pitch") is not None
                or row.get("preview_status") != "local_personal_preview_pending_listening"):
            raise ValueError("Local preview cannot claim approval, admission or verified pitch")
        if row.get("source_label") != Path(row["file"]).stem or not row.get("mapping_basis"):
            raise ValueError("Local preview requires source label and mapping evidence")
        source = validate_audio_source(identity, row)
        if row["sha256"] in used_hashes:
            raise ValueError("Duplicate local preview PCM source")
        provenance = row.get("source_provenance", {})
        manifest_path = (ROOT / provenance.get("intake_manifest", "")).resolve()
        if not manifest_path.is_relative_to(ROOT) or not manifest_path.is_file():
            raise ValueError("Local preview requires repository intake provenance")
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        native = next((candidate for candidate in manifest["source_pack"]
                       if candidate["file"] == provenance.get("original_file")
                       and candidate["sha256"] == provenance.get("original_sha256")), None)
        if not native or any(provenance.get(key) != native[key] for key in
                             ("archive_member", "source_archive", "source_archive_sha256")):
            raise ValueError("Local preview differs from its preserved native source")
        if int(Path(native["file"]).name.split("_", 1)[0]) != ordinal:
            raise ValueError("Source ordinal was assigned to the wrong canonical identity")
        validate_audio_source(identity + "/original", {"file": native["file"], "sha256": native["sha256"]})
        kind = row.get("source_kind")
        if kind == "native_supplied_wav":
            if row["file"] != native["file"] or row["sha256"] != native["sha256"]:
                raise ValueError("Native source bytes changed")
        else:
            repair_path = (ROOT / provenance.get("repair_manifest", "")).resolve()
            if not repair_path.is_relative_to(ROOT) or not repair_path.is_file():
                raise ValueError("Derived audio requires explicit repair provenance")
            repairs = json.loads(repair_path.read_text(encoding="utf-8"))["repairs"]
            repair = next((candidate for candidate in repairs if candidate["ordinal"] == ordinal
                           and candidate["file"] == row["file"] and candidate["sha256"] == row["sha256"]), None)
            if not repair or repair["kind"] != kind or repair["original_sha256"] != native["sha256"]:
                raise ValueError("Derived audio differs from its repair receipt")
            if kind == "deterministic_dsp_silence_repair":
                if ordinal not in (1, 9, 10, 17, 30, 31, 32) or native["peak_dbfs"] is not None:
                    raise ValueError("DSP replacement is limited to the seven silent instruments")
            elif kind == "leading_silence_trim":
                from prepare_pack_native_audio import ONSET_TRIM, onset_trim, pcm
                if ordinal not in ONSET_TRIM:
                    raise ValueError("Onset trim is limited to the measured delayed sources")
                rate, channels, original_pcm = pcm(ROOT / native["file"])
                expected_pcm, removed, _ = onset_trim(original_pcm, channels, rate)
                derived_rate, derived_channels, derived_pcm = pcm(source)
                if (derived_rate != rate or derived_channels != channels
                        or derived_pcm != expected_pcm or repair.get("removed_leading_frames") != removed):
                    raise ValueError("Onset derivative must be the exact declared PCM slice")
            elif kind != "level_only_normalization" or ordinal != 15:
                raise ValueError("Unapproved audio derivation")
        with wave.open(str(source), "rb") as stream:
            if stream.getcomptype() != "NONE" or stream.getsampwidth() != 2:
                raise ValueError("Local preview requires native PCM16 WAV")
            samples = array.array("h", stream.readframes(stream.getnframes()))
        if not samples or not any(samples):
            raise ValueError("All-zero local preview is not playable")
        used_hashes.add(row["sha256"])
        result[identity] = dict(row)
    admitted_count = sum(identity in slots for identity in active)
    if len(result) + admitted_count != 64:
        raise ValueError("The native local kit requires exactly 64 playable identities")
    return result


def authority_hash():
    return hashlib.sha256(AUTHORITY.read_bytes()).hexdigest()


def validate_install_manifest(manifest):
    """Reject stale packages even if their files still exist in an archive."""
    if manifest.get("active_content_sha256") != authority_hash():
        raise ValueError("Package active-content authority is stale; rebuild local content")
    allowed = {"audio/" + identity + ".wav" for identity in active_audio()}
    packaged = {row["file"] for row in manifest["files"] if row["file"].startswith("audio/")}
    if packaged != allowed:
        raise ValueError("Package audio differs from the explicit active allowlist")
    allowed_previews = {"preview-audio/" + identity + ".wav" for identity in preview_audio()}
    packaged_previews = {row["file"] for row in manifest["files"] if row["file"].startswith("preview-audio/")}
    if packaged_previews != allowed_previews or set(manifest.get("allowed_preview_audio_files", [])) != allowed_previews:
        raise ValueError("Package previews differ from the explicit local preview allowlist")


def package_policy():
    retired_catalog = json.loads((ROOT / load_authority()["retired_catalog"]).read_text(encoding="utf-8"))
    retired_ids = {row["id"] for row in retired_catalog["samples"]}
    old_manifest = ROOT / retired_catalog["archive"] / "assets/local-demo/install-manifest.json"
    retired_payloads = [row for row in json.loads(old_manifest.read_text(encoding="utf-8"))["files"]
                        if Path(row["file"]).parent.as_posix() == "audio" and Path(row["file"]).stem in retired_ids]
    return {"active_content_sha256": authority_hash(),
            "allowed_audio_files": sorted("audio/" + identity + ".wav" for identity in active_audio()),
            "allowed_preview_audio_files": sorted("preview-audio/" + identity + ".wav" for identity in preview_audio()),
            "retired_audio_payloads": retired_payloads}
