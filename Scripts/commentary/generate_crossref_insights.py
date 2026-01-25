#!/usr/bin/env python3
"""
Generate Rich Cross-Reference Explanations for Bible Study App

This script:
1. Reads cross-references from BibleData.sqlite
2. Selects 5-7 diversified cross-refs per verse
3. Generates AI explanations for each connection
4. Inserts into Supabase crossref_explanations table

Usage:
    # Set credentials:
    export DATABASE_URL="postgresql://..."
    export OPENAI_API_KEY="sk-..."

    # Generate for a specific chapter:
    python generate_crossref_insights.py --book john --chapter 3

    # Generate for entire book:
    python generate_crossref_insights.py --book john --all

    # Test mode (no API calls, just show selections):
    python generate_crossref_insights.py --book john --chapter 3 --dry-run

Requirements:
    pip install openai psycopg2-binary
"""

import argparse
import json
import os
import sqlite3
import sys
import time
from pathlib import Path
from typing import Optional

try:
    from openai import OpenAI
except ImportError:
    print("Error: openai package not installed. Run: pip install openai")
    sys.exit(1)

try:
    import psycopg2
except ImportError:
    print("Error: psycopg2 package not installed. Run: pip install psycopg2-binary")
    sys.exit(1)

# Configuration
CONFIG = {
    "model": "gpt-4o-mini",
    "prompt_version": "v1.2",  # Added retry/backoff, validation, deterministic ordering
    "min_crossrefs": 5,
    "max_crossrefs": 7,
    "max_per_book": 2,  # Diversification: max 2 targets per book
    "adjacency_threshold": 5,  # Avoid targets within ±5 verses of each other
    "max_retries": 3,  # Retry on transient API failures
    "base_delay": 1.0,  # Base delay for exponential backoff (seconds)
    "translation_id": "kjv",  # Translation for verse lookups
}

# Book mappings
BOOKS = {
    # Old Testament
    1: "Genesis", 2: "Exodus", 3: "Leviticus", 4: "Numbers", 5: "Deuteronomy",
    6: "Joshua", 7: "Judges", 8: "Ruth", 9: "1 Samuel", 10: "2 Samuel",
    11: "1 Kings", 12: "2 Kings", 13: "1 Chronicles", 14: "2 Chronicles",
    15: "Ezra", 16: "Nehemiah", 17: "Esther", 18: "Job", 19: "Psalms",
    20: "Proverbs", 21: "Ecclesiastes", 22: "Song of Solomon", 23: "Isaiah",
    24: "Jeremiah", 25: "Lamentations", 26: "Ezekiel", 27: "Daniel",
    28: "Hosea", 29: "Joel", 30: "Amos", 31: "Obadiah", 32: "Jonah",
    33: "Micah", 34: "Nahum", 35: "Habakkuk", 36: "Zephaniah", 37: "Haggai",
    38: "Zechariah", 39: "Malachi",
    # New Testament
    40: "Matthew", 41: "Mark", 42: "Luke", 43: "John", 44: "Acts",
    45: "Romans", 46: "1 Corinthians", 47: "2 Corinthians", 48: "Galatians",
    49: "Ephesians", 50: "Philippians", 51: "Colossians", 52: "1 Thessalonians",
    53: "2 Thessalonians", 54: "1 Timothy", 55: "2 Timothy", 56: "Titus",
    57: "Philemon", 58: "Hebrews", 59: "James", 60: "1 Peter", 61: "2 Peter",
    62: "1 John", 63: "2 John", 64: "3 John", 65: "Jude", 66: "Revelation",
}

BOOK_NAME_TO_ID = {v.lower().replace(" ", ""): k for k, v in BOOKS.items()}
BOOK_NAME_TO_ID.update({
    "1sam": 9, "2sam": 10, "1kgs": 11, "2kgs": 12,
    "1chr": 13, "2chr": 14, "1cor": 46, "2cor": 47,
    "1thess": 52, "2thess": 53, "1tim": 54, "2tim": 55,
    "1pet": 60, "2pet": 61, "1jn": 62, "2jn": 63, "3jn": 64,
    "songofsolomon": 22, "songofsongs": 22,
})

