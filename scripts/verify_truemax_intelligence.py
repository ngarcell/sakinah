#!/usr/bin/env python3
"""Validate the versioned TrueMax evidence pack and offline rule boundary."""

from __future__ import annotations

import argparse
from datetime import date
import json
from pathlib import Path
import re
import sys
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs/truemax-intelligence-sources.json"
SWIFT = ROOT / "ios/Sakinah/TrueMax/TrueMaxIntelligenceLayer.swift"


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"[FAIL] TrueMax intelligence: {message}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify TrueMax's local intelligence pack.")
    parser.add_argument(
        "--enforce-freshness",
        action="store_true",
        help="Fail when the evidence review exceeds its declared cadence.",
    )
    parser.add_argument(
        "--as-of",
        help="Use a deterministic YYYY-MM-DD date for freshness checks.",
    )
    args = parser.parse_args()

    try:
        document = json.loads(MANIFEST.read_text(encoding="utf-8"))
        source = SWIFT.read_text(encoding="utf-8")
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        fail(str(error))

    if document.get("schema_version") != 1:
        fail("schema_version must be 1")
    pack_version = document.get("pack_version")
    reviewed_at = document.get("reviewed_at")
    if not isinstance(pack_version, str) or not isinstance(reviewed_at, str):
        fail("pack version and review date are required")
    try:
        reviewed = date.fromisoformat(reviewed_at)
    except ValueError:
        fail("reviewed_at must use YYYY-MM-DD")
    if pack_version != reviewed.strftime("%Y.%m.%d"):
        fail("pack_version must match reviewed_at")
    cadence = document.get("review_cadence_days")
    if not isinstance(cadence, int) or not 30 <= cadence <= 180:
        fail("review_cadence_days must be between 30 and 180")
    if args.enforce_freshness:
        try:
            as_of = date.fromisoformat(args.as_of) if args.as_of else date.today()
        except ValueError:
            fail("--as-of must use YYYY-MM-DD")
        age_days = (as_of - reviewed).days
        if age_days < 0:
            fail(f"evidence review is {abs(age_days)} day(s) in the future")
        if age_days > cadence:
            fail(f"evidence review is {age_days} days old; cadence is {cadence}")

    sources = document.get("sources")
    if not isinstance(sources, list) or not sources:
        fail("sources must be a non-empty list")
    source_ids: set[str] = set()
    for item in sources:
        if not isinstance(item, dict):
            fail("each source must be an object")
        source_id = item.get("id")
        if not isinstance(source_id, str) or source_id in source_ids:
            fail(f"invalid or duplicate source id: {source_id!r}")
        source_ids.add(source_id)
        if item.get("reviewed_at") != reviewed_at:
            fail(f"source {source_id} review date drifted")
        url = item.get("url")
        parsed = urlparse(url) if isinstance(url, str) else None
        if parsed is None or parsed.scheme != "https" or not parsed.netloc:
            fail(f"source {source_id} must have an HTTPS URL")

    required = {
        "vision-face-landmarks",
        "vision-face-capture-quality",
        "avfoundation-photo-capture",
        "avfoundation-depth-data",
        "declared-age-range",
        "privacy-manifest",
        "apple-app-review-safety",
        "nist-ai-rmf-1",
    }
    if not required <= source_ids:
        fail("required source IDs are missing")

    for contract in (
        f"static let schemaVersion = 1",
        f'static let packVersion = "{pack_version}"',
        f'static let revision = "{reviewed_at}"',
    ):
        if source.count(contract) != 1:
            fail(f"Swift knowledge pack must contain exactly one {contract!r}")

    for item in sources:
        source_id = item["id"]
        if f'id: "{source_id}"' not in source:
            fail(f"Swift pack has no entry for {source_id}")
        if f'URL(string: "{item["url"]}")!' not in source:
            fail(f"Swift URL drifted for {source_id}")

    forbidden = ("URLSession", "NWConnection", "CloudKit", "HealthKit")
    if any(token in source for token in forbidden):
        fail("knowledge layer crossed the local-only boundary")

    for token in (
        "TrueMaxIntelligenceEngine.signals(for: scan)",
        "vision-face-capture-quality",
        "nist-ai-rmf-1",
    ):
        if token not in (ROOT / "ios/Sakinah/TrueMax/TrueMaxResultsViews.swift").read_text(encoding="utf-8") + source:
            fail(f"integration contract missing: {token}")

    print(
        f"[PASS] TrueMax intelligence {pack_version}: "
        f"{len(source_ids)} reviewed sources, offline provenance, and UI integration"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
