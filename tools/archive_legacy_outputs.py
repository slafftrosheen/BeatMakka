"""Archive superseded generated demos only; the default is a read-only dry run.

Nothing outside output/needle-quay-demo is a cleanup source. Every moved file,
including obsolete Studio lock markers, is retained with a SHA-256 receipt.
Live, foreign-host and unrecognised locks are preserved. Studio is never closed.
"""
import argparse
import ctypes
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import stat
import uuid

ROOT = Path(__file__).absolute().parents[1]
OUTPUT = ROOT / "output/needle-quay-demo"
ARCHIVE_ROOT = ROOT.parent / "BeatMaka-Archive"
DEFAULT_ARCHIVE = ARCHIVE_ROOT / "2026-10-30-groovebox-v4"
FINAL_STEM = "NeedleQuay-Groovebox-v4"
GENERATED_FILE = re.compile(r"NeedleQuay-[A-Za-z0-9][A-Za-z0-9._-]*\.(?:rbxlx?|zip)(?:\.partial)?$")
LEGACY_REPORTS = {"ROJO_WARNING_FIX.md", "STUDIO_QA.md", "cleanup-blockouts.json", "cleanup-final.json"}


def plain_path(path):
    """Reject links/reparse points at every existing path component."""
    path = path.absolute()
    for component in (path, *path.parents):
        try:
            info = component.lstat()
        except FileNotFoundError:
            continue
        if stat.S_ISLNK(info.st_mode) or getattr(info, "st_file_attributes", 0) & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400):
            raise ValueError(f"Refusing linked path: {component}")
    return path.resolve()


def child_path(path, root):
    resolved, boundary = plain_path(path), plain_path(root)
    if resolved == boundary or not resolved.is_relative_to(boundary):
        raise ValueError(f"Path escaped intended directory: {path}")
    return resolved


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def process_state(pid):
    """Check the expected Studio owner, including recycled PIDs; errors stay unknown."""
    if os.name != "nt" or pid <= 0:
        return "unknown"
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.OpenProcess.argtypes = [ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
    kernel.OpenProcess.restype = ctypes.c_void_p
    kernel.GetExitCodeProcess.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong)]
    kernel.QueryFullProcessImageNameW.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_wchar_p, ctypes.POINTER(ctypes.c_ulong)]
    kernel.CloseHandle.argtypes = [ctypes.c_void_p]
    handle = kernel.OpenProcess(0x1000, False, pid)
    if not handle:
        return "absent" if ctypes.get_last_error() == 87 else "unknown"
    try:
        code = ctypes.c_ulong()
        if not kernel.GetExitCodeProcess(handle, ctypes.byref(code)):
            return "unknown"
        if code.value != 259:
            return "absent"
        image = ctypes.create_unicode_buffer(32768)
        length = ctypes.c_ulong(len(image))
        if not kernel.QueryFullProcessImageNameW(handle, 0, image, ctypes.byref(length)):
            return "unknown"
        return "alive" if Path(image.value).name.casefold() == "robloxstudiobeta.exe" else "absent"
    finally:
        kernel.CloseHandle(handle)


def lock_state(path):
    plain_path(path)
    try:
        lines = path.read_text(encoding="utf-8-sig").rstrip("\r\n").splitlines()
        if len(lines) != 4 or lines[1] != "RobloxStudioBeta" or lines[2].casefold() != platform.node().casefold():
            return "unknown"
        pid = int(lines[0])
    except (OSError, ValueError, UnicodeError):
        return "unknown"
    return "obsolete" if process_state(pid) == "absent" else "live_or_unknown"


def tree_paths(path):
    plain_path(path)
    if not path.is_dir():
        return [path]
    result = []
    for parent, directories, files in os.walk(path, followlinks=False):
        parent = Path(parent)
        directories.sort()
        for name in sorted(directories + files):
            entry = parent / name
            child_path(entry, OUTPUT)
            result.append(entry)
    return result


def blocking_lock(path):
    paths = tree_paths(path)
    locks = [entry for entry in paths if entry.name.endswith(".lock")]
    paired = path.with_name(path.name + ".lock")
    if paired.exists() and paired not in locks:
        locks.append(paired)
    return [str(entry.relative_to(OUTPUT)) for entry in locks if lock_state(entry) != "obsolete"]


def exclusive_readable(path):
    """Conservatively skip files held open even without a Studio lock marker."""
    if os.name != "nt":
        return False
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.CreateFileW.argtypes = [ctypes.c_wchar_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_void_p]
    kernel.CreateFileW.restype = ctypes.c_void_p
    kernel.CloseHandle.argtypes = [ctypes.c_void_p]
    handle = kernel.CreateFileW(str(path), 0x80000000, 0, None, 3, 0x80, None)
    if handle == ctypes.c_void_p(-1).value:
        return False
    kernel.CloseHandle(handle)
    return True


def inventory(path):
    entries = []
    for entry in tree_paths(path):
        if entry.is_file():
            if not exclusive_readable(entry):
                raise PermissionError(f"File is open or cannot be checked exclusively: {entry}")
            info = entry.stat()
            entries.append({"file": entry.relative_to(path).as_posix() if path.is_dir() else entry.name,
                            "bytes": info.st_size, "sha256": sha256(entry)})
        elif not entry.is_dir():
            raise ValueError(f"Unsupported file type: {entry}")
    return entries


