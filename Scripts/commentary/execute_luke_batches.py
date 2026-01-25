#!/usr/bin/env python3
"""Execute Luke batch files via psycopg2 directly to Supabase."""
import os
import glob
import sys

try:
    import psycopg2
except ImportError:
    print("Installing psycopg2...")
    os.system("pip3 install psycopg2-binary")
    import psycopg2

# Get database URL from environment or use default
DATABASE_URL = os.environ.get('DATABASE_URL')

if not DATABASE_URL:
    print("Error: DATABASE_URL not set")
    sys.exit(1)

# Get all Luke batch files
batch_files = sorted(glob.glob('crossref_batches/luke_batch_*.sql'))
print(f"Found {len(batch_files)} Luke batch files")

# Connect to database
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Execute each batch
successful = 0
failed = 0

for i, batch_file in enumerate(batch_files, 1):
    try:
        with open(batch_file, 'r') as f:
            sql = f.read()
        cur.execute(sql)
        conn.commit()
        successful += 1
        if i % 10 == 0:
            print(f"  Executed {i}/{len(batch_files)} batches ({successful} successful, {failed} failed)")
    except Exception as e:
        failed += 1
        print(f"  Error in {batch_file}: {e}")
        conn.rollback()

cur.close()
conn.close()

print(f"\nCompleted: {successful} successful, {failed} failed")
