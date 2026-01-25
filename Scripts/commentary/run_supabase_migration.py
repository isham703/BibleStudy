#!/usr/bin/env python3
"""
Run the Supabase migration using the supabase-py library.

This script reads the SQL batch files and executes them against Supabase
using the Supabase Python client (which uses the REST API).

Usage:
    # Set your Supabase credentials:
    export SUPABASE_URL="https://prgvybhpdrcbomoilrsy.supabase.co"
    export SUPABASE_KEY="your-service-role-key"  # Get from Supabase Dashboard > Settings > API

    # Run all batches:
    python run_supabase_migration.py

    # Run specific batch range:
    python run_supabase_migration.py --start 4 --end 651

    # Verify current count:
    python run_supabase_migration.py --verify
"""

import argparse
import os
import sys
import time
from pathlib import Path

try:
    from supabase import create_client, Client
except ImportError:
    print("Error: supabase package not installed.")
    print("Run: pip install supabase")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).parent
BATCH_DIR = SCRIPT_DIR / "migration_batches"


def get_supabase_client() -> Client:
    """Get Supabase client from environment variables."""
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_KEY")

    if not url or not key:
        print("Error: Set SUPABASE_URL and SUPABASE_KEY environment variables")
        print()
        print("Get these from: Supabase Dashboard > Settings > API")
        print("  SUPABASE_URL: Project URL")
        print("  SUPABASE_KEY: service_role key (NOT anon key)")
        sys.exit(1)

    return create_client(url, key)


def verify_count(supabase: Client) -> int:
    """Check current row count in bible_insights."""
    try:
        result = supabase.table("bible_insights").select("id", count="exact").execute()
        count = result.count or 0
        print(f"Current row count: {count}")
        return count
    except Exception as e:
        print(f"Error checking count: {e}")
        return 0


def execute_batch(supabase: Client, batch_file: Path) -> bool:
    """Execute a single batch file by parsing INSERT and using upsert."""
    try:
        sql = batch_file.read_text()

        # Parse the SQL to extract rows
        # The batch files have format:
        # INSERT INTO bible_insights (...) VALUES (...), (...), ...;

        # Extract column names from the INSERT statement
        start = sql.find("(") + 1
        end = sql.find(")")
        columns_str = sql[start:end]
        columns = [c.strip() for c in columns_str.split(",")]

        # Extract VALUES section
        values_start = sql.find("VALUES") + 6
        values_section = sql[values_start:].strip().rstrip(";")

        # Parse individual rows - this is tricky because values contain commas and quotes
        # We'll use the PostgreSQL direct connection instead via RPC

        # Use raw SQL execution via RPC
        result = supabase.rpc("exec_sql", {"query": sql}).execute()
        return True

    except Exception as e:
        print(f"  Error: {e}")
        # Try using psycopg2 as fallback
        return False


def main():
    parser = argparse.ArgumentParser(description="Run migration batches via Supabase")
    parser.add_argument("--start", type=int, default=1, help="Starting batch number")
    parser.add_argument("--end", type=int, help="Ending batch number")
    parser.add_argument("--verify", action="store_true", help="Only verify current count")

    args = parser.parse_args()

    supabase = get_supabase_client()

    if args.verify:
        verify_count(supabase)
        return

    # Get all batch files
    if not BATCH_DIR.exists():
        print(f"Error: Batch directory not found: {BATCH_DIR}")
        print("Run: python generate_migration_sql.py --nt-only first")
        return

    batch_files = sorted(BATCH_DIR.glob("batch_*.sql"))
    total_batches = len(batch_files)

    if args.end:
        batch_files = batch_files[args.start-1:args.end]
    else:
        batch_files = batch_files[args.start-1:]

    print(f"Found {total_batches} total batch files")
    print(f"Will execute batches {args.start} to {args.end or total_batches}")
    print()

    initial_count = verify_count(supabase)

    success = 0
    failed = 0
    start_time = time.time()

    for i, batch_file in enumerate(batch_files, start=args.start):
        print(f"Executing batch {i}/{total_batches}...", end=" ", flush=True)

        if execute_batch(supabase, batch_file):
            success += 1
            print("OK")
        else:
            failed += 1
            print("FAILED")

    elapsed = time.time() - start_time
    final_count = verify_count(supabase)

    print()
    print(f"{'='*50}")
    print(f"Migration complete!")
    print(f"  Batches executed: {success + failed}")
    print(f"  Successful: {success}")
    print(f"  Failed: {failed}")
    print(f"  Rows added: {final_count - initial_count}")
    print(f"  Time: {elapsed:.1f}s")


if __name__ == "__main__":
    main()
