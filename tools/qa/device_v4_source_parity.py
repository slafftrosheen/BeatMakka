"""Compare the built place's source with fingerprints read through Studio MCP."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "docs/evidence/handoff-v4/groovebox-2026-10-30"
PLACE = ROOT / "output/needle-quay-demo/NeedleQuay-Groovebox-v4.rbxlx"


def fingerprint(source):
    source = source.replace("\r\n", "\n").rstrip() + "\n"
    content = source.encode("utf-8")
    rolling = 5381
    for byte in content:
        rolling = (rolling * 33 + byte) & 0xFFFFFFFF
    return {"bytes": len(content), "hash": f"{rolling:08x}", "sha256": hashlib.sha256(content).hexdigest()}


def main():
    built = {}

    def visit(item, prefix=""):
        properties = item.find("Properties")
        name = properties.find("string[@name='Name']").text
        path = f"{prefix}.{name}" if prefix else name
        if path.split(".")[0] not in {"ReplicatedStorage", "ServerScriptService", "StarterPlayer"}:
            return
        for tag in ("string", "ProtectedString"):
            source = properties.find(f"{tag}[@name='Source']")
            if source is not None:
                built[path] = fingerprint(source.text or "")
        for child in item.findall("Item"):
            visit(child, path)

    for item in ET.parse(PLACE).getroot().findall("Item"):
        visit(item)
    live = json.loads((EVIDENCE / "live-source-fingerprints.json").read_text(encoding="utf-8"))
    live = list(live.values()) if isinstance(live, dict) else live
    actual = {entry["path"]: entry for entry in live}
    differences = []
    for path in sorted(set(built) | set(actual)):
        expected, observed = built.get(path), actual.get(path)
        if not expected or not observed or any(expected[key] != observed[key] for key in ("bytes", "hash")):
            differences.append({"path": path, "built": expected, "studio": observed})
    result = {"status": "PASS" if not differences else "FAIL", "builtScripts": len(built), "studioScripts": len(actual), "differences": differences, "builtFingerprints": built}
    (EVIDENCE / "source-parity.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: result[key] for key in ("status", "builtScripts", "studioScripts", "differences")}, indent=2))
    if differences:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
