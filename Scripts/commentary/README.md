# Living Commentary Pre-Generation Pipeline

Scripts for generating and validating pre-generated marginalia insights for the Living Commentary feature.

## Overview

These scripts generate AI-powered insights for the Gospel of John and bundle them as a SQLite database (`CommentaryData.sqlite`) that ships with the app. This approach has zero runtime AI costs.

## Prerequisites

```bash
pip install openai
export OPENAI_API_KEY="your-api-key"
```

## Scripts

### generate_commentary.py

Main generation script. Calls OpenAI API to generate insights for each verse.

```bash
# Generate sample chapters for review (1, 3, 11, 21)
python generate_commentary.py --sample

# Generate for a specific chapter
python generate_commentary.py --chapter 1

# Generate all of John (21 chapters)
python generate_commentary.py --all

# Dry run (no database writes)
python generate_commentary.py --chapter 1 --dry-run

# Check existing database
python generate_commentary.py --validate
```

**Estimated cost**: ~$0.50-1 for all of John using GPT-4o mini

### validate_insights.py

Validates generated insights against quality rules.

```bash
# Validate all insights
python validate_insights.py

# Validate specific chapter
python validate_insights.py --chapter 1
```

**Validation checks**:
- Segment locator bounds (character indices)
- Cross-reference validity (verses exist)
- Strong's number format
- Content quality (length, ban list)

## Workflow

### 1. Generate Sample

```bash
python generate_commentary.py --sample --dry-run
```

Review output for quality before proceeding.

### 2. Review Sample

Manually check generated insights for:
- Relevance to text
- Tone (scholarly but accessible)
- Citation quality
- Doctrinal safety

### 3. Generate Full

```bash
python generate_commentary.py --all
```

### 4. Validate

```bash
python validate_insights.py
```

Fix any errors before bundling.

### 5. Bundle

Copy `CommentaryData.sqlite` to app resources:

```bash
cp ../../BibleStudy/Resources/CommentaryData.sqlite \
   ../../BibleStudy/Resources/CommentaryData.sqlite
```

Add to Xcode project if not already present.

## Database Schema

```sql
CREATE TABLE commentary_insights (
    id TEXT PRIMARY KEY,                    -- "43_1_1_connection_0"
    book_id INTEGER NOT NULL,               -- 43 for John
    chapter INTEGER NOT NULL,
    verse_start INTEGER NOT NULL,
    verse_end INTEGER NOT NULL,
    segment_text TEXT NOT NULL,             -- Display text
    segment_start_char INTEGER NOT NULL,    -- 0-based start
    segment_end_char INTEGER NOT NULL,      -- Exclusive end
    insight_type TEXT NOT NULL,             -- connection/greek/theology/question
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    icon TEXT NOT NULL,                     -- SF Symbol name
    sources TEXT,                           -- JSON array
    content_version INTEGER NOT NULL,
    prompt_version TEXT NOT NULL,
    model_version TEXT NOT NULL,
    created_at TEXT NOT NULL,
    quality_tier TEXT DEFAULT 'standard',
    is_interpretive INTEGER DEFAULT 0
);
```

## Prompt Tuning

Edit `prompts/marginalia_prompt.txt` to adjust insight quality.

Key sections:
- **Insight Types**: Rules for each type (connection, greek, theology, question)
- **Quality Rules**: Constraints on format and content
- **Bad Examples**: Anti-patterns to avoid

## Troubleshooting

### "No verses found"
- Ensure `BibleData.sqlite` exists at `../../BibleStudy/Resources/BibleData.sqlite`
- Check that KJV translation is present (`translation_id = 'kjv'`)

### "API error"
- Verify `OPENAI_API_KEY` is set
- Check API quota/billing

### Segment locator errors
- The model sometimes miscounts character indices
- Re-run with `--dry-run` to debug specific verses
- Consider adding retry logic for malformed responses
