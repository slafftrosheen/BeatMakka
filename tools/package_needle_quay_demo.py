"""Package the built local place and checksum-verified companion content."""
from pathlib import Path
import json, hashlib, zipfile, shutil, argparse
parser=argparse.ArgumentParser()
parser.add_argument('--evidence-dir',default='docs/evidence/needle-quay-artbook-pass')
args=parser.parse_args()
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/needle-quay-demo'
archive=OUT/'NeedleQuay-Artbook-Pass.zip'
shutil.copyfile(ROOT/'tools/Launch-NeedleQuay.ps1',OUT/'Launch-NeedleQuay.ps1')
shutil.copyfile(ROOT/'docs/needle-quay/LOCAL_PACKAGE_README.md',OUT/'README.md')
manifest=json.loads((ROOT/'assets/local-demo/install-manifest.json').read_text())
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for name in ['NeedleQuay-Artbook-Pass.rbxlx','Launch-NeedleQuay.ps1','README.md']:
        z.write(OUT/name,name)
    z.write(ROOT/'assets/local-demo/install-manifest.json','install-manifest.json')
    for entry in manifest['files']:
        p=ROOT/'assets/local-demo/content/needle-quay'/entry['file']
        assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256']
        z.write(p,'content/needle-quay/'+entry['file'])
receipt={'package':str(archive.relative_to(ROOT)).replace('\\','/'),'bytes':archive.stat().st_size,
    'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'companion_files':len(manifest['files']),
    'place_sha256':hashlib.sha256((OUT/'NeedleQuay-Artbook-Pass.rbxlx').read_bytes()).hexdigest(),
    'uploads':0,'tripo_spend_credits':200}
evidence=ROOT/args.evidence_dir;evidence.mkdir(parents=True,exist_ok=True)
(evidence/'local-package.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt))
