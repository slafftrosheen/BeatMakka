"""Serve only the approved 14 PNG sources to the local Studio MCP uploader."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'assets/production/upload-manifest.json').read_text())
approved = {('/' + x['file']) for x in manifest['images'][:14]}


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path not in approved:
            self.send_error(404)
            return
        super().do_GET()


ThreadingHTTPServer(('127.0.0.1', 8769), partial(Handler, directory=str(ROOT))).serve_forever()
