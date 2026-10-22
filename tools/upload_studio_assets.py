"""Execute the approved private Studio batch with durable per-invocation receipts.

Every key is submitted at most once. Unknown outcomes stop the batch; reconcile
Studio's AssetUploadReceipts before any user-authorized recovery invocation.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--studio-id", required=True)
parser.add_argument("--limit", type=int)
args = parser.parse_args()
report = json.loads((ROOT / "docs/evidence/optimized-assets.json").read_text())
batch = []
for asset in report["assets"]:
    for name in asset["part_groups"]:
        batch.append({"kind": "mesh", "key": asset["id"] + "__" + name, "id": asset["id"], "part": name,
                      "name": "FZ " + name.replace("_", " "), "source": asset["output"], "sourceHash": asset["sha256"]})
for size in (512, 1024):
    for finish in ("quay", "chalk", "coral", "afterhours"):
        batch.append({"kind": "image", "key": f"atlas.{finish}.basecolor.{size}", "template": f"{finish}_{size}",
                      "property": "ColorMapContent", "name": f"FZ {finish} color {size}", "source": f"Shared material atlas {finish}, {size}px"})
    for channel, property_name in (("roughness", "RoughnessMapContent"), ("metalness", "MetalnessMapContent")):
        batch.append({"kind": "image", "key": f"atlas.{channel}.{size}", "template": f"quay_{size}",
                      "property": property_name, "name": f"FZ shared {channel} {size}", "source": f"Shared atlas {channel}, {size}px"})
for name, key in (("Icons", "ui.icons"), ("Panel", "ui.panel")):
    batch.append({"kind": "image", "key": key, "template": name, "graphic": True, "property": "ImageContent",
                  "name": "FZ UI " + name, "source": "Original UI graphics / " + name})
assert sum(s["kind"] == "mesh" for s in batch) == 32
assert sum(s["kind"] == "image" for s in batch) == 14
out = ROOT / "docs/evidence/private-uploads"
out.mkdir(parents=True, exist_ok=True)
work = ROOT / "work/studio-uploads"
work.mkdir(parents=True, exist_ok=True)
template = (ROOT / "tools/studio_upload_asset.luau").read_text()
completed = 0
for spec in batch:
    result_file = out / (spec["key"] + ".json")
    if result_file.exists():
        result = json.loads(result_file.read_text())
        assert not result.get("isError"), "Prior upload outcome must be reconciled: " + spec["key"]
        completed += 1
        continue
    if args.limit is not None and completed >= args.limit:
        break
    code = template.replace("local spec = __UPLOAD_SPEC__", "local spec = game:GetService('HttpService'):JSONDecode([==[" + json.dumps(spec) + "]==])")
    request_file = work / (spec["key"] + ".json")
    request_file.write_text(json.dumps({"name": "execute_luau", "arguments": {"studio_id": args.studio_id, "datamodel_type": "Edit", "code": code}}))
    run = subprocess.run([sys.executable, str(ROOT / "tools/studio_mcp_bridge.py"), "--request", str(request_file),
                          "--output", str(result_file), "--timeout", "55"], cwd=ROOT)
    if run.returncode:
        raise SystemExit("Unknown upload outcome. Stop and inspect Studio receipts: " + spec["key"])
    result = json.loads(result_file.read_text())
    if result.get("isError"):
        raise SystemExit("Upload did not succeed. No automatic retry: " + spec["key"])
    completed += 1
print(json.dumps({"approved_meshes": 32, "approved_images": 14, "completed": completed}))
