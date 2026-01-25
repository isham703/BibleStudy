#!/usr/bin/env python3
"""Split SQL files and output for execution."""
import re
import sys
from pathlib import Path

def split_sql(content: str, batch_size: int = 30):
    """Split INSERT statement into smaller batches."""
    # Extract the header (INSERT INTO ... VALUES)
    match = re.match(r'(INSERT INTO [^V]+VALUES\s*)\n(.+)\nON CONFLICT.*', content, re.DOTALL)
    if not match:
        return [content]
    
    header = match.group(1)
    values_str = match.group(2)
    conflict_clause = content[content.rfind('ON CONFLICT'):]
    
    # Split values - each row is a complete tuple
    # More robust: split on ),\n(
    rows = re.split(r'\),\s*\n\(', values_str)
    
    # Clean up first and last rows
    if rows:
        rows[0] = rows[0].lstrip('(')
        rows[-1] = rows[-1].rstrip(')')
    
    batches = []
    for i in range(0, len(rows), batch_size):
        batch_rows = rows[i:i+batch_size]
        values = ',\n'.join(f'({row})' for row in batch_rows)
        sql = f"{header}\n{values}\n{conflict_clause}"
        batches.append(sql)
    
    return batches

# Process each file
for sql_file in sorted(Path('.').glob('john_*.sql')):
    if 'batch' in sql_file.name:
        continue
    print(f"Processing {sql_file.name}...")
    content = sql_file.read_text()
    batches = split_sql(content)
    print(f"  Split into {len(batches)} batches")
    
    # Write batch files
    for i, batch in enumerate(batches, 1):
        batch_file = sql_file.with_name(f"{sql_file.stem}_batch_{i:02d}.sql")
        batch_file.write_text(batch)
        print(f"  Wrote {batch_file.name}")
