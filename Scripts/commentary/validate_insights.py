#!/usr/bin/env python3
"""
Commentary Insights Validator

Validates the generated CommentaryData.sqlite against:
1. Schema correctness
2. Segment locator bounds
3. Cross-reference validity (against BibleData.sqlite)
4. Strong's number format
5. Content quality checks (ban list, length)

Usage:
    python validate_insights.py                    # Full validation
    python validate_insights.py --chapter 1        # Validate specific chapter
    python validate_insights.py --fix              # Attempt to fix issues
"""

import argparse
import json
import re
import sqlite3
from pathlib import Path
from typing import Optional

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
BIBLE_DB_PATH = PROJECT_ROOT / "BibleStudy" / "Resources" / "BibleData.sqlite"
COMMENTARY_DB_PATH = PROJECT_ROOT / "BibleStudy" / "Resources" / "CommentaryData.sqlite"

# Validation rules
BAN_LIST = [
    # Doctrinal overreach
    "definitively proves",
    "this verse proves",
    "beyond any doubt",
    "the only correct interpretation",
    "all Christians must believe",
    # Fake/uncertain content markers
    "I believe",
    "in my opinion",
    "probably means",
    # Generic filler
    "how does this make you feel",
    "journal about",
    "pray about this",
]

# Valid Strong's number ranges
STRONGS_GREEK_RANGE = (1, 5624)  # G1-G5624
STRONGS_HEBREW_RANGE = (1, 8674)  # H1-H8674


class ValidationResult:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.insights_checked = 0
        self.insights_valid = 0

    def add_error(self, insight_id: str, message: str):
        self.errors.append(f"[ERROR] {insight_id}: {message}")

    def add_warning(self, insight_id: str, message: str):
        self.warnings.append(f"[WARN] {insight_id}: {message}")

    def print_summary(self):
        print(f"\n=== Validation Summary ===")
        print(f"Insights checked: {self.insights_checked}")
        print(f"Valid: {self.insights_valid}")
        print(f"Errors: {len(self.errors)}")
        print(f"Warnings: {len(self.warnings)}")

        if self.errors:
            print(f"\n=== Errors ({len(self.errors)}) ===")
            for error in self.errors[:20]:
                print(error)
            if len(self.errors) > 20:
                print(f"... and {len(self.errors) - 20} more errors")

        if self.warnings:
            print(f"\n=== Warnings ({len(self.warnings)}) ===")
            for warning in self.warnings[:20]:
                print(warning)
            if len(self.warnings) > 20:
                print(f"... and {len(self.warnings) - 20} more warnings")


def get_verse_text(bible_conn: sqlite3.Connection, book_id: int, chapter: int, verse: int) -> Optional[str]:
    """Get the text of a specific verse."""
    cursor = bible_conn.execute(
        "SELECT text FROM verses WHERE book_id = ? AND chapter = ? AND verse = ? AND translation_id = 'kjv'",
        (book_id, chapter, verse)
    )
    row = cursor.fetchone()
    return row[0] if row else None


def verse_exists(bible_conn: sqlite3.Connection, book_id: int, chapter: int, verse: int) -> bool:
    """Check if a verse exists in the Bible database."""
    cursor = bible_conn.execute(
        "SELECT 1 FROM verses WHERE book_id = ? AND chapter = ? AND verse = ? LIMIT 1",
        (book_id, chapter, verse)
    )
    return cursor.fetchone() is not None


