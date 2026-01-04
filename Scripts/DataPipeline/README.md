# Bible Data Pipeline

Builds `BibleData.sqlite` from open-source data for the BibleStudy iOS app.

## Data Sources

| Source | Content | License |
|--------|---------|---------|
| [scrollmapper/bible_databases](https://github.com/scrollmapper/bible_databases) | KJV verses (31,102) | Public Domain |
| [OpenBible.info](https://www.openbible.info/labs/cross-references/) | Cross-references (~340,000) | CC BY 4.0 |
| [STEPBible-Data](https://github.com/STEPBible/STEPBible-Data) | Hebrew/Greek morphology (~443,000 tokens) | CC BY 4.0 |

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Build the database
python build_bible_database.py

# Output: BibleStudy/Resources/BibleData.sqlite
```

## Options

```
--output, -o PATH     Custom output path (default: ../BibleStudy/Resources/BibleData.sqlite)
--skip-download       Use cached files only (for offline builds)
--skip-morphology     Skip Hebrew/Greek tokens (faster, smaller database)
```

## What It Does

1. Downloads source files to `cache/` directory
2. Creates SQLite database with schema matching iOS app migrations (v1-v16)
3. Imports KJV verses with proper book/chapter/verse structure
4. Builds FTS5 full-text search index
5. Imports cross-references with relevance weights
6. Imports Hebrew/Greek morphology (optional)
7. Records data sources for attribution compliance

## Output Database

The generated database includes:

- **66 books** with metadata (testament, category, chapter counts)
- **31,102 verses** (complete KJV)
- **FTS5 index** for fast full-text search
- **~340,000 cross-references** with weights
- **~443,000 language tokens** (Hebrew + Greek morphology)
- **Data source records** for attribution screen

Expected size: ~15-25 MB

## Integration

After building:

1. Open Xcode project
2. Drag `BibleData.sqlite` to `BibleStudy/Resources/`
3. Ensure "Copy items if needed" is checked
4. Add to app target
5. The app's `DatabaseManager` will detect and use the bundled database

## Caching

Downloaded files are cached in `cache/` for faster rebuilds. To force re-download, delete the cache directory.

## Attribution

The generated database includes a `data_sources` table that the app uses to display proper attribution on the Attributions screen (required for CC BY compliance).
