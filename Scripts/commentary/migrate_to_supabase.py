#!/usr/bin/env python3
"""
Migrate CommentaryData.sqlite to Supabase

Reads all insights from the local SQLite database and uploads them
to the Supabase bible_insights table.

Usage:
    # First, set your Supabase credentials:
    export SUPABASE_URL="https://prgvybhpdrcbomoilrsy.supabase.co"
    export SUPABASE_SERVICE_KEY="your-service-role-key"

    # Run migration:
    python migrate_to_supabase.py

    # Dry run (preview without uploading):
    python migrate_to_supabase.py --dry-run

    # Resume from specific offset:
    python migrate_to_supabase.py --offset 10000

    # Migrate specific book only:
    python migrate_to_supabase.py --book 43  # John

Requirements:
    pip install supabase
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
    from supabase import create_client, Client
    SUPABASE_AVAILABLE = True
except ImportError:
    SUPABASE_AVAILABLE = False
    Client = None  # Type stub for dry-run mode

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
COMMENTARY_DB_PATH = PROJECT_ROOT / "BibleStudy" / "Resources" / "CommentaryData.sqlite"

# Batch size for uploads
BATCH_SIZE = 500

# Valid insight types (must match Supabase enum)
VALID_INSIGHT_TYPES = {"greek", "theology", "question", "connection"}

# Quality tiers
VALID_QUALITY_TIERS = {"standard", "premium", "experimental"}


def get_supabase_client():
    """Create and return Supabase client."""
    if not SUPABASE_AVAILABLE:
        print("Error: supabase package not installed.")
        print("Run: pip install supabase")
        sys.exit(1)

    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_KEY")

    if not url or not key:
        print("Error: Missing Supabase credentials.")
        print("Set SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables.")
        print()
        print("You can find these in your Supabase Dashboard > Settings > API")
        print("Use the service_role key (not anon) for migration.")
        sys.exit(1)

    return create_client(url, key)


def transform_insight(row: tuple) -> Optional[dict]:
    """Transform SQLite row to Supabase schema format."""
    # Unpack SQLite row
    (
        old_id,
        book_id,
        chapter,
        verse_start,
        verse_end,
        segment_text,
        segment_start_char,
        segment_end_char,
        insight_type,
        title,
        content,
        icon,
        sources_json,
        content_version,
        prompt_version,
        model_version,
        created_at,
        quality_tier,
        is_interpretive
    ) = row

    # Validate insight_type
    if insight_type not in VALID_INSIGHT_TYPES:
        print(f"  Warning: Invalid insight_type '{insight_type}' for {old_id}, skipping")
        return None

    # Validate quality_tier
    if quality_tier not in VALID_QUALITY_TIERS:
        quality_tier = "standard"

    # Parse sources JSON
    try:
        sources = json.loads(sources_json) if sources_json else None
    except json.JSONDecodeError:
        sources = None

    # Transform to Supabase schema
    return {
        "book_id": book_id,
        "chapter": chapter,
        "verse_start": verse_start,
        "verse_end": verse_end,
        "translation_id": "kjv",  # All existing insights are KJV-based
        "segment_text": segment_text,
        "segment_start_char": segment_start_char,
        "segment_end_char": segment_end_char,
        "insight_type": insight_type,
        "title": title,
        "content": content,
        "icon": icon,
        "sources": sources,
        "quality_tier": quality_tier,
        "is_interpretive": bool(is_interpretive),
        "prompt_version": prompt_version,
        "model": model_version,
        # created_at will be set by Supabase default
        # updated_at will be set by Supabase default
    }


def count_insights(conn: sqlite3.Connection, book_id: Optional[int] = None) -> int:
    """Count total insights to migrate."""
    if book_id:
        cursor = conn.execute(
            "SELECT COUNT(*) FROM commentary_insights WHERE book_id = ?",
            (book_id,)
        )
    else:
        cursor = conn.execute("SELECT COUNT(*) FROM commentary_insights")
    return cursor.fetchone()[0]


def fetch_insights(
    conn: sqlite3.Connection,
    offset: int = 0,
    limit: int = BATCH_SIZE,
    book_id: Optional[int] = None
) -> list[tuple]:
    """Fetch a batch of insights from SQLite."""
    query = """
        SELECT
            id, book_id, chapter, verse_start, verse_end,
            segment_text, segment_start_char, segment_end_char,
            insight_type, title, content, icon, sources,
            content_version, prompt_version, model_version,
            created_at, quality_tier, is_interpretive
        FROM commentary_insights
    """

    if book_id:
        query += f" WHERE book_id = {book_id}"

    query += f" ORDER BY book_id, chapter, verse_start LIMIT {limit} OFFSET {offset}"

    cursor = conn.execute(query)
    return cursor.fetchall()


def upload_batch(supabase: Client, batch: list[dict], dry_run: bool = False) -> int:
    """Upload a batch of insights to Supabase."""
    if not batch:
        return 0

    if dry_run:
        print(f"  [DRY RUN] Would upload {len(batch)} insights")
        return len(batch)

    try:
        result = supabase.table("bible_insights").insert(batch).execute()
        return len(result.data) if result.data else 0
    except Exception as e:
        print(f"  Error uploading batch: {e}")
        # Try uploading one by one to identify problematic records
        success_count = 0
        for insight in batch:
            try:
                supabase.table("bible_insights").insert(insight).execute()
                success_count += 1
            except Exception as e2:
                print(f"    Failed: {insight.get('book_id')}:{insight.get('chapter')}:{insight.get('verse_start')} - {e2}")
        return success_count


def verify_migration(supabase: Client, expected_count: int) -> bool:
    """Verify the migration completed successfully."""
    try:
        result = supabase.table("bible_insights").select("id", count="exact").execute()
        actual_count = result.count

        print(f"\nVerification:")
        print(f"  Expected: {expected_count}")
        print(f"  Actual:   {actual_count}")

        if actual_count >= expected_count:
            print("  Status: SUCCESS")
            return True
        else:
            print(f"  Status: INCOMPLETE ({expected_count - actual_count} missing)")
            return False
    except Exception as e:
        print(f"  Verification failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Migrate insights to Supabase")
    parser.add_argument("--dry-run", action="store_true", help="Preview without uploading")
    parser.add_argument("--offset", type=int, default=0, help="Start from offset (for resume)")
    parser.add_argument("--book", type=int, help="Migrate specific book only")
    parser.add_argument("--verify-only", action="store_true", help="Only verify existing migration")

    args = parser.parse_args()

    # Check database exists
    if not COMMENTARY_DB_PATH.exists():
        print(f"Error: Commentary database not found: {COMMENTARY_DB_PATH}")
        sys.exit(1)

    # Connect to SQLite
    conn = sqlite3.connect(COMMENTARY_DB_PATH)
    total_count = count_insights(conn, args.book)

    print(f"Commentary Database: {COMMENTARY_DB_PATH}")
    print(f"Total insights to migrate: {total_count}")

    if args.book:
        print(f"Filtering to book_id: {args.book}")

    if args.offset > 0:
        print(f"Resuming from offset: {args.offset}")

    print()

    # Get Supabase client
    if not args.dry_run:
        supabase = get_supabase_client()

        if args.verify_only:
            verify_migration(supabase, total_count)
            conn.close()
            return
    else:
        supabase = None
        print("[DRY RUN MODE - No data will be uploaded]\n")

    # Migration loop
    offset = args.offset
    uploaded = 0
    skipped = 0
    start_time = time.time()

    while offset < total_count:
        rows = fetch_insights(conn, offset, BATCH_SIZE, args.book)
        if not rows:
            break

        # Transform rows
        batch = []
        for row in rows:
            transformed = transform_insight(row)
            if transformed:
                batch.append(transformed)
            else:
                skipped += 1

        # Upload batch
        if batch:
            count = upload_batch(supabase, batch, args.dry_run)
            uploaded += count

        # Progress
        progress = min(100, (offset + len(rows)) / total_count * 100)
        elapsed = time.time() - start_time
        rate = uploaded / elapsed if elapsed > 0 else 0
        eta = (total_count - offset - len(rows)) / rate if rate > 0 else 0

        print(f"  Progress: {progress:.1f}% ({offset + len(rows)}/{total_count}) | "
              f"Uploaded: {uploaded} | Skipped: {skipped} | "
              f"Rate: {rate:.0f}/s | ETA: {eta:.0f}s")

        offset += len(rows)

    # Summary
    elapsed = time.time() - start_time
    print(f"\n{'='*50}")
    print(f"Migration {'(DRY RUN) ' if args.dry_run else ''}Complete!")
    print(f"  Total processed: {offset}")
    print(f"  Uploaded: {uploaded}")
    print(f"  Skipped: {skipped}")
    print(f"  Time: {elapsed:.1f}s")

    # Verify
    if not args.dry_run and supabase:
        verify_migration(supabase, uploaded)

    conn.close()


if __name__ == "__main__":
    main()
