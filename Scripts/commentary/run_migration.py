#!/usr/bin/env python3
"""
Run the Supabase migration from generated SQL batch files.

This script reads the SQL batch files and executes them against Supabase
using direct PostgreSQL connection (psycopg2).

Usage:
    # Set DATABASE_URL from Supabase Dashboard > Settings > Database > Connection string
    export DATABASE_URL="postgresql://postgres.xxx:password@aws-0-region.pooler.supabase.com:6543/postgres"

    # Run all batches:
    python run_migration.py

    # Run specific batch range:
    python run_migration.py --start 1 --end 100

    # Verify current count:
    python run_migration.py --verify
"""

import argparse
import os
import sys
import time
from pathlib import Path

try:
    import psycopg2
except ImportError:
    print("Error: psycopg2 package not installed.")
    print("Run: pip install psycopg2-binary")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).parent
BATCH_DIR = SCRIPT_DIR / "migration_batches"


def get_connection():
    """Get PostgreSQL connection from DATABASE_URL."""
    database_url = os.environ.get("DATABASE_URL")

    if not database_url:
        print("Error: Set DATABASE_URL environment variable")
        print()
        print("Get this from: Supabase Dashboard > Settings > Database > Connection string")
        print("Use the 'URI' format, e.g.:")
        print("  postgresql://postgres.xxx:password@aws-0-region.pooler.supabase.com:6543/postgres")
        sys.exit(1)

    try:
        conn = psycopg2.connect(database_url)
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)


def verify_count(conn):
    """Check current row count in bible_insights."""
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM bible_insights;")
            count = cur.fetchone()[0]
            print(f"Current row count: {count}")
            return count
    except Exception as e:
        print(f"Error checking count: {e}")
        return 0


def execute_batch(conn, batch_file: Path) -> bool:
    """Execute a single batch file."""
    try:
        sql = batch_file.read_text()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        print(f"  Error: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Run migration batches")
    parser.add_argument("--start", type=int, default=1, help="Starting batch number")
    parser.add_argument("--end", type=int, help="Ending batch number")
    parser.add_argument("--verify", action="store_true", help="Only verify current count")

    args = parser.parse_args()

    conn = get_connection()

    if args.verify:
        verify_count(conn)
        conn.close()
        return

    # Get all batch files
    if not BATCH_DIR.exists():
        print(f"Error: Batch directory not found: {BATCH_DIR}")
        print("Run: python generate_migration_sql.py --nt-only first")
        conn.close()
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

    initial_count = verify_count(conn)

    success = 0
    failed = 0
    start_time = time.time()

    for i, batch_file in enumerate(batch_files, start=args.start):
        print(f"Executing batch {i}/{total_batches}...", end=" ", flush=True)

        if execute_batch(conn, batch_file):
            success += 1
            print("OK")
        else:
            failed += 1
            print("FAILED")

    elapsed = time.time() - start_time
    final_count = verify_count(conn)

    conn.close()

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
