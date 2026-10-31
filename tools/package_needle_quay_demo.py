"""Package the final local place and verified, explicitly active companion content."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import zipfile

from active_content import validate_install_manifest

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/needle-quay-demo"
FINAL_PLACE = "NeedleQuay-Groovebox-v4.rbxlx"
FINAL_EVIDENCE = "docs/evidence/handoff-v4/groovebox-2026-10-30"


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".partial")
    temporary.write_bytes(content)
    os.replace(temporary, path)


def repository_file(relative):
    path = (ROOT / relative).resolve()
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"Expected an existing repository file: {relative}")
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence-dir", default=FINAL_EVIDENCE)
    parser.add_argument("--place", default=FINAL_PLACE, help="Built .rbxlx filename in output/needle-quay-demo.")
    parser.add_argument("--readme", default="docs/needle-quay/FINAL_DEMO_README.md")
    args = parser.parse_args()
    if Path(args.place).name != args.place or Path(args.place).suffix != ".rbxlx":
        raise ValueError("Place must be a .rbxlx filename inside output/needle-quay-demo")
    place = repository_file("output/needle-quay-demo/" + args.place)
    place_digest = digest(place)
    archive = place.with_suffix(".zip")
    evidence = (ROOT / args.evidence_dir).resolve()
    if evidence == ROOT or not evidence.is_relative_to(ROOT):
        raise ValueError("Evidence directory must be a child of the repository")
    manifest_path = repository_file("assets/local-demo/install-manifest.json")
    authority_path = repository_file("data/active-content.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    validate_install_manifest(manifest)
    content_root = (ROOT / "assets/local-demo/content/needle-quay").resolve()
    content = []
    names = set()
    for entry in manifest["files"]:
        relative = PurePosixPath(entry["file"])
        if relative.is_absolute() or ".." in relative.parts or "\\" in entry["file"] or relative.as_posix() in names:
            raise ValueError("Invalid or duplicate companion content path: " + entry["file"])
        source = (content_root / relative).resolve()
        if not source.is_relative_to(content_root) or not source.is_file():
            raise ValueError("Companion file escaped its namespace: " + entry["file"])
        if source.stat().st_size != entry["bytes"] or digest(source) != entry["sha256"]:
            raise ValueError("Companion checksum failed: " + entry["file"])
        names.add(relative.as_posix())
        content.append((source, "content/needle-quay/" + relative.as_posix()))

    launcher = repository_file("tools/Launch-NeedleQuay.ps1").read_text(encoding="utf-8")
    if FINAL_PLACE not in launcher:
        raise ValueError("Launcher default must name the current groovebox place")
    launcher = launcher.replace(FINAL_PLACE, place.name)
    atomic_write(OUT / "Launch-NeedleQuay.ps1", launcher.encode("utf-8"))
    atomic_write(OUT / "Launch-NeedleQuay.cmd", repository_file("tools/Launch-NeedleQuay.cmd").read_bytes())
    atomic_write(OUT / "README.md", repository_file(args.readme).read_bytes())
    reports = []
    for source_name, package_name in (
        (args.evidence_dir + "/README.md", "DEVICE_DEMO_QA.md"),
        (args.evidence_dir + "/results.json", "device-results.json"),
        (FINAL_EVIDENCE + "/README.md", "FINAL_DEMO_QA.md"),
        (FINAL_EVIDENCE + "/results.json", "results.json"),
        (FINAL_EVIDENCE + "/presentation.json", "presentation.json"),
        (FINAL_EVIDENCE + "/cleanup.json", "cleanup.json"),
        (FINAL_EVIDENCE + "/cleanup-blockouts.json", "cleanup-blockouts.json"),
        (FINAL_EVIDENCE + "/cleanup-final.json", "cleanup-final.json"),
        (FINAL_EVIDENCE + "/IMPLEMENTATION.md", "IMPLEMENTATION.md"),
        (FINAL_EVIDENCE + "/source-parity.json", "source-parity.json"),
        ("assets/production/needle-quay/ui-device-v3/v4-provenance.json", "ui-art-provenance.json"),
        ("assets/production/needle-quay/ui-device-v3/v4-prompts.json", "ui-art-prompts.json"),
        ("assets/production/needle-quay/harbour-pulse-v3/onset-audit.json", "onset-audit.json"),
        (FINAL_EVIDENCE + "/groovebox-desktop.jpg", "groovebox-desktop.jpg"),
        (FINAL_EVIDENCE + "/groovebox-portrait.jpg", "groovebox-portrait.jpg"),
        (FINAL_EVIDENCE + "/groovebox-landscape-fx.jpg", "groovebox-landscape-fx.jpg"),
        (FINAL_EVIDENCE + "/public-performance.jpg", "public-performance.jpg"),
    ):
        source = ROOT / source_name
        if source.is_file():
            source = repository_file(source_name)
            reports.append((source, package_name))
            atomic_write(OUT / package_name, source.read_bytes())
    temporary = archive.with_name(archive.name + ".partial")
    with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as package:
        for name in (place.name, "Launch-NeedleQuay.cmd", "Launch-NeedleQuay.ps1", "README.md"):
            package.write(OUT / name, name)
        for source, package_name in reports:
            package.write(source, package_name)
        package.write(manifest_path, "install-manifest.json")
        package.write(authority_path, "active-content.json")
        for source, package_name in content:
            package.write(source, package_name)
    with zipfile.ZipFile(temporary) as package:
        failed = package.testzip()
        if failed:
            raise RuntimeError("Package CRC failed: " + failed)
        expected = {"content/needle-quay/" + entry["file"]: entry["sha256"] for entry in manifest["files"]}
        expected[place.name] = place_digest
        for name, checksum in expected.items():
            result = hashlib.sha256()
            with package.open(name) as stream:
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    result.update(chunk)
            if result.hexdigest() != checksum:
                raise RuntimeError("Packaged checksum failed: " + name)
    if digest(place) != place_digest:
        raise RuntimeError("Built place changed while packaging; final ZIP was preserved")
    os.replace(temporary, archive)
    receipt = {"package": archive.relative_to(ROOT).as_posix(), "bytes": archive.stat().st_size,
               "sha256": digest(archive), "companion_files": len(content), "place_sha256": place_digest,
               "readme": args.readme, "reports": [name for _, name in reports], "archive_crc": "PASS",
               "uploads": 0, "tripo_spend_credits": 0}
    evidence.mkdir(parents=True, exist_ok=True)
    atomic_write(evidence / "local-package.json", (json.dumps(receipt, indent=2) + "\n").encode("utf-8"))
    print(json.dumps(receipt))


if __name__ == "__main__":
    main()
