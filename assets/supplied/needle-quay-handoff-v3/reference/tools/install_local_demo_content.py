"""Install only the needle-quay namespace into an explicitly selected local Studio.

Example: python tools/install_local_demo_content.py --studio-content C:/.../content
No credentials, uploads, registry writes or changes to Roblox-owned files.
"""
from pathlib import Path
import argparse,json,hashlib,shutil
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--studio-content',type=Path,required=True)
args=parser.parse_args()
ROOT=Path(__file__).resolve().parents[1]
content=args.studio_content.resolve()
if not content.is_dir() or not (content.parent/'RobloxStudioBeta.exe').is_file():
    raise SystemExit('Select the content directory beside RobloxStudioBeta.exe')
source=ROOT/'assets/local-demo/content/needle-quay'
target=content/'needle-quay'
manifest=json.loads((ROOT/'assets/local-demo/install-manifest.json').read_text())
for record in manifest['files']:
    relative=Path(record['file']);src=(source/relative).resolve();dst=(target/relative).resolve()
    if not src.is_relative_to(source.resolve()) or not dst.is_relative_to(target.resolve()):raise ValueError('Path outside package')
    if hashlib.sha256(src.read_bytes()).hexdigest()!=record['sha256']:raise ValueError('Source hash mismatch: '+str(relative))
    dst.parent.mkdir(parents=True,exist_ok=True)
    if not dst.exists() or hashlib.sha256(dst.read_bytes()).hexdigest()!=record['sha256']:shutil.copyfile(src,dst)
    if hashlib.sha256(dst.read_bytes()).hexdigest()!=record['sha256']:raise ValueError('Installed hash mismatch: '+str(relative))
receipt={'target':str(target),'files':len(manifest['files']),'verified_sha256':True,'uploads':0}
(ROOT/'docs/evidence/needle-quay-demo/local-install.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt))
