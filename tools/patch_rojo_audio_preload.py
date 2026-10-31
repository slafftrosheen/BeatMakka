"""Patch the known local Rojo 7.7.0 preloader, preserving a verified backup.

Uses the repository-pinned Rojo to round-trip models; no downloads or uploads.
Builds and verifies by default. --install explicitly replaces the local plugin.
"""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET


ORIGINAL_SOURCE_SHA256 = "1ec46de4ebee8859e301136dccd49593dd9c35e711b827b0bb814fcf0abe036d"
ORIGINAL_PLUGIN_SHA256 = "de8cac278030b37f7d4f7efb931fe68087be0a851a31c33312f592b802a23714"
ROOT = Path(__file__).resolve().parents[1]
REPLACEMENT = ROOT / "tools/compat/rojo-preloadAssets.luau"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_node(root):
    matches = []
    for item in root.iter("Item"):
        props = item.find("Properties")
        name = props.find("*[@name='Name']") if props is not None else None
        if item.get("class") == "ModuleScript" and name is not None and name.text == "preloadAssets":
            matches.append(props.find("*[@name='Source']"))
    if len(matches) != 1 or matches[0] is None:
        raise RuntimeError("Expected exactly one Rojo preloadAssets ModuleScript")
    return matches[0]


def signature(root):
    """Compare every model property and child, resolving generated Ref IDs."""
    references = {}

    def index(item, path):
        references[item.get("referent")] = path
        for n, child in enumerate(item.findall("Item")):
            index(child, path + (n,))

    for n, item in enumerate(root.findall("Item")):
        index(item, (n,))

    def value(node):
        text = node.text or ""
        if node.tag == "Ref":
            text = references.get(text, text)
        return (node.tag, tuple(sorted(node.attrib.items())), text if len(node) == 0 else "",
                tuple(value(child) for child in node))

    def item_value(item):
        props = item.find("Properties")
        return (item.get("class"), tuple(sorted((value(p) for p in props), key=repr)),
                tuple(item_value(child) for child in item.findall("Item")))

    return (tuple(item_value(item) for item in root.findall("Item")),
            tuple(value(node) for node in root if node.tag != "Item"))


def build(source, output, work):
    project = work / (output.stem + ".project.json")
    # Rojo's entry script uses FindFirstAncestor("Rojo"). The project name
    # overrides the imported model root, so preserve its required original name.
    project.write_text(json.dumps({"name": "Rojo", "tree": {"$path": str(source)}}), encoding="utf-8")
    subprocess.run(["rojo", "build", str(project), "--output", str(output)], cwd=ROOT, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plugin", type=Path, required=True)
    parser.add_argument("--backup-dir", type=Path, required=True)
    parser.add_argument("--install", action="store_true")
    args = parser.parse_args()
    version = subprocess.check_output(["rojo", "--version"], cwd=ROOT, text=True).strip()
    if version != "Rojo 7.7.0":
        raise RuntimeError(f"Use repository-pinned Rojo 7.7.0, found {version}")
    plugin = args.plugin.resolve(strict=True)
    if digest(plugin) != ORIGINAL_PLUGIN_SHA256:
        raise RuntimeError("Not the known original Rojo 7.7.0 plugin; refusing changes")
    work = args.backup_dir.resolve()
    work.mkdir(parents=True, exist_ok=False)
    backup = work / plugin.name
    shutil.copy2(plugin, backup)
    before = digest(plugin)
    if digest(backup) != before:
        raise RuntimeError("Backup checksum mismatch")
    original = work / "original.rbxmx"
    build(backup, original, work)
    tree = ET.parse(original)
    source = source_node(tree.getroot())
    old = (source.text or "").replace("\r\n", "\n")
    if hashlib.sha256(old.encode()).hexdigest() != ORIGINAL_SOURCE_SHA256:
        raise RuntimeError("Unknown preloader source; preserved backup, made no plugin change")
    source.text = REPLACEMENT.read_text(encoding="utf-8")
    patched_xml = work / "patched.rbxmx"
    tree.write(patched_xml, encoding="utf-8", xml_declaration=True)
    patched = work / "patched.rbxm"
    build(patched_xml, patched, work)
    roundtrip = work / "verified.rbxmx"
    build(patched, roundtrip, work)
    if signature(tree.getroot()) != signature(ET.parse(roundtrip).getroot()):
        raise RuntimeError("Plugin round-trip changed model properties; no plugin installed")
    if args.install:
        if digest(plugin) != before:
            raise RuntimeError("Installed plugin changed during patch; refusing replacement")
        shutil.copy2(patched, plugin)
        if digest(plugin) != digest(patched):
            raise RuntimeError("Installed plugin checksum mismatch; restore preserved backup")
    receipt = {"tool": version, "plugin": str(plugin), "backup": str(backup), "root_name": "Rojo",
               "original_sha256": before, "patched_sha256": digest(patched),
               "replacement_source_sha256": digest(REPLACEMENT),
               "only_preload_source_changed": True, "roundtrip_verified": True,
               "installed": args.install, "upstream": "https://github.com/rojo-rbx/rojo/pull/1344"}
    (work / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
