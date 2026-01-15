#!/usr/bin/env python3
"""
Generate SQL batches for migrating insights to Supabase.

Outputs SQL files that can be executed via MCP or psql.

Usage:
    python generate_migration_sql.py --output-dir ./migration_batches
    python generate_migration_sql.py --book 43  # John only
    python generate_migration_sql.py --nt-only  # New Testament only (books 40-66)
"""

import argparse
import json
import os
import sqlite3
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
COMMENTARY_DB_PATH = PROJECT_ROOT / "BibleStudy" / "Resources" / "CommentaryData.sqlite"

# Batch size (rows per SQL file)
# Use small batches for MCP execution (50), larger for direct psql (500)
BATCH_SIZE = 50


def escape_sql(text: str) -> str:
    """Escape text for SQL insertion."""
    if text is None:
        return ""
    # Escape single quotes by doubling them
    return text.replace("'", "''")


def generate_values_clause(row: tuple) -> str:
    """Generate a VALUES clause for a single row."""
    (
        book_id, chapter, verse_start, verse_end,
        segment_text, segment_start, segment_end,
        insight_type, title, content, icon,
        sources_raw, prompt_version, model_version,
        quality_tier, is_interpretive
    ) = row

    # Escape text fields
    segment_text = escape_sql(segment_text)
    title = escape_sql(title)
    content = escape_sql(content)

    # Parse and format sources
    try:
        sources = json.loads(sources_raw) if sources_raw else None
    except json.JSONDecodeError:
        sources = None

    if sources:
        sources_sql = "'" + escape_sql(json.dumps(sources)) + "'::jsonb"
    else:
        sources_sql = "NULL"

    # Format other fields
    prompt_v = escape_sql(prompt_version or "")
    model = escape_sql(model_version or "")
    quality = quality_tier or "standard"
    is_interp = "true" if is_interpretive else "false"

    return f"({book_id}, {chapter}, {verse_start}, {verse_end}, 'kjv', '{segment_text}', {segment_start}, {segment_end}, '{insight_type}', '{title}', '{content}', '{icon}', {sources_sql}, '{quality}', {is_interp}, '{prompt_v}', '{model}')"


def generate_insert_statement(values) -> str:
    """Generate a complete INSERT statement."""
    columns = "(book_id, chapter, verse_start, verse_end, translation_id, segment_text, segment_start_char, segment_end_char, insight_type, title, content, icon, sources, quality_tier, is_interpretive, prompt_version, model)"

    values_str = ",\n".join(values)
    return f"INSERT INTO bible_insights {columns}\nVALUES\n{values_str};"


def main():
    parser = argparse.ArgumentParser(description="Generate migration SQL batches")
    parser.add_argument("--output-dir", type=str, default="./migration_batches",
                        help="Directory to write SQL files")
    parser.add_argument("--book", type=int, help="Migrate specific book only")
    parser.add_argument("--nt-only", action="store_true",
                        help="Migrate New Testament only (books 40-66)")
    parser.add_argument("--print-stats", action="store_true",
                        help="Print statistics only, don't generate files")

    args = parser.parse_args()

    if not COMMENTARY_DB_PATH.exists():
        print(f"Error: Commentary database not found: {COMMENTARY_DB_PATH}")
        return

    conn = sqlite3.connect(COMMENTARY_DB_PATH)

    # Build WHERE clause
    where_clause = ""
    if args.book:
        where_clause = f"WHERE book_id = {args.book}"
    elif args.nt_only:
        where_clause = "WHERE book_id >= 40 AND book_id <= 66"

    # Get total count
    count_query = f"SELECT COUNT(*) FROM commentary_insights {where_clause}"
    total = conn.execute(count_query).fetchone()[0]

    print(f"Database: {COMMENTARY_DB_PATH}")
    print(f"Total insights to migrate: {total}")

    if args.nt_only:
        print("Filtering: New Testament only (books 40-66)")
    elif args.book:
        print(f"Filtering: Book {args.book} only")

    if args.print_stats:
        # Print per-book stats
        stats_query = f"""
            SELECT book_id, COUNT(*) as count
            FROM commentary_insights
            {where_clause}
            GROUP BY book_id
            ORDER BY book_id
        """
        print("\nPer-book counts:")
        for row in conn.execute(stats_query):
            print(f"  Book {row[0]}: {row[1]} insights")
        conn.close()
        return

    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Fetch and batch
    query = f"""
        SELECT book_id, chapter, verse_start, verse_end,
               segment_text, segment_start_char, segment_end_char,
               insight_type, title, content, icon, sources,
               prompt_version, model_version, quality_tier, is_interpretive
        FROM commentary_insights
        {where_clause}
        ORDER BY book_id, chapter, verse_start
    """

    cursor = conn.execute(query)
    batch_num = 0
    values = []
    total_written = 0

    for row in cursor:
        values.append(generate_values_clause(row))

        if len(values) >= BATCH_SIZE:
            batch_num += 1
            sql = generate_insert_statement(values)
            output_file = output_dir / f"batch_{batch_num:04d}.sql"
            output_file.write_text(sql)
            total_written += len(values)
            print(f"  Written batch {batch_num}: {len(values)} rows ({total_written}/{total})")
            values = []

    # Write remaining
    if values:
        batch_num += 1
        sql = generate_insert_statement(values)
        output_file = output_dir / f"batch_{batch_num:04d}.sql"
        output_file.write_text(sql)
        total_written += len(values)
        print(f"  Written batch {batch_num}: {len(values)} rows ({total_written}/{total})")

    print(f"\nGenerated {batch_num} SQL files in {output_dir}")
    print(f"Total rows: {total_written}")

    conn.close()


if __name__ == "__main__":
    main()