def get_book_id(book_name: str) -> Optional[int]:
    """Convert book name to ID."""
    # Simplified mapping - expand as needed
    BOOKS = {
        "genesis": 1, "gen": 1,
        "exodus": 2, "exod": 2, "ex": 2,
        "leviticus": 3, "lev": 3,
        "numbers": 4, "num": 4,
        "deuteronomy": 5, "deut": 5,
        "joshua": 6, "josh": 6,
        "judges": 7, "judg": 7,
        "ruth": 8,
        "1 samuel": 9, "1samuel": 9, "1 sam": 9,
        "2 samuel": 10, "2samuel": 10, "2 sam": 10,
        "1 kings": 11, "1kings": 11, "1 kgs": 11,
        "2 kings": 12, "2kings": 12, "2 kgs": 12,
        "1 chronicles": 13, "1 chron": 13,
        "2 chronicles": 14, "2 chron": 14,
        "ezra": 15,
        "nehemiah": 16, "neh": 16,
        "esther": 17, "esth": 17,
        "job": 18,
        "psalm": 19, "psalms": 19, "ps": 19, "psa": 19,
        "proverbs": 20, "prov": 20,
        "ecclesiastes": 21, "eccl": 21, "eccles": 21,
        "song of solomon": 22, "song": 22, "sos": 22,
        "isaiah": 23, "isa": 23,
        "jeremiah": 24, "jer": 24,
        "lamentations": 25, "lam": 25,
        "ezekiel": 26, "ezek": 26,
        "daniel": 27, "dan": 27,
        "hosea": 28, "hos": 28,
        "joel": 29,
        "amos": 30,
        "obadiah": 31, "obad": 31,
        "jonah": 32,
        "micah": 33, "mic": 33,
        "nahum": 34, "nah": 34,
        "habakkuk": 35, "hab": 35,
        "zephaniah": 36, "zeph": 36,
        "haggai": 37, "hag": 37,
        "zechariah": 38, "zech": 38,
        "malachi": 39, "mal": 39,
        "matthew": 40, "matt": 40, "mt": 40,
        "mark": 41, "mk": 41,
        "luke": 42, "lk": 42,
        "john": 43, "jn": 43,
        "acts": 44,
        "romans": 45, "rom": 45,
        "1 corinthians": 46, "1 cor": 46, "1cor": 46,
        "2 corinthians": 47, "2 cor": 47, "2cor": 47,
        "galatians": 48, "gal": 48,
        "ephesians": 49, "eph": 49,
        "philippians": 50, "phil": 50,
        "colossians": 51, "col": 51,
        "1 thessalonians": 52, "1 thess": 52,
        "2 thessalonians": 53, "2 thess": 53,
        "1 timothy": 54, "1 tim": 54,
        "2 timothy": 55, "2 tim": 55,
        "titus": 56,
        "philemon": 57, "phlm": 57,
        "hebrews": 58, "heb": 58,
        "james": 59, "jas": 59,
        "1 peter": 60, "1 pet": 60,
        "2 peter": 61, "2 pet": 61,
        "1 john": 62, "1 jn": 62,
        "2 john": 63, "2 jn": 63,
        "3 john": 64, "3 jn": 64,
        "jude": 65,
        "revelation": 66, "rev": 66,
    }
    return BOOKS.get(book_name.lower().strip())


def parse_reference(ref: str) -> Optional[tuple[int, int, int]]:
    """Parse a reference like 'Genesis 1:1' into (book_id, chapter, verse)."""
    match = re.match(r"^(\d?\s*[A-Za-z]+)\s+(\d+):(\d+)", ref.strip())
    if not match:
        return None

    book_name = match.group(1)
    chapter = int(match.group(2))
    verse = int(match.group(3))

    book_id = get_book_id(book_name)
    if not book_id:
        return None

    return (book_id, chapter, verse)


def validate_segment_locator(
    insight: dict,
    verse_text: str,
    result: ValidationResult
) -> bool:
    """Validate that segment locator correctly identifies text."""
    insight_id = insight["id"]
    start = insight["segment_start_char"]
    end = insight["segment_end_char"]
    expected_text = insight["segment_text"]

    # Bounds check
    if start < 0:
        result.add_error(insight_id, f"segment_start_char < 0: {start}")
        return False

    if end > len(verse_text):
        result.add_error(insight_id, f"segment_end_char > verse length: {end} > {len(verse_text)}")
        return False

    if start >= end:
        result.add_error(insight_id, f"segment_start_char >= segment_end_char: {start} >= {end}")
        return False

    # Text match
    actual_text = verse_text[start:end]
    if actual_text != expected_text:
        result.add_error(insight_id, f"Segment text mismatch. Expected '{expected_text}', got '{actual_text}'")
        return False

    return True


def validate_sources(
    insight: dict,
    bible_conn: sqlite3.Connection,
    result: ValidationResult
) -> bool:
    """Validate source references."""
    insight_id = insight["id"]
    sources_json = insight.get("sources", "[]")

    try:
        sources = json.loads(sources_json)
    except json.JSONDecodeError:
        result.add_error(insight_id, "Invalid sources JSON")
        return False

    if not isinstance(sources, list):
        result.add_error(insight_id, "Sources must be an array")
        return False

    for source in sources:
        src_type = source.get("type")
        ref = source.get("reference", "")

        if src_type == "crossReference":
            parsed = parse_reference(ref)
            if not parsed:
                result.add_warning(insight_id, f"Could not parse cross-reference: {ref}")
            else:
                book_id, chapter, verse = parsed
                if not verse_exists(bible_conn, book_id, chapter, verse):
                    result.add_warning(insight_id, f"Cross-reference verse not found: {ref}")

        elif src_type == "strongs":
            # Validate Strong's number format
            match = re.match(r"^([GH])(\d+)$", ref.upper())
            if not match:
                result.add_error(insight_id, f"Invalid Strong's number format: {ref}")
            else:
                prefix = match.group(1)
                number = int(match.group(2))
                if prefix == "G":
                    if not (STRONGS_GREEK_RANGE[0] <= number <= STRONGS_GREEK_RANGE[1]):
                        result.add_warning(insight_id, f"Strong's number out of range: {ref}")
                elif prefix == "H":
                    if not (STRONGS_HEBREW_RANGE[0] <= number <= STRONGS_HEBREW_RANGE[1]):
                        result.add_warning(insight_id, f"Strong's number out of range: {ref}")

    return True


