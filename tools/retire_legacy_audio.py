"""One-time, idempotent retirement of historical music; never deletes authored sources."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "assets/archive/audio-retirement-handoff-v3"
PRESERVE = ("ui_tap", "ui_collect", "ui_save", "ui_error", "waterfront")
PREIMAGES = ("src/shared/SampleCatalog.luau", "src/shared/StylePacks.luau", "src/shared/SampleWaveforms.luau",
             "src/shared/ContentIds.luau", "src/shared/LocalContent.luau", "data/content-ids.json",
             "data/style-upload-manifest.json", "data/audio-source-revisions.json",
             "assets/production/upload-manifest.json", "assets/production/audio/manifest.json",
             "assets/candidates/audio/style-starters-v1/manifest.json", "assets/candidates/audio/quay-found-v1/manifest.json",
             "assets/local-demo/install-manifest.json", "assets/local-demo/content-provenance.json")


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def original(relative):
    return ARCHIVE / relative


def main():
    authority_path = ROOT / "data/active-content.json"
    if authority_path.exists() and json.loads(authority_path.read_text(encoding="utf-8")).get("musical_audio"):
        raise ValueError("Retirement migration cannot overwrite a later admitted musical revision")
    # Runtime catalog itself is projected separately, so its original comes from the supplied baseline.
    for relative in PREIMAGES:
        target = original(relative)
        if not target.exists():
            source = ROOT / relative
            if relative == "src/shared/SampleCatalog.luau":
                source = ROOT / "assets/supplied/needle-quay-handoff-v3/source_snapshot/src/shared/SampleCatalog.luau"
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
    production = json.loads(original("assets/production/audio/manifest.json").read_text(encoding="utf-8"))
    styles = json.loads(original("assets/candidates/audio/style-starters-v1/manifest.json").read_text(encoding="utf-8"))
    labels = dict(re.findall(r'id = "([^"]+)", label = "([^"]+)"', original("src/shared/SampleCatalog.luau").read_text()))
    retired = [{"id": row["id"], "label": labels.get(row["id"], row["id"]), "pack": "quay",
                "status": "retired_unavailable", "reason": "test_music_retired_handoff_v3"}
               for row in production["samples"] if row["id"] not in PRESERVE]
    for pack in styles["packs"]:
        retired.extend({"id": row["id"], "label": row["label"], "pack": pack["id"],
                        "status": "retired_unavailable", "reason": "test_music_retired_handoff_v3"} for row in pack["samples"])
    write_json(ROOT / "data/retired-audio.json", {"schema": 1, "samples": retired,
               "archive": ARCHIVE.relative_to(ROOT).as_posix(), "aliases": {}})
    nonmusic = []
    for row in production["samples"]:
        if row["id"] in PRESERVE:
            nonmusic.append({"id": row["id"], "file": row["file"],
                             "sha256": hashlib.sha256((ROOT / row["file"]).read_bytes()).hexdigest(),
                             "category": "ambience" if row["id"] == "waterfront" else "ui-cue"})
    authority = ROOT / "data/active-content.json"
    if not authority.exists():
        write_json(authority, {"schema": 1, "revision": "handoff-v3-pending-audio",
                   "planned_contract": "data/first-pack-slots.v3.json", "retired_catalog": "data/retired-audio.json",
                   "nonmusical_audio": nonmusic, "musical_audio": [],
                   "policy": "Only this explicit graph grants audio admission. Source archives and planned roles never do."})
    production["samples"] = [row for row in production["samples"] if row["id"] in PRESERVE]
    production.update({"active_content_authority": "data/active-content.json", "retired_music_archive":
                       original("assets/production/audio/manifest.json").relative_to(ROOT).as_posix()})
    write_json(ROOT / "assets/production/audio/manifest.json", production)
    for relative in ("assets/candidates/audio/style-starters-v1/manifest.json", "assets/candidates/audio/quay-found-v1/manifest.json"):
        data = json.loads(original(relative).read_text(encoding="utf-8"))
        data.update({"stage": "archival_retired_unavailable", "active": False, "runtime_admitted": False,
                     "retirement": "handoff_v3", "active_content_authority": "data/active-content.json"})
        write_json(ROOT / relative, data)
    revisions = json.loads(original("data/audio-source-revisions.json").read_text(encoding="utf-8"))
    for row in revisions["revisions"].values():
        row.update({"active": False, "runtime_bound": False, "status": "archival_retired"})
    revisions.update({"default": "handoff-v3-pending-audio", "active_content_authority": "data/active-content.json"})
    revisions["revisions"]["handoff-v3-pending-audio"] = {"manifest": "data/active-content.json",
        "category": "active_content_authority", "active_musical_samples": 0, "runtime_bound": False}
    write_json(ROOT / "data/audio-source-revisions.json", revisions)
    retired_ids = {row["id"] for row in retired}
    old = json.loads(original("assets/local-demo/install-manifest.json").read_text(encoding="utf-8"))
    removed, retained_modified = [], []
    payload = ROOT / "assets/local-demo/content/needle-quay"
    for row in old["files"]:
        relative = Path(row["file"])
        if relative.parent.as_posix() != "audio" or relative.stem not in retired_ids:
            continue
        target = (payload / relative).resolve()
        if not target.is_relative_to(payload.resolve()):
            raise ValueError("Invalid retired payload path")
        if target.is_file():
            if hashlib.sha256(target.read_bytes()).hexdigest() == row["sha256"]:
                target.unlink()
                removed.append(row["file"])
            else:
                retained_modified.append(row["file"])
    installed = []
    versions = Path(os.environ.get("LOCALAPPDATA", "")) / "Roblox/Versions"
    for version in versions.glob("*"):
        if not (version / "RobloxStudioBeta.exe").is_file():
            continue
        target = version / "content/needle-quay/audio"
        found = []
        for row in old["files"]:
            if Path(row["file"]).parent.as_posix() != "audio" or Path(row["file"]).stem not in retired_ids:
                continue
            path = target / Path(row["file"]).name
            if path.is_file():
                found.append({"file": str(path), "sha256_matches_old_manifest": hashlib.sha256(path.read_bytes()).hexdigest() == row["sha256"]})
        if found:
            installed.append({"studio": str(version), "retired_files": found})
    evidence = {"schema": 1, "retired_musical_ids": len(retired), "retired_kit_count": 11,
                "removed_repository_package_files": removed, "retained_modified_payloads": retained_modified,
                "installed_studio_audit": installed, "installed_files_changed": 0,
                "active_nonmusical_ids": list(PRESERVE), "source_audio_deleted": 0,
                "archive_preimages": [{"file": original(relative).relative_to(ROOT).as_posix(),
                                       "sha256": hashlib.sha256(original(relative).read_bytes()).hexdigest()} for relative in PREIMAGES]}
    write_json(ROOT / "docs/evidence/handoff-v3/content-retirement.json", evidence)
    print(json.dumps({"retired_ids": len(retired), "removed_package_files": len(removed), "installed_namespaces_audited": len(installed)}))


if __name__ == "__main__":
    main()