# Connection type keywords for classification
CONNECTION_KEYWORDS = {
    "quotation": ["quote", "quoted", "citing", "citation", "allusion", "allude", "echoes"],
    "theme": ["theme", "thematic", "concept", "idea", "motif"],
    "typology": ["type", "shadow", "prefigure", "antitype", "foreshadow"],
    "prophecy": ["prophec", "fulfill", "foretold", "predict"],
    "parallel": ["parallel", "similar", "compare", "analogy", "likewise"],
    "keyword": ["word", "term", "phrase", "language", "vocabulary"],
}

# Prompt for generating cross-reference explanations
CROSSREF_PROMPT = """You are a biblical scholar explaining why two Bible passages are connected.

SOURCE VERSE ({source_ref}):
"{source_text}"

TARGET PASSAGE ({target_ref}):
"{target_text}"

These passages have been identified as connected by biblical scholars. Explain WHY in 2-3 sentences.

Respond in JSON format:
{{
    "title": "Brief title for this connection (3-6 words)",
    "content": "2-3 sentence explanation of the connection",
    "connection_type": "one of: quotation, theme, typology, prophecy, parallel, keyword, other",
    "anchor_phrase": "exact phrase from SOURCE verse that links to target (must appear verbatim in source text above, or null)",
    "confidence": "high, medium, or low - based on how clear/direct the textual connection is"
}}

STRICT RULES - You must follow these:
1. ONLY reference words, phrases, or concepts that appear in the verses above
2. The anchor_phrase MUST be copied exactly from the source verse text, or use null
3. Do NOT add theological claims, historical facts, or interpretations beyond what the text states
4. Do NOT speculate about author intent or historical context
5. Use hedging language: "This connection highlights..." or "Both passages emphasize..."
6. Keep explanations to observable textual/thematic parallels only
7. If the connection is weak or unclear, say so honestly
8. Maximum 8 words for any direct quote"""


