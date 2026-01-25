#!/usr/bin/env python3
"""
Combine batch files into larger chunks for more efficient MCP migration.
Creates combined SQL files that can be executed in fewer calls.
"""

from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
BATCH_DIR = SCRIPT_DIR / "migration_batches"
COMBINED_DIR = SCRIPT_DIR / "combined_batches"

# Combine 10 batches into 1 file (reduces 651 calls to ~66)
BATCHES_PER_COMBINED = 10


def main():
    COMBINED_DIR.mkdir(exist_ok=True)

    batch_files = sorted(BATCH_DIR.glob("batch_*.sql"))
    print(f"Found {len(batch_files)} batch files")

    combined_num = 0
    current_sql = []

    for i, batch_file in enumerate(batch_files):
        sql = batch_file.read_text()
        # Remove trailing semicolon and add back properly
        sql = sql.strip().rstrip(';')
        current_sql.append(sql + ";")

        if (i + 1) % BATCHES_PER_COMBINED == 0 or i == len(batch_files) - 1:
            combined_num += 1
            combined_file = COMBINED_DIR / f"combined_{combined_num:04d}.sql"
            combined_file.write_text("\n\n".join(current_sql))
            print(f"Created {combined_file.name} ({len(current_sql)} batches)")
            current_sql = []

    print(f"\nCreated {combined_num} combined files in {COMBINED_DIR}")


if __name__ == "__main__":
    main()