def generated_directory(path):
    if not path.name.startswith("NeedleQuay-") or not path.is_dir():
        return False
    plain_path(path)
    return any((path / (path.name + suffix)).is_file() for suffix in (".rbxlx", ".rbxl")) and (path / "Launch-NeedleQuay.ps1").is_file()


def select_candidates():
    candidates, kept = [], []
    for path in sorted(OUTPUT.iterdir()):
        child_path(path, OUTPUT)
        if path.name == FINAL_STEM or path.name.startswith(FINAL_STEM + "."):
            kept.append({"source": path.relative_to(ROOT).as_posix(), "reason": "final_demo"})
            continue
        old_lock = path.name.endswith(".lock") and GENERATED_FILE.fullmatch(path.name[:-5])
        generated = GENERATED_FILE.fullmatch(path.name) or generated_directory(path) or path.name in LEGACY_REPORTS
        if not old_lock and not generated:
            kept.append({"source": path.relative_to(ROOT).as_posix(), "reason": "not_a_generated_old_demo"})
            continue
        if old_lock and lock_state(path) != "obsolete":
            kept.append({"source": path.relative_to(ROOT).as_posix(), "reason": "live_or_unknown_lock"})
            continue
        if old_lock:
            associated = path.with_name(path.name[:-5])
            if associated.exists() and not exclusive_readable(child_path(associated, OUTPUT)):
                kept.append({"source": path.relative_to(ROOT).as_posix(), "reason": "associated_place_is_open"})
                continue
        locks = blocking_lock(path)
        if locks:
            kept.append({"source": path.relative_to(ROOT).as_posix(), "reason": "live_or_unknown_lock", "locks": locks})
            continue
        try:
            files = inventory(path)
        except PermissionError as error:
            kept.append({"source": path.relative_to(ROOT).as_posix(), "reason": str(error)})
            continue
        candidates.append((path, {"source": path.relative_to(ROOT).as_posix(), "bytes": sum(row["bytes"] for row in files),
                                  "files": files, "obsolete_lock": bool(old_lock), "state": "planned"}))
    return candidates, kept


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Move safe generated old demos; never delete unique bytes.")
    parser.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE, help="A child of the dedicated sibling BeatMaka-Archive directory.")
    args = parser.parse_args()
    child_path(OUTPUT, ROOT)
    archive = child_path(args.archive, ARCHIVE_ROOT)
    if not OUTPUT.is_dir():
        raise FileNotFoundError(OUTPUT)
    if args.apply:
        for suffix in (".rbxlx", ".zip"):
            final = child_path(OUTPUT / (FINAL_STEM + suffix), OUTPUT)
            if not final.is_file() or final.stat().st_size == 0:
                raise ValueError("Build and package NeedleQuay-Groovebox-v4 before archiving older demos")
    candidates, kept = select_candidates()
    run_name = datetime.now(timezone.utc).strftime("run-%Y%m%dT%H%M%SZ-") + uuid.uuid4().hex[:8]
    run = child_path(archive / run_name, archive)
    receipt = {"schema": 1, "applied": args.apply, "source_boundary": str(OUTPUT), "archive": str(archive),
               "run": str(run) if args.apply else None, "items": [row for _, row in candidates], "kept": kept,
               "archived_bytes": 0, "deleted_bytes": 0, "studio_processes_closed": 0}
    if not args.apply:
        print(json.dumps(receipt, indent=2))
        return
    run.mkdir(parents=True, exist_ok=False)
    plain_path(run)
    receipt_path = run / "receipt.json"

    def save_receipt():
        partial = run / "receipt.json.partial"
        partial.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        os.replace(partial, receipt_path)

    save_receipt()
    for path, row in candidates:
        target = child_path(run / row["source"], run)
        row["archive"] = str(target)
        # Recheck immediately before an atomic same-volume rename. Never use a
        # copy/delete fallback or remove a place/lock after a failed rename.
        if blocking_lock(path) or (row["obsolete_lock"] and lock_state(path) != "obsolete"):
            row["state"] = "kept_lock_changed"
            save_receipt()
            continue
        if row["obsolete_lock"]:
            associated = path.with_name(path.name[:-5])
            if associated.exists() and not exclusive_readable(child_path(associated, OUTPUT)):
                row["state"] = "kept_associated_place_open"
                save_receipt()
                continue
        try:
            if inventory(path) != row["files"]:
                row["state"] = "kept_content_changed"
                save_receipt()
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            plain_path(target.parent)
            if target.exists():
                raise FileExistsError(target)
            row["state"] = "moving"
            save_receipt()
            path.rename(target)
        except PermissionError as error:
            row["state"] = "kept_locked_path"
            row["detail"] = str(error)
            save_receipt()
            continue
        # Retain the complete original file tree. No deduplication deletes.
        for file in row["files"]:
            archived = target / file["file"] if target.is_dir() else target
            child_path(archived, run)
            if archived.stat().st_size != file["bytes"] or sha256(archived) != file["sha256"]:
                row["state"] = "archive_verification_failed"
                save_receipt()
                raise RuntimeError(f"Archive verification failed; retained at {target}")
        row["state"] = "archived_verified"
        receipt["archived_bytes"] += row["bytes"]
        save_receipt()
    print(json.dumps({**receipt, "receipt": str(receipt_path)}, indent=2))


if __name__ == "__main__":
    main()
