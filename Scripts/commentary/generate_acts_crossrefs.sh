#!/bin/bash
# Generate Acts cross-references chapter by chapter
#
# Usage:
#   export OPENAI_API_KEY="sk-..."
#   ./generate_acts_crossrefs.sh
#
# This will generate SQL files for all 28 chapters of Acts

set -e
cd "$(dirname "$0")"

if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY environment variable not set"
    echo "Usage: export OPENAI_API_KEY='sk-...' && ./generate_acts_crossrefs.sh"
    exit 1
fi

OUTPUT_DIR="crossref_batches"
mkdir -p "$OUTPUT_DIR"

echo "=== Generating Acts Cross-References ==="
echo "Output directory: $OUTPUT_DIR"
echo ""

for chapter in $(seq 1 28); do
    padded=$(printf "%02d" $chapter)
    output_file="$OUTPUT_DIR/acts_${padded}.sql"

    if [ -f "$output_file" ]; then
        echo "Chapter $chapter: Already exists, skipping"
        continue
    fi

    echo "Chapter $chapter: Generating..."
    python3 generate_crossref_insights.py --book acts --chapter $chapter --output-sql "$output_file"
    echo "Chapter $chapter: Done -> $output_file"
    echo ""
done

echo "=== All chapters complete ==="
echo ""
echo "Next step: Run the batch splitter to create 30-row batch files"
