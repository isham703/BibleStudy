#!/usr/bin/env python3
"""
Living Commentary Pre-Generation Pipeline

Generates marginalia insights for the Gospel of John using OpenAI GPT-4o mini.
Outputs to CommentaryData.sqlite for bundling with the app.

Usage:
    python generate_commentary.py --chapter 1           # Generate for John 1 only
    python generate_commentary.py --sample              # Generate sample (1, 3, 11, 21)
    python generate_commentary.py --all                 # Generate all of John
    python generate_commentary.py --validate            # Validate existing DB

Requirements:
    pip install openai
    OPENAI_API_KEY environment variable set

Estimated cost: ~$0.50-1.00 for all of John (879 verses)
"""

import argparse
import json
import os
import re
import sqlite3
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple, Union

try:
    from openai import OpenAI
except ImportError:
    print("Error: openai package not installed. Run: pip install openai")
    sys.exit(1)

# Configuration
CONFIG = {
    "model": "gpt-4o-mini",  # Cost-efficient with excellent JSON support
    "prompt_version": "v1.0",
    "context_window": 2,  # Verses before/after for context
    "max_retries": 3,
    "john_book_id": 43,
    "john_chapters": 21,
}

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
BIBLE_DB_PATH = PROJECT_ROOT / "BibleStudy" / "Resources" / "BibleData.sqlite"
OUTPUT_DB_PATH = PROJECT_ROOT / "BibleStudy" / "Resources" / "CommentaryData.sqlite"
PROMPT_PATH = SCRIPT_DIR / "prompts" / "marginalia_prompt.txt"


def load_prompt_template() -> str:
    """Load the marginalia prompt template."""
    with open(PROMPT_PATH, "r") as f:
        return f.read()


def get_bible_connection() -> sqlite3.Connection:
    """Connect to the bundled Bible database."""
    if not BIBLE_DB_PATH.exists():
        raise FileNotFoundError(f"Bible database not found: {BIBLE_DB_PATH}")
    return sqlite3.connect(BIBLE_DB_PATH)


def get_output_connection() -> sqlite3.Connection:
    """Connect to or create the commentary output database."""
    conn = sqlite3.connect(OUTPUT_DB_PATH)
    create_schema(conn)
    return conn


def create_schema(conn: sqlite3.Connection):
    """Create the commentary_insights table if it doesn't exist."""
    conn.execute("""
        CREATE TABLE IF NOT EXISTS commentary_insights (
            id TEXT PRIMARY KEY,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse_start INTEGER NOT NULL,
            verse_end INTEGER NOT NULL,
            segment_text TEXT NOT NULL,
            segment_start_char INTEGER NOT NULL,
            segment_end_char INTEGER NOT NULL,
            insight_type TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            icon TEXT NOT NULL,
            sources TEXT,
            content_version INTEGER NOT NULL,
            prompt_version TEXT NOT NULL,
            model_version TEXT NOT NULL,
            created_at TEXT NOT NULL,
            quality_tier TEXT DEFAULT 'standard',
            is_interpretive INTEGER DEFAULT 0
        )
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_insights_chapter
        ON commentary_insights(book_id, chapter)
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_insights_verse
        ON commentary_insights(book_id, chapter, verse_start)
    """)
    conn.commit()


def get_verses(conn: sqlite3.Connection, book_id: int, chapter: int) -> list[dict]:
    """Get all verses for a chapter."""
    cursor = conn.execute(
        """
        SELECT verse, text FROM verses
        WHERE book_id = ? AND chapter = ? AND translation_id = 'kjv'
        ORDER BY verse
        """,
        (book_id, chapter)
    )
    return [{"verse": row[0], "text": row[1]} for row in cursor.fetchall()]


def get_context_window(verses: list[dict], verse_num: int, window: int) -> str:
    """Get surrounding verses for context."""
    context_lines = []
    for v in verses:
        if verse_num - window <= v["verse"] <= verse_num + window:
            marker = ">>>" if v["verse"] == verse_num else "   "
            context_lines.append(f"{marker} {v['verse']}. {v['text']}")
    return "\n".join(context_lines)


def generate_insights_for_verse(
    client: OpenAI,
    prompt_template: str,
    book_name: str,
    chapter: int,
    verse: dict,
    context: str
) -> Optional[dict]:
    """Call OpenAI API to generate insights for a single verse."""

    prompt = prompt_template.format(
        book_name=book_name,
        chapter=chapter,
        verse_number=verse["verse"],
        verse_text=verse["text"],
        context_verses=context
    )

    # System message to enforce JSON output
    system_message = """You are a biblical scholar creating marginalia for Scripture study.
Output valid JSON only. No markdown code blocks. No explanation outside the JSON.
Follow the schema exactly as specified in the user prompt."""

    try:
        response = client.chat.completions.create(
            model=CONFIG["model"],
            response_format={"type": "json_object"},  # Enforce JSON output
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2000,
            temperature=0.7
        )

        # Extract JSON from response
        content = response.choices[0].message.content.strip()

        return json.loads(content)

    except json.JSONDecodeError as e:
        print(f"  Warning: Failed to parse JSON for verse {verse['verse']}: {e}")
        return None
    except Exception as e:
        print(f"  Warning: API error for verse {verse['verse']}: {e}")
        return None


