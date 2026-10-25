"""Local canonical CLI packages and read-only inspection receipts; no provider calls."""
import json,subprocess,shutil
from pathlib import Path
R=Path(__file__).resolve().parents[1];CLI=Path.home()/'AppData/Local/GameDevelopmentStudio/cli/game-dev.cmd'
E=R/'docs/evidence/needle-quay-production';E.mkdir(parents=True,exist_ok=True)
D=json.loads((R/'assets/production/needle-quay/models/model-manifest.json').read_text())
out=R/'assets/production/needle-quay/packages';out.mkdir(exist_ok=True)
def call(args):
 p=subprocess.run([str(CLI),*map(str,args),'--output-dir',str(R/'work/game-dev'),'--json'],capture_output=True,text=True,encoding='utf-8')
 d=json.loads(p.stdout)
 if not d.get('ok'):raise RuntimeError(d)
 return d
rows=[]
for a in D['buildings']+D['npcs']:
 ident=a['id'];source=R/a['glb'];folder=E/ident;folder.mkdir(exist_ok=True)
 inspection=call(['asset','inspect',source]);(folder/'inspection.json').write_text(json.dumps(inspection,indent=2)+'\n')
 meta={'description':'Local Needle Quay candidate; no production art/Studio/runtime promotion','license':'LicenseRef-BeatMakka-Private','provenance':{'authoring':'Deterministic Blender source; canonical H04 reused','sourceRegister':'data/needle-quay-environment.v1.json','sourceBlend':a['source'],'acceptanceStage':a['stage'],'billableProviderCalls':0},'policy':{'requireUvs':True,'requireNormals':True}}
 request=R/'work/needle-quay/package-metadata.json';request.write_text(json.dumps(meta))
 common=['package','build',source,'--name',ident.lower(),'--version','1.0.0','--license','LicenseRef-BeatMakka-Private','--request',request]
 plan=call(common+['--dry-run']);(folder/'package-plan.json').write_text(json.dumps(plan,indent=2)+'\n')
 built=call(common);path=Path(built['data']['packagePath']);dest=out/path.parent.name/path.name;dest.parent.mkdir(exist_ok=True)
 if dest.exists():shutil.rmtree(dest)
 shutil.copytree(path,dest)
 verified=call(['package','verify',dest]);(folder/'package-verification.json').write_text(json.dumps(verified,indent=2)+'\n')
 rows.append({'id':ident,'package':dest.relative_to(R).as_posix(),'package_id':built['data']['packageId'],'integrity_verified':True,'policy':'game-dev static UV/normal/finite-geometry checks plus CLI defaults; not a new project triangle budget or engine acceptance'})
 print(ident,flush=True)
(out/'package-index.json').write_text(json.dumps({'packages':rows,'license':'LicenseRef-BeatMakka-Private','runtime_verified':False,'roblox_uploads':0},indent=2)+'\n')
