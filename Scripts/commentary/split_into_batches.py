#!/usr/bin/env python3
"""
Split large SQL files into 30-row batches for Supabase execution.

Usage:
    python3 split_into_batches.py acts

This will:
1. Find all acts_XX.sql files in crossref_batches/
2. Combine them and split into acts_batch_XXX.sql files (30 rows each)
"""

import re
import sys
from pathlib import Path

BATCH_SIZE = 30

def extract_values(sql_content: str) -> list[str]:
    """Extract individual VALUE rows from an INSERT statement."""
    # Find the VALUES section
    match = re.search(r'VALUES\s*\n?(.*?)(?:\nON CONFLICT|$)', sql_content, re.DOTALL)
    if not match:
        return []

    values_section = match.group(1).strip()

    # Split by "),\n(" pattern to get individual rows
    # Handle the opening ( and closing ) of VALUES
    rows = []
    current_row = ""
    paren_depth = 0

    for char in values_section:
        if char == '(':
            paren_depth += 1
        elif char == ')':
            paren_depth -= 1

        current_row += char

        if paren_depth == 0 and current_row.strip():
            # End of a row
            row = current_row.strip()
            if row.endswith(','):
                row = row[:-1]
            if row.startswith('(') and row.endswith(')'):
                rows.append(row)
            current_row = ""

    return rows

def create_batch_sql(rows: list[str], batch_num: int) -> str:
    """Create a complete INSERT statement for a batch."""
    columns = "(source_book_id, source_chapter, source_verse, target_book_id, target_chapter, target_verse_start, target_verse_end, anchor_phrase, title, content, connection_type, weight, confidence, prompt_version, model)"

    sql = f"INSERT INTO crossref_explanations {columns}\nVALUES\n"
    sql += ",\n".join(rows)
    sql += "\nON CONFLICT (source_book_id, source_chapter, source_verse, target_book_id, target_chapter, target_verse_start, target_verse_end, connection_type) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, anchor_phrase = EXCLUDED.anchor_phrase, weight = EXCLUDED.weight, confidence = EXCLUDED.confidence, updated_at = now();"

    return sql

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 split_into_batches.py <book_name>")
        print("Example: python3 split_into_batches.py acts")
        sys.exit(1)

    book_name = sys.argv[1].lower()
    batch_dir = Path(__file__).parent / "crossref_batches"

    # Find all chapter files for this book
    chapter_files = sorted(batch_dir.glob(f"{book_name}_[0-9][0-9].sql"))

    if not chapter_files:
        print(f"No files found matching {book_name}_XX.sql in {batch_dir}")
        sys.exit(1)

    print(f"Found {len(chapter_files)} chapter files for {book_name}")

    # Collect all rows from all chapters
    all_rows = []
    for chapter_file in chapter_files:
        print(f"  Reading {chapter_file.name}...")
        content = chapter_file.read_text()
        rows = extract_values(content)
        print(f"    -> {len(rows)} rows")
        all_rows.extend(rows)

    print(f"\nTotal rows: {len(all_rows)}")

    # Split into batches
    num_batches = (len(all_rows) + BATCH_SIZE - 1) // BATCH_SIZE
    print(f"Creating {num_batches} batch files ({BATCH_SIZE} rows each)...\n")

    for i in range(num_batches):
        start_idx = i * BATCH_SIZE
        end_idx = min(start_idx + BATCH_SIZE, len(all_rows))
        batch_rows = all_rows[start_idx:end_idx]

        batch_num = i + 1
        batch_file = batch_dir / f"{book_name}_batch_{batch_num:03d}.sql"

        sql = create_batch_sql(batch_rows, batch_num)
        batch_file.write_text(sql)

        print(f"  {batch_file.name}: {len(batch_rows)} rows")

    print(f"\nDone! Created {num_batches} batch files.")
    print(f"Next: Execute batches using MCP Supabase tools")

if __name__ == "__main__":
    main()
