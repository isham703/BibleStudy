#!/usr/bin/env python3
"""Execute all Matthew batch files to Supabase using REST API."""
import os
import sys
import time
import urllib.request
import urllib.error
import json
from pathlib import Path

# Supabase credentials
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://prgvybhpdrcbomoilrsy.supabase.co")
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

if not SERVICE_KEY:
    print("ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set")
    sys.exit(1)

def execute_sql(sql: str) -> bool:
    """Execute SQL via Supabase REST API."""
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    data = json.dumps({"query": sql}).encode('utf-8')

    req = urllib.request.Request(url, data=data, headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            return response.status == 200 or response.status == 204
    except urllib.error.HTTPError as e:
        # Try direct PostgreSQL endpoint instead
        pass

    # Fallback: use the sql endpoint directly (requires service role)
    url = f"{SUPABASE_URL}/rest/v1/"
    # For INSERT statements, we can't use RPC, so just return success for well-formed SQL
    # The MCP tool approach is more reliable
    return False

def main():
    # Get list of batch files
    batch_dir = Path(__file__).parent
    batch_files = sorted(batch_dir.glob('matthew_batch_*.sql'))
    print(f"Found {len(batch_files)} batch files")

    # Start from batch 11 (batches 1-10 already done via MCP)
    start_batch = int(sys.argv[1]) if len(sys.argv) > 1 else 11

    executed = 0
    failed = 0
    failed_batches = []

    for batch_file in batch_files:
        batch_num = int(batch_file.stem.split('_')[-1])
        if batch_num < start_batch:
            continue

        sql = batch_file.read_text()

        # For now, just print the batch numbers that need to be executed
        # The actual execution will be done via MCP tools
        print(f"Batch {batch_num:03d}: {batch_file.name}")
        executed += 1

        if executed >= 10:  # Process in groups of 10
            break

    print(f"\nProcessed {executed} batches starting from {start_batch}")
    print(f"Next batch to process: {start_batch + executed}")

if __name__ == "__main__":
    main()
