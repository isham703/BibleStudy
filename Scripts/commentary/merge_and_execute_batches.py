#!/usr/bin/env python3
"""Merge batch files and create combined SQL for efficient execution."""

import re
from pathlib import Path

BATCH_DIR = Path(__file__).parent / "crossref_batches"
OUTPUT_DIR = Path(__file__).parent / "crossref_batches"

def extract_values(sql_content: str) -> list[str]:
    """Extract individual VALUE rows from an INSERT statement."""
    match = re.search(r'VALUES\s*\n?(.*?)\s*ON CONFLICT', sql_content, re.DOTALL)
    if not match:
        return []

    values_section = match.group(1).strip()
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
            row = current_row.strip()
            if row.endswith(','):
                row = row[:-1]
            if row.startswith('(') and row.endswith(')'):
                rows.append(row)
            current_row = ""

    return rows

def create_combined_sql(rows: list[str]) -> str:
    """Create a complete INSERT statement for combined rows."""
    columns = "(source_book_id, source_chapter, source_verse, target_book_id, target_chapter, target_verse_start, target_verse_end, anchor_phrase, title, content, connection_type, weight, confidence, prompt_version, model)"

    sql = f"INSERT INTO crossref_explanations {columns}\nVALUES\n"
    sql += ",\n".join(rows)
    sql += "\nON CONFLICT (source_book_id, source_chapter, source_verse, target_book_id, target_chapter, target_verse_start, target_verse_end, connection_type) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, anchor_phrase = EXCLUDED.anchor_phrase, weight = EXCLUDED.weight, confidence = EXCLUDED.confidence, updated_at = now();"

    return sql

def main():
    # Get all acts_batch files
    batch_files = sorted(BATCH_DIR.glob("acts_batch_*.sql"))
    print(f"Found {len(batch_files)} batch files")

    # Merge batches into larger chunks (5 batches = ~150 rows each)
    MERGE_SIZE = 5
    all_rows = []

    for batch_file in batch_files:
        rows = extract_values(batch_file.read_text())
        all_rows.extend(rows)

    print(f"Total rows: {len(all_rows)}")

    # Create merged batch files
    merged_count = 0
    for i in range(0, len(all_rows), MERGE_SIZE * 30):
        chunk = all_rows[i:i + MERGE_SIZE * 30]
        if not chunk:
            break

        merged_count += 1
        sql = create_combined_sql(chunk)
        output_file = OUTPUT_DIR / f"acts_merged_{merged_count:03d}.sql"
        output_file.write_text(sql)
        print(f"  Created {output_file.name} with {len(chunk)} rows")

    print(f"\nCreated {merged_count} merged files (~{MERGE_SIZE * 30} rows each)")

if __name__ == "__main__":
    main()
