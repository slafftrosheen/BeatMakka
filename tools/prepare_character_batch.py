"""Record one reviewed non-billable plan. Does not submit provider work."""
import json,sys,hashlib
from pathlib import Path
from datetime import datetime,timezone
R=Path(__file__).resolve().parents[1];O=R/'docs/evidence/needle-quay-artbook-pass/tripo'
slug=sys.argv[1].lower();texture=len(sys.argv)>2 and sys.argv[2]=='texture';suffix='-texture' if texture else ''
balance=json.loads((R/'work/tripo-current-balance.json').read_text(encoding='utf-8-sig'))['balance']
connection=json.loads((O/'connection.json').read_text());connection.update(checked_at=datetime.now(timezone.utc).isoformat(),balance_credits=balance);connection['account_check']['balance_credits']=balance
connection_path=O/(slug+suffix+'-connection.json');connection_path.write_text(json.dumps(connection,indent=2))
batch=json.loads((O/'tori-batch.json').read_text());batch['connection_receipt']=connection_path.relative_to(R).as_posix();batch['quoted_total_credits']=10 if texture else 40
batch['authorization']['approved_asset_ids']=['NQ-NPC-'+slug.upper()]
request=batch['requests'][0];request.update(asset_id='NQ-NPC-'+slug.upper(),estimated_credits=batch['quoted_total_credits'],approved_reference=f'references/production/characters/{slug.upper()}-front.png',dry_run_receipt=(O/(slug+suffix+'-dry-run.json')).relative_to(R).as_posix())
if texture:
 batch['authorization']['approved_processing']=['texture'];receipt=O/(slug+'-generation.json');source=json.loads(receipt.read_text(encoding='utf-8-sig'));request.update(processing='texture',source_task_id=source['task_id'],source_task_receipt=receipt.relative_to(R).as_posix())
(O/(slug+suffix+'-batch.json')).write_text(json.dumps(batch,indent=2))
reference=R/request['approved_reference'];(O/(slug+'-reference.json')).write_text(json.dumps({'source_design':f'assets/production/needle-quay/npcs/{slug.upper()}-design.png','isolated_reference':request['approved_reference'],'method':'image_gen faithful single-character extraction','sha256':hashlib.sha256(reference.read_bytes()).hexdigest()},indent=2))
