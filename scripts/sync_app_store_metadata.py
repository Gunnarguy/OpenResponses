#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "AppStoreMetadata.md"
OUTPUT_DIR = ROOT / "fastlane" / "metadata" / "en-US"
REVIEW_INFO_DIR = OUTPUT_DIR.parent / "review_information"

ASCII_MAP = {
    "\u2014": "--",
    "\u2013": "-",
    "\u2019": "'",
    "\u2018": "'",
    "\u201c": '"',
    "\u201d": '"',
    "\u2026": "...",
    "\u22ef": "...",
    "\u00a0": " ",
}


def asciiize(text: str) -> str:
    for src, dst in ASCII_MAP.items():
        text = text.replace(src, dst)
    return text


def parse_sections(text: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current: str | None = None
    for line in text.splitlines():
        if line.startswith("## "):
            heading = line[3:].strip()
            heading = heading.split(" (")[0].strip()
            current = heading
            sections.setdefault(current, [])
            continue
        if current is not None:
            sections[current].append(line)
    return sections


def strip_markdown(line: str) -> str:
    line = re.sub(r"^#{1,6}\s+", "", line)
    line = line.replace("**", "")
    line = re.sub(r"\*([^*]+)\*", r"\1", line)
    return line


def normalize_plain(lines: list[str]) -> str:
    normalized = [asciiize(line.rstrip()) for line in lines]
    return "\n".join(normalized).strip()


def normalize_markdown(lines: list[str]) -> str:
    normalized = [asciiize(strip_markdown(line.rstrip())) for line in lines]
    return "\n".join(normalized).strip()


def parse_labeled_bullets(lines: list[str]) -> dict[str, str]:
    data: dict[str, str] = {}
    pattern = re.compile(r"^-\s+\*\*([^*]+)\*\*\s+(.*)$")
    for line in lines:
        match = pattern.match(line.strip())
        if match:
            label = match.group(1).strip().rstrip(":")
            data[label] = match.group(2).strip()
    return data


def extract_url(value: str) -> str:
    if not value:
        return ""
    bracketed = re.search(r"<([^>]+)>", value)
    if bracketed:
        return bracketed.group(1)
    match = re.search(r"https?://\S+", value)
    if match:
        return match.group(0).rstrip(").,")
    return value.split()[0]


def extract_email(value: str) -> str:
    if not value:
        return ""
    match = re.search(r"mailto:([^>\\s]+)", value)
    if match:
        return match.group(1)
    match = re.search(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", value)
    if match:
        return match.group(0)
    return value.split()[0]


def extract_phone(value: str) -> str:
    if not value:
        return ""
    match = re.search(r"\\+?\\d[\\d\\s().-]{6,}", value)
    if match:
        return match.group(0).strip()
    return value.strip()


def extract_subsection(lines: list[str], heading: str) -> list[str]:
    start = None
    marker = f"### {heading}".strip().lower()
    for idx, line in enumerate(lines):
        if line.strip().lower() == marker:
            start = idx + 1
            break
    if start is None:
        return []
    block: list[str] = []
    for line in lines[start:]:
        if line.startswith("### "):
            break
        block.append(line)
    while block and not block[0].strip():
        block.pop(0)
    while block and not block[-1].strip():
        block.pop()
    return block


def extract_note_lines(lines: list[str]) -> list[str]:
    notes = []
    for line in lines:
        stripped = line.strip()
        if stripped.lower().startswith("note:"):
            notes.append(strip_markdown(stripped))
    return notes


def split_name(full_name: str) -> tuple[str, str]:
    parts = [part for part in full_name.split() if part.strip()]
    if not parts:
        return "", ""
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], " ".join(parts[1:])


def require(mapping: dict[str, str], key: str) -> str:
    if key not in mapping or not mapping[key].strip():
        raise KeyError(key)
    return mapping[key].strip()


def main() -> int:
    if not SOURCE.exists():
        print(f"Missing source file: {SOURCE}", file=sys.stderr)
        return 1

    text = SOURCE.read_text(encoding="utf-8")
    sections = parse_sections(text)

    required_sections = [
        "Quick Reference",
        "Promotional Text",
        "Full Description",
        "Keywords",
        "URLs",
    ]
    missing_sections = [section for section in required_sections if section not in sections]
    if missing_sections:
        print(f"Missing sections: {', '.join(missing_sections)}", file=sys.stderr)
        return 1

    release_key = next((key for key in sections if key.startswith("What's New in ")), None)
    if not release_key:
        print("Missing release notes section (expected 'What's New in X.Y.Z')", file=sys.stderr)
        return 1

    quick_ref = parse_labeled_bullets(sections["Quick Reference"])
    urls = parse_labeled_bullets(sections["URLs"])
    review_section = sections.get("Review Information", [])
    review_info = parse_labeled_bullets(review_section)

    try:
        name = require(quick_ref, "Name")
        subtitle = require(quick_ref, "Subtitle")
        primary_category = require(quick_ref, "Primary Category")
        secondary_category = require(quick_ref, "Secondary Category")
    except KeyError as exc:
        print(f"Missing Quick Reference field: {exc.args[0]}", file=sys.stderr)
        return 1

    try:
        marketing_url = extract_url(require(urls, "Marketing URL"))
        support_url = extract_url(require(urls, "Support URL"))
        privacy_url = extract_url(require(urls, "Privacy Policy URL"))
    except KeyError as exc:
        print(f"Missing URL field: {exc.args[0]}", file=sys.stderr)
        return 1

    files = {
        "name.txt": asciiize(name),
        "subtitle.txt": asciiize(subtitle),
        "promotional_text.txt": normalize_plain(sections["Promotional Text"]),
        "description.txt": normalize_markdown(sections["Full Description"]),
        "keywords.txt": normalize_plain(sections["Keywords"]),
        "release_notes.txt": normalize_markdown(sections[release_key]),
        "marketing_url.txt": asciiize(marketing_url),
        "support_url.txt": asciiize(support_url),
        "privacy_url.txt": asciiize(privacy_url),
        "primary_category.txt": asciiize(primary_category),
        "secondary_category.txt": asciiize(secondary_category),
    }

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for filename, content in files.items():
        if not content:
            print(f"Missing content for {filename}", file=sys.stderr)
            return 1
        path = OUTPUT_DIR / filename
        path.write_text(f"{content.strip()}\n", encoding="utf-8")

    review_files: dict[str, str] = {}
    if review_info:
        try:
            contact_name = require(review_info, "Contact Name")
            contact_email = require(review_info, "Contact Email")
            contact_phone = require(review_info, "Contact Phone")
        except KeyError as exc:
            print(f"Missing Review Information field: {exc.args[0]}", file=sys.stderr)
            return 1

        first_name, last_name = split_name(strip_markdown(contact_name))
        email = extract_email(contact_email)
        phone = extract_phone(strip_markdown(contact_phone))

        notes_parts: list[str] = []
        demo_account = review_info.get("Demo Account")
        if demo_account:
            notes_parts.append(f"Demo account: {strip_markdown(demo_account)}")
        availability = review_info.get("Availability")
        if availability:
            notes_parts.append(f"Availability: {strip_markdown(availability)}")
        demo_content = extract_subsection(review_section, "Demo Content Provided")
        demo_content = [line for line in demo_content if not line.strip().lower().startswith("note:")]
        if demo_content:
            notes_parts.append("Demo content provided:\n" + normalize_markdown(demo_content))
        walkthrough = extract_subsection(sections.get("Review Information", []), "Reviewer Walkthrough")
        if walkthrough:
            notes_parts.append("Reviewer walkthrough:\n" + normalize_markdown(walkthrough))
        note_lines = extract_note_lines(review_section)
        if note_lines:
            notes_parts.append("\n".join(note_lines))
        notes = "\n\n".join(notes_parts).strip()

        review_files = {
            "first_name.txt": asciiize(first_name),
            "last_name.txt": asciiize(last_name),
            "email_address.txt": asciiize(email),
            "phone_number.txt": asciiize(phone),
        }
        if notes:
            review_files["notes.txt"] = asciiize(notes)

    if review_files:
        REVIEW_INFO_DIR.mkdir(parents=True, exist_ok=True)
        for filename, content in review_files.items():
            if not content:
                print(f"Missing content for review information {filename}", file=sys.stderr)
                return 1
            path = REVIEW_INFO_DIR / filename
            path.write_text(f"{content.strip()}\n", encoding="utf-8")

    written = ", ".join(sorted(files.keys()))
    if review_files:
        written_review = ", ".join(sorted(review_files.keys()))
        print(f"Wrote fastlane review information files: {written_review}")
    print(f"Wrote fastlane metadata files: {written}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
