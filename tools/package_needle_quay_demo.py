"""Package the built local place and checksum-verified companion content."""
from pathlib import Path
import json, hashlib, zipfile, shutil, argparse
parser=argparse.ArgumentParser()
parser.add_argument('--evidence-dir',default='docs/evidence/needle-quay-artbook-pass')
parser.add_argument('--place',default='NeedleQuay-Artbook-Pass.rbxlx')
parser.add_argument('--readme',default='docs/needle-quay/LOCAL_PACKAGE_README.md')
args=parser.parse_args()
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/needle-quay-demo'
place=OUT/args.place
assert place.parent.resolve()==OUT.resolve() and place.suffix=='.rbxlx' and place.is_file()
archive=place.with_suffix('.zip')
launcher=(ROOT/'tools/Launch-NeedleQuay.ps1').read_text(encoding='utf-8').replace('NeedleQuay-Artbook-Pass.rbxlx',place.name)
(OUT/'Launch-NeedleQuay.ps1').write_text(launcher,encoding='utf-8')
shutil.copyfile(ROOT/args.readme,OUT/'README.md')
manifest=json.loads((ROOT/'assets/local-demo/install-manifest.json').read_text())
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for name in [place.name,'Launch-NeedleQuay.ps1','README.md']:
        z.write(OUT/name,name)
    z.write(ROOT/'assets/local-demo/install-manifest.json','install-manifest.json')
    for entry in manifest['files']:
        p=ROOT/'assets/local-demo/content/needle-quay'/entry['file']
        assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256']
        z.write(p,'content/needle-quay/'+entry['file'])
receipt={'package':str(archive.relative_to(ROOT)).replace('\\','/'),'bytes':archive.stat().st_size,
    'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'companion_files':len(manifest['files']),
    'place_sha256':hashlib.sha256(place.read_bytes()).hexdigest(),
    'uploads':0,'tripo_spend_credits':0}
evidence=ROOT/args.evidence_dir;evidence.mkdir(parents=True,exist_ok=True)
(evidence/'local-package.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt))
