#!/usr/bin/env python3
"""Offline, fail-closed readiness check for a proposed Tripo batch.

This script never contacts Tripo, uploads files, or submits work.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as stream:
        value = json.load(stream)
    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return value


def resolve_repo_path(value: str, base: Path = ROOT) -> Path:
    path = (base / value).resolve()
    if path != ROOT and ROOT not in path.parents:
        raise ValueError(f"Path escapes repository: {value}")
    return path


def receipt_is_fresh(receipt: dict[str, Any], max_age_hours: int) -> bool:
    timestamp = receipt.get("checked_at")
    if not isinstance(timestamp, str):
        return False
    try:
        checked_at = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
    except ValueError:
        return False
    if checked_at.tzinfo is None:
        return False
    age = datetime.now(timezone.utc) - checked_at.astimezone(timezone.utc)
    return 0 <= age.total_seconds() <= max_age_hours * 3600


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="Batch manifest JSON file")
    parser.add_argument("--max-doc-age-hours", type=int, default=24)
    args = parser.parse_args()

    errors: list[str] = []
    try:
        manifest_path = args.manifest.resolve()
        manifest = read_json(manifest_path)
        assets_data = read_json(ROOT / "data" / "assets.json")
        recipes_data = read_json(ROOT / "data" / "job_recipes.json")
        asset_by_id = {str(item["id"]): item for item in assets_data.get("assets", [])}
        recipe_by_id = {str(item["id"]): item for item in recipes_data.get("recipes", [])}

        authorization = manifest.get("authorization", {})
        if authorization.get("approved") is not True:
            errors.append("User authorization is not marked approved.")
        cap = authorization.get("approved_cap_credits")
        if not isinstance(cap, (int, float)) or cap <= 0:
            errors.append("Approved credit cap must be a positive number.")

        approved_ids = set(map(str, authorization.get("approved_asset_ids", [])))
        requests = manifest.get("requests", [])
        if not requests:
            errors.append("Batch has no requests.")
        request_ids = [str(item.get("asset_id", "")) for item in requests]
        if len(request_ids) != len(set(request_ids)):
            errors.append("Each canonical asset ID may appear only once in this manifest.")
        for asset_id in request_ids:
            if asset_id not in approved_ids:
                errors.append(f"{asset_id}: not included in the approved asset list.")
            if asset_id not in asset_by_id:
                errors.append(f"{asset_id}: unknown canonical asset ID.")
            if asset_id not in recipe_by_id:
                errors.append(f"{asset_id}: no candidate recipe exists.")

        estimate_total = 0.0
        for request in requests:
            asset_id = str(request.get("asset_id", ""))
            asset = asset_by_id.get(asset_id, {})
            recipe = recipe_by_id.get(asset_id, {})
            estimate = request.get("estimated_credits")
            if not isinstance(estimate, (int, float)) or estimate < 0:
                errors.append(f"{asset_id}: missing or invalid estimated_credits.")
            else:
                estimate_total += estimate

            operation = recipe.get("operation")
            reference_value = request.get("approved_reference")
            if operation == "image-to-model":
                if not isinstance(reference_value, str) or not reference_value:
                    errors.append(f"{asset_id}: approved_reference is required for the image route.")
                else:
                    reference = resolve_repo_path(reference_value)
                    if not reference.is_file():
                        errors.append(f"{asset_id}: approved reference file is missing: {reference_value}")
            elif operation == "text-to-model":
                if request.get("prompt") != recipe.get("prompt"):
                    errors.append(f"{asset_id}: request prompt must exactly match the reviewed recipe.")
            else:
                errors.append(f"{asset_id}: unsupported candidate operation: {operation}")

            face_limit = request.get("face_limit")
            cap_for_asset = asset.get("tripo_face_limit")
            if not isinstance(face_limit, int) or not isinstance(cap_for_asset, int):
                errors.append(f"{asset_id}: face_limit and canonical asset cap must be integers.")
            elif face_limit <= 0 or face_limit > cap_for_asset:
                errors.append(f"{asset_id}: face_limit exceeds the canonical per-asset cap.")
            elif face_limit != recipe.get("candidate_face_cap"):
                errors.append(f"{asset_id}: face_limit differs from the canonical candidate recipe.")

            dry_run_value = request.get("dry_run_receipt")
            if not isinstance(dry_run_value, str) or not dry_run_value:
                errors.append(f"{asset_id}: dry_run_receipt is required.")
                continue
            dry_run_path = resolve_repo_path(dry_run_value)
            if not dry_run_path.is_file():
                errors.append(f"{asset_id}: dry-run receipt is missing: {dry_run_value}")
                continue
            dry_run = read_json(dry_run_path)
            if dry_run.get("dry_run") is not True or dry_run.get("valid") is not True:
                errors.append(f"{asset_id}: the recorded CLI dry run is not valid.")
                continue
            steps = dry_run.get("steps", [])
            payloads = [step.get("payload", {}) for step in steps]
            expected_face_limit = recipe.get("candidate_face_cap")
            endpoint = (
                "/v3/generation/image-to-model"
                if operation == "image-to-model"
                else "/v3/generation/text-to-model"
            )
            def route_matches(step: dict[str, Any], payload: dict[str, Any]) -> bool:
                if step.get("endpoint") != endpoint:
                    return False
                if operation == "text-to-model":
                    return payload.get("prompt") == recipe.get("prompt")
                return (
                    isinstance(payload.get("input"), str)
                    and payload.get("input", "").startswith("<upload:")
                    and Path(payload.get("input", "")[8:-1]).name == Path(reference_value).name
                )

            if not any(
                route_matches(step, payload)
                and
                payload.get("model") == "P1-20260311"
                and payload.get("face_limit") == expected_face_limit
                and payload.get("texture") is False
                and payload.get("pbr") is False
                and payload.get("export_uv") is True
                for step, payload in zip(steps, payloads)
            ):
                errors.append(f"{asset_id}: dry-run must match the canonical geometry-only P1 {operation} recipe.")

        quoted_total = manifest.get("quoted_total_credits")
        if not isinstance(quoted_total, (int, float)) or quoted_total < 0:
            errors.append("A current quoted_total_credits value is required.")
        elif isinstance(cap, (int, float)) and quoted_total > cap:
            errors.append("Current quote exceeds the approved cap.")
        if isinstance(quoted_total, (int, float)) and estimate_total > quoted_total:
            errors.append("Per-request estimates exceed the batch quote.")

        for field in ("connection_receipt", "docs_receipt"):
            receipt_path_value = manifest.get(field)
            if not isinstance(receipt_path_value, str):
                errors.append(f"{field} is required.")
                continue
            receipt = read_json(resolve_repo_path(receipt_path_value))
            if not receipt_is_fresh(receipt, args.max_doc_age_hours):
                errors.append(f"{field} is older than {args.max_doc_age_hours} hours or has an invalid timestamp.")
            if field == "connection_receipt" and receipt.get("verified") is not True:
                errors.append("Connected Tripo account and required schema are not verified.")
            if field == "connection_receipt":
                account_check = receipt.get("account_check", {})
                balance = receipt.get("balance_credits", account_check.get("balance_credits"))
                if account_check.get("balance_checked") is not True:
                    errors.append("Live Tripo API balance has not been checked.")
                elif not isinstance(balance, (int, float)) or balance < 0:
                    errors.append("Live Tripo API balance is missing or invalid.")
                elif isinstance(quoted_total, (int, float)) and balance < quoted_total:
                    errors.append(
                        f"Live Tripo API balance ({balance:g}) is below this batch quote ({quoted_total:g})."
                    )
            if field == "docs_receipt" and receipt.get("verified") is not True:
                errors.append("Current official docs and schema receipt is not marked verified.")

    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        errors.append(str(error))

    result = {"passed": not errors, "errors": errors}
    print(json.dumps(result, indent=2))
    return 0 if not errors else 2


if __name__ == "__main__":
    sys.exit(main())
