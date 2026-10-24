"""Capture original Studio MCP viewport bytes and a small provenance receipt."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--studio-id', required=True)
parser.add_argument('--output', type=Path, required=True, help='Output prefix without extension')
args = parser.parse_args()
work = ROOT/'work/studio-requests'
work.mkdir(parents=True, exist_ok=True)
request, result, image = (work/(args.output.name+s) for s in ['-capture-request.json','-capture-result.json','-capture-image.bin'])
request.write_text(json.dumps({'name':'screen_capture','arguments':{'studio_id':args.studio_id,'capture_id':args.output.name}}),encoding='utf-8')
subprocess.run([sys.executable,str(ROOT/'tools/studio_mcp_bridge.py'),'--request',str(request),'--output',str(result),'--image-output',str(image)],check=True)
data = json.loads(result.read_text(encoding='utf-8'))
assert not data.get('isError'), data
block = next(b for b in data['content'] if b['type']=='image')
extension = {'image/png':'.png','image/jpeg':'.jpg'}[block['mimeType']]
target = args.output.with_suffix(extension)
target.parent.mkdir(parents=True,exist_ok=True)
target.write_bytes(image.read_bytes())
receipt = {'studio_id':args.studio_id,'source':'Studio MCP screen_capture','mime_type':block['mimeType'],'image':target.name,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'edited':False}
args.output.with_suffix('.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
print(target)
