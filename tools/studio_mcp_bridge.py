"""Use the configured local Studio MCP launcher when its tools aren't surfaced.

JSON-RPC over stdio; schemas are discovered before any tool invocation.
No credentials are read or configured. Requests are explicit JSON files.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import queue
import subprocess
import threading
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--list-tools", action="store_true")
parser.add_argument("--request", type=Path)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--timeout", type=int, default=45)
parser.add_argument("--image-output", type=Path)
args = parser.parse_args()
launcher = Path(os.environ["LOCALAPPDATA"]) / "Roblox/mcp.bat"
process = subprocess.Popen(["cmd.exe", "/c", str(launcher)], stdin=subprocess.PIPE,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8")
messages = queue.Queue()


def read_lines(stream):
    for line in stream:
        try:
            messages.put(json.loads(line))
        except json.JSONDecodeError:
            pass


threading.Thread(target=read_lines, args=(process.stdout,), daemon=True).start()
# Drain diagnostic stderr without exposing local session data.
threading.Thread(target=lambda: [None for _ in process.stderr], daemon=True).start()


def send(message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()


def rpc(request_id, method, params):
    send({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params})
    deadline = time.monotonic() + args.timeout
    while time.monotonic() < deadline:
        try:
            item = messages.get(timeout=min(1, max(.01, deadline - time.monotonic())))
        except queue.Empty:
            if process.poll() is not None:
                raise RuntimeError("Studio MCP launcher exited: " + str(process.returncode))
            continue
        if item.get("id") == request_id:
            if "error" in item:
                raise RuntimeError(json.dumps(item["error"]))
            return item.get("result")
    raise TimeoutError("Studio MCP timed out: " + method)


try:
    initialization = rpc(1, "initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                           "clientInfo": {"name": "Codex-BeatMakka", "version": "1.0"}})
    send({"jsonrpc": "2.0", "method": "notifications/initialized"})
    if args.list_tools:
        result = rpc(2, "tools/list", {})
    elif args.request:
        request = json.loads(args.request.read_text(encoding="utf-8"))
        result = rpc(2, "tools/call", request)
    else:
        parser.error("Choose --list-tools or --request")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    printable = dict(result) if isinstance(result, dict) else result
    if isinstance(result, dict):
        content = []
        for block in result.get("content", []):
            if block.get("type") == "image":
                if args.image_output:
                    args.image_output.parent.mkdir(parents=True, exist_ok=True)
                    args.image_output.write_bytes(base64.b64decode(block["data"]))
                content.append({"type": "image", "saved": str(args.image_output), "mimeType": block.get("mimeType")})
            else:
                content.append(block)
        printable["content"] = content
    print(json.dumps(printable, ensure_ascii=True)[:16000])
finally:
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
