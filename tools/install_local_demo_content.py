"""Install only the needle-quay namespace into an explicitly selected local Studio.

Example: python tools/install_local_demo_content.py --studio-content C:/.../content
No credentials, uploads, registry writes or changes to Roblox-owned files.
"""
from pathlib import Path
import argparse,json,hashlib,shutil
from active_content import validate_install_manifest
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
validate_install_manifest(manifest)
# Retire only specific generated files whose exact previous hash is known.
# Never delete a directory, a modified user file, or anything outside this namespace.
removed=[]
for record in manifest.get('retired_audio_payloads',[]):
    relative=Path(record['file']);dst=(target/relative).resolve()
    if relative.parent.as_posix()!='audio' or not dst.is_relative_to(target.resolve()):raise ValueError('Invalid retirement path')
    if dst.is_file() and hashlib.sha256(dst.read_bytes()).hexdigest()==record['sha256']:
        dst.unlink();removed.append(record['file'])
for record in manifest['files']:
    relative=Path(record['file']);src=(source/relative).resolve();dst=(target/relative).resolve()
    if not src.is_relative_to(source.resolve()) or not dst.is_relative_to(target.resolve()):raise ValueError('Path outside package')
    if hashlib.sha256(src.read_bytes()).hexdigest()!=record['sha256']:raise ValueError('Source hash mismatch: '+str(relative))
    dst.parent.mkdir(parents=True,exist_ok=True)
    if not dst.exists() or hashlib.sha256(dst.read_bytes()).hexdigest()!=record['sha256']:shutil.copyfile(src,dst)
    if hashlib.sha256(dst.read_bytes()).hexdigest()!=record['sha256']:raise ValueError('Installed hash mismatch: '+str(relative))
receipt={'target':str(target),'files':len(manifest['files']),'verified_sha256':True,'uploads':0,'retired_audio_removed':removed,
         'local_personal_preview_files':manifest.get('allowed_preview_audio_files',[]),
         'preview_status':'pending_listening_not_runtime_admitted'}
(ROOT/'docs/evidence/needle-quay-demo/local-install.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt))