def find_segment_in_verse(segment_text: str, verse_text: str) -> Optional[Tuple[int, int, str]]:
    """
    Find the segment text in the verse and return corrected indices.
    Returns (start, end, actual_text) or None if not found.

    Handles:
    - Exact matches
    - Case-insensitive matches
    - Matches with minor punctuation differences
    """
    # Try exact match first
    idx = verse_text.find(segment_text)
    if idx >= 0:
        return (idx, idx + len(segment_text), segment_text)

    # Try case-insensitive match
    lower_verse = verse_text.lower()
    lower_segment = segment_text.lower()
    idx = lower_verse.find(lower_segment)
    if idx >= 0:
        # Return the actual text from the verse (preserving original case)
        actual = verse_text[idx:idx + len(segment_text)]
        return (idx, idx + len(actual), actual)

    # Try matching without trailing/leading punctuation
    stripped = segment_text.strip(".,;:!?\"' ")
    if stripped != segment_text:
        idx = verse_text.find(stripped)
        if idx >= 0:
            return (idx, idx + len(stripped), stripped)

    # Try fuzzy: find longest substring match
    # Look for the core words in the segment
    words = segment_text.split()
    if len(words) >= 2:
        # Try matching first few words
        for num_words in range(len(words), 0, -1):
            partial = " ".join(words[:num_words])
            idx = verse_text.lower().find(partial.lower())
            if idx >= 0:
                # Find actual extent in verse
                actual = verse_text[idx:idx + len(partial)]
                return (idx, idx + len(actual), actual)

    return None


def normalize_cross_reference(ref: str) -> bool:
    """
    Validate cross-reference format.
    Handles: "Genesis 1:1", "1 John 1:5", "2 Peter 3:9", "Song of Solomon 1:1"
    """
    # Pattern: optional number + book name (may have spaces) + chapter:verse
    # Examples: "Genesis 1:1", "1 John 1:5", "Song of Solomon 2:4"
    pattern = r"^(\d\s+)?([A-Za-z]+(\s+[A-Za-z]+)*)\s+\d+:\d+(-\d+)?$"
    return bool(re.match(pattern, ref.strip()))


def validate_and_fix_insight(insight: dict, verse_text: str, verse_num: int) -> Tuple[Optional[dict], list]:
    """
    Validate a single insight, auto-fix segment locators, and return (fixed_insight, issues).
    Returns (None, issues) if unfixable, (fixed_insight, []) if valid/fixed.
    """
    issues = []

    # Required fields
    required = ["segment_text", "segment_start_char", "segment_end_char",
                "type", "title", "content", "icon"]
    for field in required:
        if field not in insight:
            issues.append(f"Missing required field: {field}")

    if issues:
        return (None, issues)

    # Auto-fix segment locator by finding text in verse
    segment_text = insight["segment_text"]
    found = find_segment_in_verse(segment_text, verse_text)

    if found:
        start, end, actual_text = found
        # Update insight with corrected values
        insight["segment_start_char"] = start
        insight["segment_end_char"] = end
        insight["segment_text"] = actual_text
    else:
        issues.append(f"Segment text not found in verse: '{segment_text}'")
        return (None, issues)

    # Validate type
    valid_types = ["connection", "greek", "theology", "question"]
    if insight["type"] not in valid_types:
        issues.append(f"Invalid type: {insight['type']}")
        return (None, issues)

    # Validate sources for connection type
    if insight["type"] == "connection":
        sources = insight.get("sources", [])
        if not sources:
            issues.append("Connection insight missing sources")
            return (None, issues)

        for src in sources:
            if src.get("type") == "crossReference":
                ref = src.get("reference", "")
                if not normalize_cross_reference(ref):
                    issues.append(f"Invalid cross-reference format: {ref}")
                    return (None, issues)

    # Validate Greek insights have Strong's numbers
    if insight["type"] == "greek":
        content = insight.get("content", "")
        if not re.search(r"[GH]\d{1,5}", content):
            issues.append("Greek insight missing Strong's number (G#### or H####)")
            return (None, issues)

    return (insight, [])


