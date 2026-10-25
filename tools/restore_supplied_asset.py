"""Restore losslessly archived user-supplied GLB assets."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/supplied-asset-archives.json"
def digest(path):
    h=hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda:stream.read(4*1024*1024),b""):h.update(block)
    return h.hexdigest()
def main():
    rows=json.loads(MANIFEST.read_text(encoding="utf-8"))["assets"]
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name",choices=[Path(row["source"]).stem for row in rows])
    args=parser.parse_args()
    item=next(row for row in rows if Path(row["source"]).stem==args.name)
    def local(relative):
        path=(ROOT/relative).resolve()
        if ROOT not in path.parents:raise ValueError("Archive path escapes the repository")
        return path
    archive,target=local(item["archive"]),local(item["source"])
    if digest(archive)!=item["archive_sha256"]:raise ValueError("Compressed asset checksum mismatch")
    if target.exists():
        if target.stat().st_size==item["bytes"] and digest(target)==item["sha256"]:
            print(f"Already restored and verified: {target.relative_to(ROOT)}")
            return
        raise FileExistsError(f"Refusing to replace an existing different file: {target}")
    temporary=target.with_name(target.name+".restore.tmp")
    target.parent.mkdir(parents=True,exist_ok=True)
    original=hashlib.sha256();length=0
    try:
        with gzip.open(archive,"rb") as source,temporary.open("xb") as output:
            for block in iter(lambda:source.read(4*1024*1024),b""):
                output.write(block);original.update(block);length+=len(block)
        if length!=item["bytes"] or original.hexdigest()!=item["sha256"]:
            raise ValueError("Restored asset size or checksum mismatch")
        os.replace(temporary,target)
    except BaseException:
        if temporary.exists():temporary.unlink()
        raise
    print(f"Restored and verified {target.relative_to(ROOT)} ({length} bytes)")
if __name__=="__main__":main()
