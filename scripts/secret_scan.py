#!/usr/bin/env python3
"""Simple repository secret scanner for release preflight.

Scans a curated list of file extensions and flags suspicious credential
patterns (e.g., OpenAI `sk-` keys, long token literals). Exits with a
non-zero status when potential secrets are detected so CI or local
pre-submit hooks can block the release until resolved.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterable, Tuple

# File extensions that warrant scanning. Markdown and other docs are
# excluded to avoid false positives caused by instructional snippets.
SCAN_EXTENSIONS = {
    ".swift",
    ".m",
    ".mm",
    ".plist",
    ".json",
    ".yaml",
    ".yml",
    ".sh",
    ".py",
    ".env",
    ".xcconfig",
}

# Suspicious patterns to flag. Each entry pairs a short label with the
# compiled regular expression so we can surface concise diagnostics.
SUSPICIOUS_PATTERNS: Tuple[Tuple[str, re.Pattern[str]], ...] = (
    (
        "openai_key",
        re.compile(r"sk-[A-Za-z0-9]{24,}"),
    ),
    (
        "generic_token",
        re.compile(
            r"(?i)(api|token|secret|bearer)[-_ ]?(key|token)?\s*[:=]\s*['\"][A-Za-z0-9_\-]{20,}"
        ),
    ),
)

# Relative paths that should be ignored entirely. Extend this list if a
# future build introduces generated artifacts with placeholder values.
IGNORE_PATHS = {
    Path("scripts/secret_scan.py"),  # Avoid flagging ourselves
}

REPO_ROOT = Path(__file__).resolve().parent.parent


def iter_candidate_files(root: Path) -> Iterable[Path]:
    """Yield repository files with extensions we want to inspect."""

    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.relative_to(root) in IGNORE_PATHS:
            continue
        if path.suffix.lower() not in SCAN_EXTENSIONS:
            continue
        yield path


def scan_file(path: Path) -> Iterable[Tuple[int, str, str]]:
    """Scan a file for suspicious secrets.

    Returns a sequence of `(line_number, pattern_label, line_contents)`
    tuples whenever a regex matches.
    """

    try:
        contents = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        # Skip binary blobs that sneak in with matching extensions.
        return []

    findings = []
    for label, pattern in SUSPICIOUS_PATTERNS:
        for match in pattern.finditer(contents):
            line_number = contents.count("\n", 0, match.start()) + 1
            findings.append((line_number, label, match.group()))
    return findings


def main() -> int:
    findings: list[tuple[Path, int, str, str]] = []

    for file_path in iter_candidate_files(REPO_ROOT):
        for line_number, label, snippet in scan_file(file_path):
            findings.append((file_path, line_number, label, snippet))

    if not findings:
        print("✅ Secret scan passed: no suspicious tokens detected.")
        return 0

    print("❌ Potential secrets detected:\n")
    for path, line_number, label, snippet in findings:
        relative = path.relative_to(REPO_ROOT)
        print(f"- {label}: {relative}:{line_number} → {snippet}")

    print("\nResolve or confirm false positives before archiving the release build.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
