#!/usr/bin/env python3
"""Fix curly apostrophes in all Matthew batch files."""
import re
from pathlib import Path

batch_files = sorted(Path('.').glob('matthew_batch_*.sql'))
fixed_count = 0

for f in batch_files:
    content = f.read_text()
    # Replace curly apostrophes with straight ones
    new_content = content.replace('\u2019', "'")  # Right single quote
    new_content = new_content.replace('\u2018', "'")  # Left single quote
    if new_content != content:
        f.write_text(new_content)
        fixed_count += 1
        print(f'Fixed: {f.name}')

print(f'\nTotal files fixed: {fixed_count} out of {len(batch_files)}')
