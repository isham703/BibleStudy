#!/usr/bin/env python3
"""Execute crossref SQL files against Supabase using psycopg2."""

import os
import sys
import subprocess
from pathlib import Path

try:
    import psycopg2
except ImportError:
    print("Installing psycopg2-binary...")
    subprocess.run([sys.executable, "-m", "pip", "install", "psycopg2-binary"], check=True)
    import psycopg2

def execute_sql_file(file_path: str, database_url: str):
    """Execute a SQL file against the database."""
    print(f"Executing {file_path}...")

    with open(file_path, 'r') as f:
        sql = f.read()

    conn = psycopg2.connect(database_url)
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  Success!")
        return True
    except Exception as e:
        conn.rollback()
        print(f"  Error: {e}")
        return False
    finally:
        conn.close()

def main():
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("Error: Set DATABASE_URL environment variable")
        print("Format: postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres")
        print("\nFind this in Supabase Dashboard > Project Settings > Database > Connection string > URI (Transaction pooler)")
        sys.exit(1)

    batch_dir = Path(__file__).parent / "crossref_batches"

    if len(sys.argv) >= 2:
        # Execute specified files
        for sql_file in sys.argv[1:]:
            execute_sql_file(sql_file, database_url)
    else:
        # Execute all acts_batch_*.sql files
        batch_files = sorted(batch_dir.glob("acts_batch_*.sql"))
        if not batch_files:
            print(f"No acts_batch_*.sql files found in {batch_dir}")
            sys.exit(1)

        print(f"Found {len(batch_files)} batch files to execute")
        success = 0
        failed = 0
        for i, sql_file in enumerate(batch_files, 1):
            print(f"[{i}/{len(batch_files)}] ", end="")
            if execute_sql_file(str(sql_file), database_url):
                success += 1
            else:
                failed += 1
        print(f"\nDone! {success} succeeded, {failed} failed")

if __name__ == "__main__":
    main()