def save_insight(
    conn: sqlite3.Connection,
    book_id: int,
    chapter: int,
    verse_num: int,
    insight: dict,
    index: int
) -> bool:
    """Save a validated insight to the database."""

    insight_id = f"{book_id}_{chapter}_{verse_num}_{insight['type']}_{index}"

    sources_json = json.dumps(insight.get("sources", []))

    try:
        conn.execute("""
            INSERT OR REPLACE INTO commentary_insights (
                id, book_id, chapter, verse_start, verse_end,
                segment_text, segment_start_char, segment_end_char,
                insight_type, title, content, icon, sources,
                content_version, prompt_version, model_version,
                created_at, quality_tier, is_interpretive
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            insight_id,
            book_id,
            chapter,
            verse_num,
            verse_num,  # verse_end = verse_start for single-verse insights
            insight["segment_text"],
            insight["segment_start_char"],
            insight["segment_end_char"],
            insight["type"],
            insight["title"],
            insight["content"],
            insight["icon"],
            sources_json,
            1,  # content_version
            CONFIG["prompt_version"],
            CONFIG["model"],
            datetime.now().isoformat(),
            "standard",
            1 if insight.get("is_interpretive", False) else 0
        ))
        return True
    except sqlite3.Error as e:
        print(f"  Warning: Failed to save insight {insight_id}: {e}")
        return False


def generate_chapter(
    client: OpenAI,
    bible_conn: sqlite3.Connection,
    output_conn: sqlite3.Connection,
    prompt_template: str,
    chapter: int,
    dry_run: bool = False
):
    """Generate insights for an entire chapter."""

    print(f"\n=== John Chapter {chapter} ===")

    verses = get_verses(bible_conn, CONFIG["john_book_id"], chapter)
    if not verses:
        print(f"  No verses found for John {chapter}")
        return

    print(f"  Found {len(verses)} verses")

    total_insights = 0
    total_issues = 0

    for verse in verses:
        context = get_context_window(verses, verse["verse"], CONFIG["context_window"])

        print(f"  Generating for verse {verse['verse']}...", end=" ", flush=True)

        result = generate_insights_for_verse(
            client, prompt_template, "John", chapter, verse, context
        )

        if not result or "insights" not in result:
            print("(no insights)")
            continue

        insights = result["insights"]
        valid_count = 0

        for i, insight in enumerate(insights):
            fixed_insight, issues = validate_and_fix_insight(insight, verse["text"], verse["verse"])

            if issues:
                total_issues += len(issues)
                for issue in issues:
                    print(f"\n    Issue: {issue}")
            elif fixed_insight:
                if not dry_run:
                    if save_insight(output_conn, CONFIG["john_book_id"], chapter, verse["verse"], fixed_insight, i):
                        valid_count += 1
                else:
                    valid_count += 1

        print(f"({valid_count}/{len(insights)} valid)")
        total_insights += valid_count

    if not dry_run:
        output_conn.commit()

    print(f"\n  Chapter {chapter} complete: {total_insights} insights saved, {total_issues} issues found")


def main():
    parser = argparse.ArgumentParser(description="Generate Living Commentary insights")
    parser.add_argument("--chapter", type=int, help="Generate for a specific chapter")
    parser.add_argument("--sample", action="store_true", help="Generate sample chapters (1, 3, 11, 21)")
    parser.add_argument("--all", action="store_true", help="Generate all chapters")
    parser.add_argument("--validate", action="store_true", help="Validate existing database")
    parser.add_argument("--dry-run", action="store_true", help="Don't save to database")

    args = parser.parse_args()

    if not (args.chapter or args.sample or args.all or args.validate):
        parser.print_help()
        return

    # Check API key
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key and not args.validate:
        print("Error: OPENAI_API_KEY environment variable not set")
        sys.exit(1)

    # Load prompt template
    prompt_template = load_prompt_template()

    # Connect to databases
    bible_conn = get_bible_connection()
    output_conn = get_output_connection()

    if args.validate:
        print("Validating existing commentary database...")
        cursor = output_conn.execute("SELECT COUNT(*) FROM commentary_insights")
        count = cursor.fetchone()[0]
        print(f"Total insights: {count}")

        # Check by chapter
        cursor = output_conn.execute("""
            SELECT chapter, COUNT(*) FROM commentary_insights
            WHERE book_id = 43 GROUP BY chapter ORDER BY chapter
        """)
        for row in cursor:
            print(f"  John {row[0]}: {row[1]} insights")
        return

    # Initialize API client
    client = OpenAI(api_key=api_key)

    # Determine chapters to generate
    if args.chapter:
        chapters = [args.chapter]
    elif args.sample:
        chapters = [1, 3, 11, 21]  # Sample chapters for review
    elif args.all:
        chapters = list(range(1, CONFIG["john_chapters"] + 1))
    else:
        chapters = []

    print(f"Generating insights for John chapters: {chapters}")
    print(f"Model: {CONFIG['model']}")
    print(f"Prompt version: {CONFIG['prompt_version']}")
    if args.dry_run:
        print("DRY RUN - not saving to database")

    for chapter in chapters:
        generate_chapter(
            client, bible_conn, output_conn, prompt_template,
            chapter, dry_run=args.dry_run
        )

    # Final summary
    if not args.dry_run:
        cursor = output_conn.execute("SELECT COUNT(*) FROM commentary_insights")
        total = cursor.fetchone()[0]
        print(f"\n=== Generation Complete ===")
        print(f"Total insights in database: {total}")
        print(f"Output saved to: {OUTPUT_DB_PATH}")

    bible_conn.close()
    output_conn.close()


if __name__ == "__main__":
    main()