class CrossRefGenerator:
    def __init__(self, bible_db_path: Path, dry_run: bool = False, output_sql: str = None):
        self.bible_db = sqlite3.connect(bible_db_path)
        self.dry_run = dry_run
        self.output_sql = output_sql
        self.sql_values = []  # Collect SQL values for batch output
        self.openai = None if dry_run else OpenAI()
        self.pg_conn = None

        if not dry_run and not output_sql:
            db_url = os.environ.get("DATABASE_URL")
            if not db_url:
                print("Error: Set DATABASE_URL environment variable (or use --output-sql)")
                sys.exit(1)
            self.pg_conn = psycopg2.connect(db_url)

    def close(self):
        self.bible_db.close()
        if self.pg_conn:
            self.pg_conn.close()
        if self.output_sql and self.sql_values:
            self._write_sql_file()

    def _escape_sql(self, text: str) -> str:
        """Escape text for SQL insertion."""
        if text is None:
            return "NULL"
        # Replace curly/smart quotes with standard ones before escaping
        text = text.replace("'", "'").replace("'", "'").replace(""", '"').replace(""", '"')
        return "'" + text.replace("'", "''") + "'"

    def _write_sql_file(self):
        """Write collected values to SQL file."""
        output_path = Path(self.output_sql)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        columns = "(source_book_id, source_chapter, source_verse, target_book_id, target_chapter, target_verse_start, target_verse_end, anchor_phrase, title, content, connection_type, weight, confidence, prompt_version, model)"

        sql = f"INSERT INTO crossref_explanations {columns}\nVALUES\n"
        sql += ",\n".join(self.sql_values)
        sql += "\nON CONFLICT (source_book_id, source_chapter, source_verse, target_book_id, target_chapter, target_verse_start, target_verse_end, connection_type) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, anchor_phrase = EXCLUDED.anchor_phrase, weight = EXCLUDED.weight, confidence = EXCLUDED.confidence, updated_at = now();"

        output_path.write_text(sql)
        print(f"\nWritten {len(self.sql_values)} rows to {output_path}")

    def get_verse_text(self, book_id: int, chapter: int, verse_start: int, verse_end: int = None) -> str:
        """Get verse text from BibleData.sqlite."""
        verse_end = verse_end or verse_start
        cursor = self.bible_db.cursor()
        cursor.execute("""
            SELECT text FROM verses
            WHERE translation_id = ? AND book_id = ? AND chapter = ? AND verse BETWEEN ? AND ?
            ORDER BY verse
        """, (CONFIG["translation_id"], book_id, chapter, verse_start, verse_end))
        rows = cursor.fetchall()
        return " ".join(row[0] for row in rows)

    def get_cross_references(self, book_id: int, chapter: int, verse: int) -> list:
        """Get all cross-references for a verse, ordered by weight with deterministic tie-breaking."""
        cursor = self.bible_db.cursor()
        cursor.execute("""
            SELECT target_book_id, target_chapter, target_verse_start, target_verse_end, weight
            FROM cross_references
            WHERE source_book_id = ? AND source_chapter = ? AND source_verse_start = ?
            ORDER BY weight DESC, target_book_id ASC, target_chapter ASC,
                     target_verse_start ASC, target_verse_end ASC
        """, (book_id, chapter, verse))
        return cursor.fetchall()

    def _select_with_constraints(self, crossrefs: list, max_per_book: int,
                                    adjacency_threshold: int, max_count: int) -> list:
        """Helper to select crossrefs with given constraints."""
        selected = []
        book_counts = {}
        selected_positions = []

        for ref in crossrefs:
            target_book, target_chapter, target_verse_start, target_verse_end, weight = ref

            # Check max per book constraint
            if book_counts.get(target_book, 0) >= max_per_book:
                continue

            # Check adjacency constraint
            is_adjacent = False
            for prev_book, prev_chapter, prev_verse in selected_positions:
                if prev_book == target_book and prev_chapter == target_chapter:
                    if abs(prev_verse - target_verse_start) <= adjacency_threshold:
                        is_adjacent = True
                        break

            if is_adjacent:
                continue

            selected.append(ref)
            book_counts[target_book] = book_counts.get(target_book, 0) + 1
            selected_positions.append((target_book, target_chapter, target_verse_start))

            if len(selected) >= max_count:
                break

        return selected

    def diversify_crossrefs(self, crossrefs: list) -> list:
        """Select diversified cross-references (5-7, with fallback if constraints too strict)."""
        min_refs = CONFIG["min_crossrefs"]
        max_refs = CONFIG["max_crossrefs"]

        # Pass 1: Strict constraints
        selected = self._select_with_constraints(
            crossrefs,
            CONFIG["max_per_book"],
            CONFIG["adjacency_threshold"],
            max_refs
        )

        if len(selected) >= min_refs:
            return selected

        # Pass 2: Relax adjacency threshold
        selected = self._select_with_constraints(
            crossrefs, CONFIG["max_per_book"], 20, max_refs
        )

        if len(selected) >= min_refs:
            return selected

        # Pass 3: Relax max per book
        selected = self._select_with_constraints(
            crossrefs, 4, 20, max_refs
        )

        if len(selected) >= min_refs:
            return selected

        # Pass 4: No constraints, just take top by weight
        return crossrefs[:max_refs]

    def format_reference(self, book_id: int, chapter: int, verse_start: int, verse_end: int = None) -> str:
        """Format a verse reference string."""
        book_name = BOOKS.get(book_id, f"Book {book_id}")
        if verse_end and verse_end != verse_start:
            return f"{book_name} {chapter}:{verse_start}-{verse_end}"
        return f"{book_name} {chapter}:{verse_start}"

    def classify_connection(self, content: str) -> str:
        """Classify connection type based on content keywords."""
        content_lower = content.lower()
        for conn_type, keywords in CONNECTION_KEYWORDS.items():
            if any(kw in content_lower for kw in keywords):
                return conn_type
        return "other"

    def _validate_explanation(self, result: dict, source_text: str) -> dict:
        """Validate and sanitize AI-generated explanation."""
        # Required keys
        required_keys = ["title", "content", "connection_type"]
        for key in required_keys:
            if key not in result or not result[key]:
                raise ValueError(f"Missing required key: {key}")

        # Validate and sanitize title (3-6 words recommended, but allow up to 10)
        title = str(result["title"]).strip()
        if len(title.split()) > 10:
            title = " ".join(title.split()[:10])
        result["title"] = title

        # Validate content (non-empty, reasonable length)
        content = str(result["content"]).strip()
        if len(content) < 20:
            raise ValueError("Content too short")
        result["content"] = content

        # Validate connection_type
        valid_types = ["quotation", "theme", "typology", "prophecy", "parallel", "keyword", "other"]
        if result.get("connection_type") not in valid_types:
            result["connection_type"] = self.classify_connection(content)

        # Validate confidence
        valid_confidence = ["high", "medium", "low"]
        if result.get("confidence") not in valid_confidence:
            result["confidence"] = "medium"

        # Validate anchor_phrase exists in source text (if provided)
        anchor = result.get("anchor_phrase")
        if anchor and str(anchor).lower() not in source_text.lower():
            result["anchor_phrase"] = None

        return result

    def generate_explanation(self, source_ref: str, source_text: str,
                            target_ref: str, target_text: str) -> dict:
        """Generate AI explanation with retry/backoff for transient failures."""
        if self.dry_run:
            return {
                "title": f"Connection to {target_ref}",
                "content": "[DRY RUN - No API call made]",
                "connection_type": "theme",
                "confidence": "medium",
                "anchor_phrase": None
            }

        prompt = CROSSREF_PROMPT.format(
            source_ref=source_ref,
            source_text=source_text,
            target_ref=target_ref,
            target_text=target_text
        )

        last_error = None
        for attempt in range(CONFIG["max_retries"]):
            try:
                response = self.openai.chat.completions.create(
                    model=CONFIG["model"],
                    messages=[{"role": "user", "content": prompt}],
                    response_format={"type": "json_object"},
                    temperature=0.2,
                    max_tokens=300,
                )
                result = json.loads(response.choices[0].message.content)

                # Validate and return
                return self._validate_explanation(result, source_text)

            except json.JSONDecodeError as e:
                last_error = f"Invalid JSON: {e}"
                # Retry on malformed JSON
            except ValueError as e:
                last_error = f"Validation failed: {e}"
                # Retry on validation failure
            except Exception as e:
                error_str = str(e).lower()
                # Retry on rate limit or server errors
                if "rate" in error_str or "429" in error_str or "500" in error_str or "502" in error_str or "503" in error_str:
                    last_error = f"API error (retrying): {e}"
                else:
                    # Non-retryable error
                    print(f"  Error generating explanation: {e}")
                    return None

            # Exponential backoff
            delay = CONFIG["base_delay"] * (2 ** attempt)
            print(f"  Retry {attempt + 1}/{CONFIG['max_retries']} after {delay}s: {last_error}")
            time.sleep(delay)

        print(f"  Failed after {CONFIG['max_retries']} retries: {last_error}")
        return None

    def insert_crossref(self, source_book_id: int, source_chapter: int, source_verse: int,
                       target_book_id: int, target_chapter: int, target_verse_start: int,
                       target_verse_end: int, explanation: dict, weight: float):
        """Queue cross-reference for batch insert."""
        if self.dry_run:
            print(f"    [DRY RUN] Would insert: {explanation['title']}")
            return True

        # SQL output mode - collect values
        if self.output_sql:
            anchor = self._escape_sql(explanation.get("anchor_phrase"))
            title = self._escape_sql(explanation["title"])
            content = self._escape_sql(explanation["content"])
            conn_type = self._escape_sql(explanation["connection_type"])
            confidence = self._escape_sql(explanation.get("confidence", "medium"))
            prompt_v = self._escape_sql(CONFIG["prompt_version"])
            model = self._escape_sql(CONFIG["model"])

            value = f"({source_book_id}, {source_chapter}, {source_verse}, {target_book_id}, {target_chapter}, {target_verse_start}, {target_verse_end}, {anchor}, {title}, {content}, {conn_type}, {weight}, {confidence}, {prompt_v}, {model})"
            self.sql_values.append(value)
            return True

        # Direct database insert (batched - commit happens in commit_batch)
        try:
            with self.pg_conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO crossref_explanations
                    (source_book_id, source_chapter, source_verse,
                     target_book_id, target_chapter, target_verse_start, target_verse_end,
                     anchor_phrase, title, content, connection_type, weight, confidence,
                     prompt_version, model)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (source_book_id, source_chapter, source_verse,
                                target_book_id, target_chapter, target_verse_start, target_verse_end,
                                connection_type)
                    DO UPDATE SET
                        title = EXCLUDED.title,
                        content = EXCLUDED.content,
                        anchor_phrase = EXCLUDED.anchor_phrase,
                        weight = EXCLUDED.weight,
                        confidence = EXCLUDED.confidence,
                        updated_at = now()
                """, (
                    source_book_id, source_chapter, source_verse,
                    target_book_id, target_chapter, target_verse_start, target_verse_end,
                    explanation.get("anchor_phrase"),
                    explanation["title"],
                    explanation["content"],
                    explanation["connection_type"],
                    weight,
                    explanation.get("confidence", "medium"),
                    CONFIG["prompt_version"],
                    CONFIG["model"]
                ))
            return True
        except Exception as e:
            print(f"    Error inserting: {e}")
            return False

    def commit_batch(self):
        """Commit pending database inserts."""
        if self.pg_conn:
            try:
                self.pg_conn.commit()
            except Exception as e:
                self.pg_conn.rollback()
                print(f"  Error committing batch: {e}")

    def process_verse(self, book_id: int, chapter: int, verse: int):
        """Process cross-references for a single verse."""
        source_ref = self.format_reference(book_id, chapter, verse)
        source_text = self.get_verse_text(book_id, chapter, verse)

        if not source_text:
            return 0

        # Get and diversify cross-references
        all_refs = self.get_cross_references(book_id, chapter, verse)
        selected_refs = self.diversify_crossrefs(all_refs)

        if not selected_refs:
            return 0

        print(f"  {source_ref}: {len(selected_refs)} cross-refs selected from {len(all_refs)} available")

        success_count = 0
        for ref in selected_refs:
            target_book, target_chapter, target_verse_start, target_verse_end, weight = ref
            target_ref = self.format_reference(target_book, target_chapter, target_verse_start, target_verse_end)
            target_text = self.get_verse_text(target_book, target_chapter, target_verse_start, target_verse_end)

            if not target_text:
                continue

            # Generate explanation
            explanation = self.generate_explanation(source_ref, source_text, target_ref, target_text)

            if explanation:
                if self.insert_crossref(
                    book_id, chapter, verse,
                    target_book, target_chapter, target_verse_start, target_verse_end,
                    explanation, weight
                ):
                    success_count += 1
                    print(f"    -> {target_ref}: {explanation['title']} [{explanation.get('confidence', 'medium')}]")

            # Rate limit
            if not self.dry_run:
                time.sleep(0.2)

        # Commit after each verse (batch per verse instead of per row)
        self.commit_batch()

        return success_count

    def process_chapter(self, book_id: int, chapter: int):
        """Process all verses in a chapter."""
        cursor = self.bible_db.cursor()
        cursor.execute("""
            SELECT DISTINCT verse FROM verses
            WHERE book_id = ? AND chapter = ?
            ORDER BY verse
        """, (book_id, chapter))
        verses = [row[0] for row in cursor.fetchall()]

        book_name = BOOKS.get(book_id, f"Book {book_id}")
        print(f"\nProcessing {book_name} {chapter} ({len(verses)} verses)...")

        total_generated = 0
        for verse in verses:
            total_generated += self.process_verse(book_id, chapter, verse)

        print(f"  Generated {total_generated} cross-ref explanations")
        return total_generated

    def process_book(self, book_id: int, chapters: Optional[list] = None, start_chapter: int = 1, end_chapter: int = None):
        """Process all chapters in a book, optionally with start/end chapter range."""
        cursor = self.bible_db.cursor()
        cursor.execute("""
            SELECT DISTINCT chapter FROM verses
            WHERE book_id = ?
            ORDER BY chapter
        """, (book_id,))
        all_chapters = [row[0] for row in cursor.fetchall()]

        if chapters:
            all_chapters = [c for c in all_chapters if c in chapters]

        # Filter to chapter range (for resume/partial runs)
        if start_chapter > 1:
            all_chapters = [c for c in all_chapters if c >= start_chapter]
        if end_chapter:
            all_chapters = [c for c in all_chapters if c <= end_chapter]

        book_name = BOOKS.get(book_id, f"Book {book_id}")
        print(f"\n{'='*50}")
        print(f"Processing {book_name} ({len(all_chapters)} chapters)")
        print(f"{'='*50}")

        total_generated = 0
        for chapter in all_chapters:
            total_generated += self.process_chapter(book_id, chapter)

        print(f"\n{'='*50}")
        print(f"Completed {book_name}: {total_generated} total cross-ref explanations")
        return total_generated


def main():
    parser = argparse.ArgumentParser(description="Generate cross-reference explanations")
    parser.add_argument("--book", required=True, help="Book name (e.g., john, romans)")
    parser.add_argument("--chapter", type=int, help="Specific chapter to process")
    parser.add_argument("--start-chapter", type=int, help="Start from this chapter (use with --all to resume)")
    parser.add_argument("--end-chapter", type=int, help="End at this chapter (use with --all for partial runs)")
    parser.add_argument("--all", action="store_true", help="Process entire book")
    parser.add_argument("--dry-run", action="store_true", help="Test mode (no API calls)")
    parser.add_argument("--output-sql", type=str, help="Output SQL file instead of direct DB insert")

    args = parser.parse_args()

    # Find book ID
    book_key = args.book.lower().replace(" ", "")
    book_id = BOOK_NAME_TO_ID.get(book_key)
    if not book_id:
        print(f"Error: Unknown book '{args.book}'")
        print(f"Available: {', '.join(sorted(BOOK_NAME_TO_ID.keys()))}")
        sys.exit(1)

    # Find BibleData.sqlite
    script_dir = Path(__file__).parent
    bible_db_path = script_dir.parent.parent / "BibleStudy" / "Resources" / "BibleData.sqlite"
    if not bible_db_path.exists():
        print(f"Error: BibleData.sqlite not found at {bible_db_path}")
        sys.exit(1)

    # Initialize generator
    generator = CrossRefGenerator(bible_db_path, dry_run=args.dry_run, output_sql=args.output_sql)

    try:
        if args.all:
            # Support --start-chapter and --end-chapter for resuming/partial runs
            start_ch = args.start_chapter if args.start_chapter else 1
            end_ch = args.end_chapter  # None means all remaining chapters
            generator.process_book(book_id, start_chapter=start_ch, end_chapter=end_ch)
        elif args.chapter:
            generator.process_chapter(book_id, args.chapter)
        else:
            print("Error: Specify --chapter N or --all")
            sys.exit(1)
    finally:
        generator.close()


if __name__ == "__main__":
    main()
