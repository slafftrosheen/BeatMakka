"""Serve only explicitly listed approved PNG sources to the local Studio MCP uploader."""
from functools import partial
import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--manifest', type=Path, default=ROOT/'assets/production/upload-manifest.json')
parser.add_argument('--port', type=int, default=8769)
args = parser.parse_args()
manifest = json.loads(args.manifest.read_text())
approved = {('/' + x['file']) for x in manifest['images'][:14]}
for entry in manifest['images'][:14]:
    assert (ROOT/entry['file']).resolve().is_relative_to(ROOT)


class Handler(SimpleHTTPRequestHandler):
    def do_HEAD(self):
        if self.path not in approved:
            self.send_error(404)
            return
        super().do_HEAD()

    def do_GET(self):
        if self.path not in approved:
            self.send_error(404)
            return
        super().do_GET()


ThreadingHTTPServer(('127.0.0.1', args.port), partial(Handler, directory=str(ROOT))).serve_forever()
