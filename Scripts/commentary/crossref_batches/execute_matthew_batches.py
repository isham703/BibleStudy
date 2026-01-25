#!/usr/bin/env python3
"""Execute Matthew batch files to Supabase using psycopg2 or httpx."""
import os
import sys
import time
from pathlib import Path

# Try to use supabase client
try:
    from supabase import create_client
    import httpx
except ImportError:
    print("Installing supabase client...")
    os.system("pip3 install supabase httpx")
    from supabase import create_client
    import httpx

# Supabase credentials from env or defaults
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://prgvybhpdrcbomoilrsy.supabase.co")

# Get service role key from user or env
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

if not SERVICE_KEY:
    print("ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set")
    print("Please set it before running this script")
    sys.exit(1)

# Initialize client
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

# Get list of batch files
batch_files = sorted(Path('.').glob('matthew_batch_*.sql'))
print(f"Found {len(batch_files)} batch files to execute")

# Skip first batch (already executed)
start_batch = 2  # Start from batch 002

executed = 0
failed = 0
for batch_file in batch_files:
    batch_num = int(batch_file.stem.split('_')[-1])
    if batch_num < start_batch:
        print(f"Skipping {batch_file.name} (already done)")
        continue
        
    sql = batch_file.read_text()
    try:
        # Execute using REST API
        result = supabase.rpc('exec_sql', {'query': sql}).execute()
        executed += 1
        print(f"✓ {batch_file.name} executed ({executed}/{len(batch_files)-start_batch+1})")
    except Exception as e:
        # Try direct postgrest execution
        try:
            # Use raw SQL execution endpoint
            headers = {
                "apikey": SERVICE_KEY,
                "Authorization": f"Bearer {SERVICE_KEY}",
                "Content-Type": "application/json",
                "Prefer": "return=minimal"
            }
            # For INSERT we need to use the table endpoint
            # This won't work for raw SQL, so let's try a different approach
            print(f"✗ {batch_file.name} failed: {str(e)[:100]}")
            failed += 1
        except Exception as e2:
            print(f"✗ {batch_file.name} double-failed: {str(e2)[:100]}")
            failed += 1
    
    # Small delay to avoid rate limiting
    time.sleep(0.1)

print(f"\nDone! Executed: {executed}, Failed: {failed}")
