#!/usr/bin/env python3
"""Regenerate content/manifest.json from the files in content/.

Usage:
    python3 scripts/generate-manifest.py [--title "My Library"]

The manifest is the only file the app needs to know about. Every other file is
discovered through it, so this script is the single source of truth for what
the app sees.

The output is deterministic (paths sorted) so diffs stay clean.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1

# Files that must never appear in the manifest.
IGNORE_NAMES = {".DS_Store", "manifest.json", ".gitkeep"}

EXTENSIONS = {
    ".md": "markdown",
    ".markdown": "markdown",
    ".html": "html",
    ".htm": "html",
    ".png": "image",
    ".jpg": "image",
    ".jpeg": "image",
    ".gif": "image",
    ".webp": "image",
    ".svg": "image",
}


def classify(path: Path) -> str:
    return EXTENSIONS.get(path.suffix.lower(), "other")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


_TITLE_RE = re.compile(r"^\s*#\s+(.+)$", re.MULTILINE)


def extract_title(path: Path) -> str | None:
    """For markdown, pull the first H1 as the title. Otherwise fall back to filename."""
    if classify(path) != "markdown":
        return None
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None
    match = _TITLE_RE.search(text)
    return match.group(1).strip() if match else None


def collect_entries(root: Path) -> list[dict]:
    entries = []
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if path.name in IGNORE_NAMES:
            continue
        rel = path.relative_to(root)
        entries.append({
            "path": str(rel).replace("\\", "/"),  # normalize on Windows
            "title": extract_title(path),
            "kind": classify(path),
            "sha256": sha256(path),
            "size": path.stat().st_size,
        })
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description="Regenerate content/manifest.json")
    parser.add_argument("--title", default="Markdown zobrazovač",
                        help="Library title shown in the app (default: %(default)s)")
    parser.add_argument("--content-dir", default="content",
                        help="Directory to scan (default: %(default)s)")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    content_dir = (repo_root / args.content_dir).resolve()
    if not content_dir.is_dir():
        print(f"error: {content_dir} is not a directory", file=sys.stderr)
        return 1

    entries = collect_entries(content_dir)
    manifest = {
        "schemaVersion": SCHEMA_VERSION,
        "title": args.title,
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "entries": entries,
    }

    out_path = content_dir / "manifest.json"
    out_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out_path} ({len(entries)} entries)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
