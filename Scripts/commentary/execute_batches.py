#!/usr/bin/env python3
"""Execute batch SQL files against Supabase using REST API.

Usage:
    export SUPABASE_SERVICE_KEY="your-service-role-key"
    python execute_batches.py acts               # Run all Acts batches
    python execute_batches.py john               # Run all John batches
    python execute_batches.py --verify acts      # Check current counts for Acts
"""

import argparse
import glob
import os
import re
import requests
import time

# Supabase config
SUPABASE_URL = "https://prgvybhpdrcbomoilrsy.supabase.co"
# We'll use service role key for admin access
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")

BATCH_DIR = "/Users/idon/Documents/BibleStudy/Scripts/commentary/crossref_batches"

# Book ID mapping
BOOK_IDS = {"john": 43, "acts": 44}

def parse_values_from_sql(sql_content):
    """Parse INSERT VALUES from SQL content and return list of dicts."""
    # Extract the VALUES portion
    match = re.search(r'VALUES\s*(.+?)\s*ON CONFLICT', sql_content, re.DOTALL)
    if not match:
        return []

    values_str = match.group(1).strip()

    # Parse each tuple - this is a simple parser that handles quoted strings with commas
    rows = []
    current_row = []
    current_value = ""
    in_string = False
    paren_depth = 0

    i = 0
    while i < len(values_str):
        char = values_str[i]

        if char == "'" and (i == 0 or values_str[i-1] != "'"):
            in_string = not in_string
            current_value += char
        elif char == '(' and not in_string:
            paren_depth += 1
            if paren_depth == 1:
                current_row = []
                current_value = ""
            else:
                current_value += char
        elif char == ')' and not in_string:
            paren_depth -= 1
            if paren_depth == 0:
                # End of row
                if current_value.strip():
                    current_row.append(current_value.strip())
                rows.append(current_row)
                current_row = []
                current_value = ""
            else:
                current_value += char
        elif char == ',' and paren_depth == 1 and not in_string:
            # Column separator
            if current_value.strip():
                current_row.append(current_value.strip())
            current_value = ""
        else:
            current_value += char

        i += 1

    # Convert to dicts - column order matches the generated SQL files
    columns = [
        "source_book_id", "source_chapter", "source_verse",
        "target_book_id", "target_chapter", "target_verse_start", "target_verse_end",
        "anchor_phrase", "title", "content", "connection_type",
        "weight", "confidence", "prompt_version", "model"
    ]

    result = []
    for row in rows:
        if len(row) != len(columns):
            print(f"Warning: Row has {len(row)} columns, expected {len(columns)}")
            continue

        record = {}
        for col, val in zip(columns, row):
            # Clean up value
            val = val.strip()
            if val == "NULL":
                record[col] = None
            elif val.startswith("'") and val.endswith("'"):
                # String value - unescape quotes
                record[col] = val[1:-1].replace("''", "'")
            else:
                # Numeric
                try:
                    if '.' in val:
                        record[col] = float(val)
                    else:
                        record[col] = int(val)
                except ValueError:
                    record[col] = val

        result.append(record)

    return result


def insert_via_rest(records):
    """Insert records using Supabase REST API."""
    if not SERVICE_KEY:
        print("Error: SUPABASE_SERVICE_KEY not set")
        return False

    url = f"{SUPABASE_URL}/rest/v1/crossref_explanations"
    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"  # Handle conflicts via upsert
    }

    response = requests.post(url, headers=headers, json=records)

    if response.status_code not in (200, 201):
        print(f"Error {response.status_code}: {response.text}")
        return False

    return True


def verify_counts(book_name: str):
    """Check current row counts per chapter."""
    if not SERVICE_KEY:
        print("Error: SUPABASE_SERVICE_KEY not set")
        return

    book_id = BOOK_IDS.get(book_name.lower())
    if not book_id:
        print(f"Unknown book: {book_name}")
        return

    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json"
    }

    # Use direct REST query
    url = f"{SUPABASE_URL}/rest/v1/crossref_explanations?select=source_chapter&source_book_id=eq.{book_id}"
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        counts = {}
        for row in data:
            ch = row['source_chapter']
            counts[ch] = counts.get(ch, 0) + 1

        total = sum(counts.values())
        print(f"Total crossref rows for {book_name.title()}: {total}")
        for ch in sorted(counts.keys()):
            print(f"  Chapter {ch}: {counts[ch]} rows")
    else:
        print(f"Error: {response.status_code} - {response.text}")


def main():
    parser = argparse.ArgumentParser(description="Execute crossref batch files")
    parser.add_argument("book", nargs="?", default="acts", help="Book name (acts or john)")
    parser.add_argument("--verify", action="store_true", help="Only verify current count")

    args = parser.parse_args()
    book_name = args.book.lower()

    if args.verify:
        verify_counts(book_name)
        return

    # Get batch files based on book
    if book_name == "acts":
        # Acts uses acts_batch_XXX.sql format (all chapters combined)
        pattern = f"{BATCH_DIR}/acts_batch_*.sql"
        batch_files = sorted(glob.glob(pattern))
        print(f"Running all Acts batches...")
    elif book_name == "john":
        # John uses john_XX_batch_*.sql format (per-chapter batches)
        batch_files = []
        for ch in range(1, 22):
            pattern = f"{BATCH_DIR}/john_{ch:02d}_batch_*.sql"
            batch_files.extend(sorted(glob.glob(pattern)))
        print(f"Running all John batches...")
    else:
        print(f"Unknown book: {book_name}")
        return

    if not batch_files:
        print(f"No batch files found in {BATCH_DIR}")
        return

    print(f"Found {len(batch_files)} batch files")
    print()

    total_inserted = 0
    failed_count = 0
    start_time = time.time()

    for i, batch_file in enumerate(batch_files):
        filename = os.path.basename(batch_file)

        with open(batch_file, 'r') as f:
            sql = f.read()

        records = parse_values_from_sql(sql)

        if records:
            if insert_via_rest(records):
                total_inserted += len(records)
                # Show progress every 10 batches
                if (i + 1) % 10 == 0:
                    print(f"  Processed {i+1}/{len(batch_files)} batches ({total_inserted} rows)")
            else:
                failed_count += 1
                print(f"  FAILED: {filename}")

        # Small delay to avoid rate limits
        time.sleep(0.05)

    elapsed = time.time() - start_time
    print()
    print(f"{'='*50}")
    print(f"Done!")
    print(f"  Total inserted: {total_inserted}")
    print(f"  Failed batches: {failed_count}")
    print(f"  Time: {elapsed:.1f}s")


if __name__ == "__main__":
    main()
