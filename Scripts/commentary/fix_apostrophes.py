#!/usr/bin/env python3
"""Fix curly apostrophes in SQL batch files."""

from pathlib import Path

batch_dir = Path(__file__).parent / 'migration_batches'
fixed_count = 0
files_fixed = 0

# Unicode right single quotation mark (curly apostrophe)
CURLY_APOSTROPHE = '\u2019'

for batch_file in sorted(batch_dir.glob('batch_*.sql')):
    content = batch_file.read_text(encoding='utf-8')

    if CURLY_APOSTROPHE in content:
        # Replace curly apostrophe with two straight single quotes for PostgreSQL
        new_content = content.replace(CURLY_APOSTROPHE, "''")

        if new_content != content:
            batch_file.write_text(new_content, encoding='utf-8')
            fixed_count += content.count(CURLY_APOSTROPHE)
            files_fixed += 1

print(f'Fixed {fixed_count} curly apostrophes across {files_fixed} files')