def validate_content_quality(insight: dict, result: ValidationResult) -> bool:
    """Check content against ban list and quality rules."""
    insight_id = insight["id"]
    content = insight.get("content", "").lower()
    title = insight.get("title", "").lower()

    valid = True

    # Check ban list
    for banned in BAN_LIST:
        if banned.lower() in content or banned.lower() in title:
            result.add_warning(insight_id, f"Contains banned phrase: '{banned}'")
            valid = False

    # Length checks
    content_len = len(insight.get("content", ""))
    if content_len < 30:
        result.add_warning(insight_id, f"Content too short: {content_len} chars")
        valid = False
    elif content_len > 500:
        result.add_warning(insight_id, f"Content too long: {content_len} chars")
        valid = False

    title_len = len(insight.get("title", ""))
    if title_len < 3:
        result.add_warning(insight_id, f"Title too short: {title_len} chars")
        valid = False
    elif title_len > 50:
        result.add_warning(insight_id, f"Title too long: {title_len} chars")
        valid = False

    return valid


def validate_chapter(
    commentary_conn: sqlite3.Connection,
    bible_conn: sqlite3.Connection,
    book_id: int,
    chapter: int,
    result: ValidationResult
):
    """Validate all insights for a chapter."""
    cursor = commentary_conn.execute(
        """
        SELECT id, book_id, chapter, verse_start, verse_end,
               segment_text, segment_start_char, segment_end_char,
               insight_type, title, content, icon, sources
        FROM commentary_insights
        WHERE book_id = ? AND chapter = ?
        ORDER BY verse_start, segment_start_char
        """,
        (book_id, chapter)
    )

    insights = []
    for row in cursor:
        insights.append({
            "id": row[0],
            "book_id": row[1],
            "chapter": row[2],
            "verse_start": row[3],
            "verse_end": row[4],
            "segment_text": row[5],
            "segment_start_char": row[6],
            "segment_end_char": row[7],
            "insight_type": row[8],
            "title": row[9],
            "content": row[10],
            "icon": row[11],
            "sources": row[12],
        })

    print(f"John {chapter}: {len(insights)} insights")

    for insight in insights:
        result.insights_checked += 1

        # Get verse text
        verse_text = get_verse_text(
            bible_conn,
            insight["book_id"],
            insight["chapter"],
            insight["verse_start"]
        )

        if not verse_text:
            result.add_error(insight["id"], f"Verse not found: {insight['book_id']}:{insight['chapter']}:{insight['verse_start']}")
            continue

        # Run validations
        locator_valid = validate_segment_locator(insight, verse_text, result)
        sources_valid = validate_sources(insight, bible_conn, result)
        quality_valid = validate_content_quality(insight, result)

        if locator_valid and sources_valid and quality_valid:
            result.insights_valid += 1


def main():
    parser = argparse.ArgumentParser(description="Validate commentary insights")
    parser.add_argument("--chapter", type=int, help="Validate specific chapter")
    parser.add_argument("--fix", action="store_true", help="Attempt to fix issues (not implemented)")

    args = parser.parse_args()

    if not COMMENTARY_DB_PATH.exists():
        print(f"Commentary database not found: {COMMENTARY_DB_PATH}")
        print("Run generate_commentary.py first to create insights.")
        return

    if not BIBLE_DB_PATH.exists():
        print(f"Bible database not found: {BIBLE_DB_PATH}")
        return

    commentary_conn = sqlite3.connect(COMMENTARY_DB_PATH)
    bible_conn = sqlite3.connect(BIBLE_DB_PATH)

    result = ValidationResult()

    if args.chapter:
        chapters = [args.chapter]
    else:
        # Get all chapters with insights
        cursor = commentary_conn.execute(
            "SELECT DISTINCT chapter FROM commentary_insights WHERE book_id = 43 ORDER BY chapter"
        )
        chapters = [row[0] for row in cursor]

    if not chapters:
        print("No insights found to validate.")
        return

    print(f"Validating chapters: {chapters}")
    print()

    for chapter in chapters:
        validate_chapter(commentary_conn, bible_conn, 43, chapter, result)

    result.print_summary()

    commentary_conn.close()
    bible_conn.close()


if __name__ == "__main__":
    main()
