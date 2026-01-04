#!/usr/bin/env python3
"""
Bible Data Pipeline
==================
Downloads and processes Bible data from open-source repositories:
- KJV verses from scrollmapper/bible_databases
- Cross-references from OpenBible.info
- Morphology from STEPBible-Data

Generates BibleData.sqlite for the iOS app.

Usage:
    python build_bible_database.py [--output PATH] [--skip-download]

License: This script is part of the BibleStudy iOS app.
Data sources have their own licenses (see attributions).
"""

import sqlite3
import json
import os
import sys
import argparse
import hashlib
from datetime import datetime
from pathlib import Path

# Optional imports for download progress
try:
    import requests
    from tqdm import tqdm
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    print("Warning: requests/tqdm not installed. Run: pip install requests tqdm")

# Configuration
SCRIPT_DIR = Path(__file__).parent
CACHE_DIR = SCRIPT_DIR / "cache"
DEFAULT_OUTPUT = SCRIPT_DIR.parent.parent / "BibleStudy" / "Resources" / "BibleData.sqlite"

# Data source URLs
SOURCES = {
    "kjv_sqlite": {
        "url": "https://github.com/scrollmapper/bible_databases/raw/master/formats/sqlite/KJV.db",
        "filename": "KJV.db",
        "license": "Public Domain",
        "attribution": "KJV text from scrollmapper/bible_databases"
    },
    "crossrefs": {
        "url": "https://a.openbible.info/data/cross-references.zip",
        "filename": "cross-references.zip",
        "is_zip": True,
        "extract_file": "cross_references.txt",
        "license": "CC BY 4.0",
        "attribution": "Cross-references compiled by OpenBible.info"
    },
    # STEPBible files are split by book ranges
    "stepbible_hebrew_1": {
        "url": "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/Translators%20Amalgamated%20OT%2BNT/TAHOT%20Gen-Deu%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
        "filename": "TAHOT_Gen-Deu.txt",
        "license": "CC BY 4.0",
        "attribution": "Hebrew morphology from STEPBible.org"
    },
    "stepbible_hebrew_2": {
        "url": "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/Translators%20Amalgamated%20OT%2BNT/TAHOT%20Jos-Est%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
        "filename": "TAHOT_Jos-Est.txt",
        "license": "CC BY 4.0",
        "attribution": "Hebrew morphology from STEPBible.org"
    },
    "stepbible_hebrew_3": {
        "url": "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/Translators%20Amalgamated%20OT%2BNT/TAHOT%20Job-Sng%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
        "filename": "TAHOT_Job-Sng.txt",
        "license": "CC BY 4.0",
        "attribution": "Hebrew morphology from STEPBible.org"
    },
    "stepbible_hebrew_4": {
        "url": "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/Translators%20Amalgamated%20OT%2BNT/TAHOT%20Isa-Mal%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20STEPBible.org%20CC%20BY.txt",
        "filename": "TAHOT_Isa-Mal.txt",
        "license": "CC BY 4.0",
        "attribution": "Hebrew morphology from STEPBible.org"
    },
    "stepbible_greek_1": {
        "url": "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/Translators%20Amalgamated%20OT%2BNT/TAGNT%20Mat-Jhn%20-%20Translators%20Amalgamated%20Greek%20NT%20-%20STEPBible.org%20CC-BY.txt",
        "filename": "TAGNT_Mat-Jhn.txt",
        "license": "CC BY 4.0",
        "attribution": "Greek morphology from STEPBible.org"
    },
    "stepbible_greek_2": {
        "url": "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/Translators%20Amalgamated%20OT%2BNT/TAGNT%20Act-Rev%20-%20Translators%20Amalgamated%20Greek%20NT%20-%20STEPBible.org%20CC-BY.txt",
        "filename": "TAGNT_Act-Rev.txt",
        "license": "CC BY 4.0",
        "attribution": "Greek morphology from STEPBible.org"
    }
}

# Book ID mapping (scrollmapper uses 1-66, matching our Book.swift)
BOOK_NAMES = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
    "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
    "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
    "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
    "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
    "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
    "Zephaniah", "Haggai", "Zechariah", "Malachi",
    "Matthew", "Mark", "Luke", "John", "Acts",
    "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy",
    "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
    "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
    "Jude", "Revelation"
]

# OSIS to book ID mapping for STEPBible data
OSIS_TO_BOOK_ID = {
    "Gen": 1, "Exod": 2, "Lev": 3, "Num": 4, "Deut": 5,
    "Josh": 6, "Judg": 7, "Ruth": 8, "1Sam": 9, "2Sam": 10,
    "1Kgs": 11, "2Kgs": 12, "1Chr": 13, "2Chr": 14, "Ezra": 15,
    "Neh": 16, "Esth": 17, "Job": 18, "Ps": 19, "Prov": 20,
    "Eccl": 21, "Song": 22, "Isa": 23, "Jer": 24, "Lam": 25,
    "Ezek": 26, "Dan": 27, "Hos": 28, "Joel": 29, "Amos": 30,
    "Obad": 31, "Jonah": 32, "Mic": 33, "Nah": 34, "Hab": 35,
    "Zeph": 36, "Hag": 37, "Zech": 38, "Mal": 39,
    "Matt": 40, "Mark": 41, "Luke": 42, "John": 43, "Acts": 44,
    "Rom": 45, "1Cor": 46, "2Cor": 47, "Gal": 48, "Eph": 49,
    "Phil": 50, "Col": 51, "1Thess": 52, "2Thess": 53, "1Tim": 54,
    "2Tim": 55, "Titus": 56, "Phlm": 57, "Heb": 58, "Jas": 59,
    "1Pet": 60, "2Pet": 61, "1John": 62, "2John": 63, "3John": 64,
    "Jude": 65, "Rev": 66
}


def download_file(url: str, dest: Path, desc: str = None) -> bool:
    """Download a file with progress bar."""
    if not HAS_REQUESTS:
        print(f"Error: Cannot download without requests library")
        return False

    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        total = int(response.headers.get('content-length', 0))

        dest.parent.mkdir(parents=True, exist_ok=True)

        with open(dest, 'wb') as f:
            with tqdm(total=total, unit='B', unit_scale=True, desc=desc or dest.name) as pbar:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
                    pbar.update(len(chunk))
        return True
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return False


def ensure_cache_files(skip_download: bool = False) -> bool:
    """Ensure all required source files are cached."""
    import zipfile

    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    all_present = True
    for key, source in SOURCES.items():
        dest = CACHE_DIR / source["filename"]

        # For zip files, check if the extracted file exists
        if source.get("is_zip"):
            extract_file = CACHE_DIR / source.get("extract_file", "")
            if extract_file.exists():
                print(f"  [cached] {source['extract_file']}")
                continue
            elif dest.exists():
                # Zip exists but not extracted
                print(f"  [extracting] {source['filename']}...")
                try:
                    with zipfile.ZipFile(dest, 'r') as zf:
                        zf.extractall(CACHE_DIR)
                    print(f"  [extracted] {source['extract_file']}")
                    continue
                except Exception as e:
                    print(f"  Error extracting: {e}")
                    all_present = False
                    continue

        if dest.exists():
            print(f"  [cached] {source['filename']}")
        elif skip_download:
            print(f"  [missing] {source['filename']} (skipping download)")
            all_present = False
        else:
            print(f"  [downloading] {source['filename']}...")
            if download_file(source["url"], dest, source["filename"]):
                # Extract if it's a zip
                if source.get("is_zip"):
                    print(f"  [extracting] {source['filename']}...")
                    try:
                        with zipfile.ZipFile(dest, 'r') as zf:
                            zf.extractall(CACHE_DIR)
                        print(f"  [extracted] {source.get('extract_file', '')}")
                    except Exception as e:
                        print(f"  Error extracting: {e}")
                        all_present = False
            else:
                all_present = False

    return all_present


def compute_file_checksum(path: Path) -> str:
    """Compute MD5 checksum of a file."""
    md5 = hashlib.md5()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            md5.update(chunk)
    return md5.hexdigest()


def create_schema(conn: sqlite3.Connection):
    """Create all database tables matching iOS app migrations v1-v16 EXACTLY."""
    cursor = conn.cursor()

    # GRDB migrations table - must be populated so iOS migrator skips all migrations
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS grdb_migrations (
            identifier TEXT NOT NULL PRIMARY KEY
        )
    """)

    # Insert all migration identifiers so iOS app knows they're applied
    migrations = [
        "v1_verses", "v2_crossrefs", "v3_tokens", "v4_highlights_cache",
        "v5_notes_cache", "v6_ai_cache", "v7_translations", "v8_user_translation_prefs",
        "v9_memorization", "v10_note_templates", "v11_highlight_categories",
        "v12_note_links", "v13_study_collections", "v14_reading_sessions",
        "v15_fts5_search", "v16_data_sources"
    ]
    for migration in migrations:
        cursor.execute("INSERT OR IGNORE INTO grdb_migrations (identifier) VALUES (?)", (migration,))

    # v7: Translations table (MUST match iOS exactly)
    # Note: iOS uses "description" not "translation_info"
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS translations (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            abbreviation TEXT NOT NULL,
            language TEXT NOT NULL,
            description TEXT NOT NULL,
            copyright TEXT,
            is_default INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0,
            is_available INTEGER NOT NULL DEFAULT 1
        )
    """)

    # v7: Verses table with translation support (MUST match iOS exactly)
    # Note: translation_id comes FIRST in column order and primary key
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS verses (
            translation_id TEXT NOT NULL REFERENCES translations(id) ON DELETE CASCADE,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            text TEXT NOT NULL,
            PRIMARY KEY (translation_id, book_id, chapter, verse)
        )
    """)

    # v2: Cross-references (matches iOS migration v2_crossrefs)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS cross_references (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_book_id INTEGER NOT NULL,
            source_chapter INTEGER NOT NULL,
            source_verse_start INTEGER NOT NULL,
            source_verse_end INTEGER NOT NULL,
            target_book_id INTEGER NOT NULL,
            target_chapter INTEGER NOT NULL,
            target_verse_start INTEGER NOT NULL,
            target_verse_end INTEGER NOT NULL,
            weight REAL NOT NULL DEFAULT 1.0,
            source TEXT
        )
    """)

    # v3: Language tokens (matches iOS migration v3_tokens)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS language_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            position INTEGER NOT NULL,
            surface TEXT NOT NULL,
            lemma TEXT,
            morph TEXT,
            strong_id TEXT,
            gloss TEXT,
            language TEXT NOT NULL
        )
    """)

    # v4: highlights_cache (matches iOS migration v4_highlights_cache + v11 category)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS highlights_cache (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse_start INTEGER NOT NULL,
            verse_end INTEGER NOT NULL,
            color TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            needs_sync INTEGER NOT NULL DEFAULT 0,
            category TEXT DEFAULT 'none'
        )
    """)

    # v5: notes_cache (matches iOS migration v5_notes_cache + v10 template + v12 links)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS notes_cache (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse_start INTEGER NOT NULL,
            verse_end INTEGER NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            needs_sync INTEGER NOT NULL DEFAULT 0,
            template TEXT DEFAULT 'freeform',
            linked_note_ids TEXT DEFAULT '[]'
        )
    """)

    # v6: ai_cache (matches iOS migration v6_ai_cache)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS ai_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cache_key TEXT NOT NULL UNIQUE,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse_start INTEGER NOT NULL,
            verse_end INTEGER NOT NULL,
            mode TEXT NOT NULL,
            prompt_hash TEXT NOT NULL,
            response TEXT NOT NULL,
            model_used TEXT,
            created_at TEXT NOT NULL,
            expires_at TEXT
        )
    """)

    # v8: user_translation_preferences (matches iOS migration v8)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS user_translation_preferences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL UNIQUE,
            primary_translation_id TEXT NOT NULL REFERENCES translations(id) ON DELETE SET NULL,
            secondary_translation_id TEXT REFERENCES translations(id) ON DELETE SET NULL,
            updated_at TEXT NOT NULL
        )
    """)

    # v9: memorization_items (matches iOS migration v9_memorization)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS memorization_items (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse_start INTEGER NOT NULL,
            verse_end INTEGER NOT NULL,
            verse_text TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            ease_factor REAL NOT NULL DEFAULT 2.5,
            interval INTEGER NOT NULL DEFAULT 0,
            repetitions INTEGER NOT NULL DEFAULT 0,
            next_review_date TEXT NOT NULL,
            last_review_date TEXT,
            mastery_level TEXT NOT NULL DEFAULT 'learning',
            total_reviews INTEGER NOT NULL DEFAULT 0,
            correct_reviews INTEGER NOT NULL DEFAULT 0,
            needs_sync INTEGER NOT NULL DEFAULT 0,
            deleted_at TEXT
        )
    """)

    # v13: study_collections (matches iOS migration v13_study_collections)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS study_collections (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT DEFAULT '',
            type TEXT NOT NULL DEFAULT 'personal',
            icon TEXT NOT NULL,
            color TEXT NOT NULL DEFAULT 'AccentGold',
            items TEXT NOT NULL DEFAULT '[]',
            is_pinned INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            needs_sync INTEGER NOT NULL DEFAULT 0
        )
    """)

    # v14: reading_sessions (matches iOS migration v14_reading_sessions)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS reading_sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verses_read TEXT NOT NULL DEFAULT '[]',
            translation_id TEXT NOT NULL DEFAULT 'kjv',
            duration_seconds INTEGER NOT NULL DEFAULT 0
        )
    """)

    # v15: FTS5 virtual table (matches iOS migration v15_fts5_search)
    # Using external content mode to sync with verses table
    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
            text,
            content='verses',
            content_rowid='rowid',
            tokenize='porter unicode61'
        )
    """)

    # v16: Data sources for attribution (matches iOS migration v16_data_sources)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS data_sources (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            version TEXT NOT NULL,
            source_url TEXT,
            license TEXT NOT NULL,
            license_url TEXT,
            attribution TEXT,
            record_count INTEGER,
            imported_at TEXT NOT NULL,
            checksum TEXT
        )
    """)

    # Create indexes (matching iOS migrations)
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_verses_translation_book_chapter ON verses(translation_id, book_id, chapter)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_verses_text ON verses(text)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_crossrefs_source ON cross_references(source_book_id, source_chapter, source_verse_start)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_crossrefs_target ON cross_references(target_book_id, target_chapter, target_verse_start)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_tokens_verse ON language_tokens(book_id, chapter, verse)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_tokens_lemma ON language_tokens(lemma)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_highlights_verse ON highlights_cache(book_id, chapter, verse_start)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_highlights_user ON highlights_cache(user_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_highlights_category ON highlights_cache(category)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_notes_verse ON notes_cache(book_id, chapter, verse_start)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_notes_user ON notes_cache(user_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_ai_cache_key ON ai_cache(cache_key)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_ai_cache_verse ON ai_cache(book_id, chapter, verse_start)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_memorization_user ON memorization_items(user_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_memorization_next_review ON memorization_items(user_id, next_review_date)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_memorization_mastery ON memorization_items(user_id, mastery_level)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_collections_user ON study_collections(user_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_collections_pinned ON study_collections(user_id, is_pinned)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_collections_type ON study_collections(user_id, type)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_sessions_user ON reading_sessions(user_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_sessions_date ON reading_sessions(user_id, started_at)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_sessions_book ON reading_sessions(user_id, book_id)")

    conn.commit()


def populate_books(conn: sqlite3.Connection):
    """Populate the books table with all 66 books."""
    cursor = conn.cursor()

    # Book metadata: (id, name, abbrev, testament, chapters, category)
    books_data = [
        # Old Testament - Pentateuch
        (1, "Genesis", "Gen", "OT", 50, "Pentateuch"),
        (2, "Exodus", "Exod", "OT", 40, "Pentateuch"),
        (3, "Leviticus", "Lev", "OT", 27, "Pentateuch"),
        (4, "Numbers", "Num", "OT", 36, "Pentateuch"),
        (5, "Deuteronomy", "Deut", "OT", 34, "Pentateuch"),
        # Historical
        (6, "Joshua", "Josh", "OT", 24, "Historical"),
        (7, "Judges", "Judg", "OT", 21, "Historical"),
        (8, "Ruth", "Ruth", "OT", 4, "Historical"),
        (9, "1 Samuel", "1Sam", "OT", 31, "Historical"),
        (10, "2 Samuel", "2Sam", "OT", 24, "Historical"),
        (11, "1 Kings", "1Kgs", "OT", 22, "Historical"),
        (12, "2 Kings", "2Kgs", "OT", 25, "Historical"),
        (13, "1 Chronicles", "1Chr", "OT", 29, "Historical"),
        (14, "2 Chronicles", "2Chr", "OT", 36, "Historical"),
        (15, "Ezra", "Ezra", "OT", 10, "Historical"),
        (16, "Nehemiah", "Neh", "OT", 13, "Historical"),
        (17, "Esther", "Esth", "OT", 10, "Historical"),
        # Wisdom/Poetry
        (18, "Job", "Job", "OT", 42, "Wisdom"),
        (19, "Psalms", "Ps", "OT", 150, "Wisdom"),
        (20, "Proverbs", "Prov", "OT", 31, "Wisdom"),
        (21, "Ecclesiastes", "Eccl", "OT", 12, "Wisdom"),
        (22, "Song of Solomon", "Song", "OT", 8, "Wisdom"),
        # Major Prophets
        (23, "Isaiah", "Isa", "OT", 66, "MajorProphets"),
        (24, "Jeremiah", "Jer", "OT", 52, "MajorProphets"),
        (25, "Lamentations", "Lam", "OT", 5, "MajorProphets"),
        (26, "Ezekiel", "Ezek", "OT", 48, "MajorProphets"),
        (27, "Daniel", "Dan", "OT", 12, "MajorProphets"),
        # Minor Prophets
        (28, "Hosea", "Hos", "OT", 14, "MinorProphets"),
        (29, "Joel", "Joel", "OT", 3, "MinorProphets"),
        (30, "Amos", "Amos", "OT", 9, "MinorProphets"),
        (31, "Obadiah", "Obad", "OT", 1, "MinorProphets"),
        (32, "Jonah", "Jonah", "OT", 4, "MinorProphets"),
        (33, "Micah", "Mic", "OT", 7, "MinorProphets"),
        (34, "Nahum", "Nah", "OT", 3, "MinorProphets"),
        (35, "Habakkuk", "Hab", "OT", 3, "MinorProphets"),
        (36, "Zephaniah", "Zeph", "OT", 3, "MinorProphets"),
        (37, "Haggai", "Hag", "OT", 2, "MinorProphets"),
        (38, "Zechariah", "Zech", "OT", 14, "MinorProphets"),
        (39, "Malachi", "Mal", "OT", 4, "MinorProphets"),
        # New Testament - Gospels
        (40, "Matthew", "Matt", "NT", 28, "Gospels"),
        (41, "Mark", "Mark", "NT", 16, "Gospels"),
        (42, "Luke", "Luke", "NT", 24, "Gospels"),
        (43, "John", "John", "NT", 21, "Gospels"),
        # Acts
        (44, "Acts", "Acts", "NT", 28, "Acts"),
        # Pauline Epistles
        (45, "Romans", "Rom", "NT", 16, "PaulineEpistles"),
        (46, "1 Corinthians", "1Cor", "NT", 16, "PaulineEpistles"),
        (47, "2 Corinthians", "2Cor", "NT", 13, "PaulineEpistles"),
        (48, "Galatians", "Gal", "NT", 6, "PaulineEpistles"),
        (49, "Ephesians", "Eph", "NT", 6, "PaulineEpistles"),
        (50, "Philippians", "Phil", "NT", 4, "PaulineEpistles"),
        (51, "Colossians", "Col", "NT", 4, "PaulineEpistles"),
        (52, "1 Thessalonians", "1Thess", "NT", 5, "PaulineEpistles"),
        (53, "2 Thessalonians", "2Thess", "NT", 3, "PaulineEpistles"),
        (54, "1 Timothy", "1Tim", "NT", 6, "PaulineEpistles"),
        (55, "2 Timothy", "2Tim", "NT", 4, "PaulineEpistles"),
        (56, "Titus", "Titus", "NT", 3, "PaulineEpistles"),
        (57, "Philemon", "Phlm", "NT", 1, "PaulineEpistles"),
        # General Epistles
        (58, "Hebrews", "Heb", "NT", 13, "GeneralEpistles"),
        (59, "James", "Jas", "NT", 5, "GeneralEpistles"),
        (60, "1 Peter", "1Pet", "NT", 5, "GeneralEpistles"),
        (61, "2 Peter", "2Pet", "NT", 3, "GeneralEpistles"),
        (62, "1 John", "1John", "NT", 5, "GeneralEpistles"),
        (63, "2 John", "2John", "NT", 1, "GeneralEpistles"),
        (64, "3 John", "3John", "NT", 1, "GeneralEpistles"),
        (65, "Jude", "Jude", "NT", 1, "GeneralEpistles"),
        # Apocalyptic
        (66, "Revelation", "Rev", "NT", 22, "Apocalyptic"),
    ]

    cursor.executemany(
        "INSERT OR REPLACE INTO books (id, name, abbreviation, testament, chapter_count, category) VALUES (?, ?, ?, ?, ?, ?)",
        books_data
    )
    conn.commit()
    print(f"  Inserted {len(books_data)} books")


def populate_translations(conn: sqlite3.Connection):
    """Populate the translations table."""
    cursor = conn.cursor()

    # Only KJV is included - it's public domain and fully redistributable
    # Other translations (ESV, NIV, NASB, NLT, NKJV) require licensing agreements
    translations = [
        # (id, name, abbreviation, language, description, copyright, is_default, sort_order, is_available)
        ("kjv", "King James Version", "KJV", "en",
         "The classic 1611 English translation, beloved for its literary beauty and precision",
         "Public Domain", 1, 1, 1),  # is_available = 1 (true)
    ]

    cursor.executemany(
        """INSERT OR REPLACE INTO translations
           (id, name, abbreviation, language, description, copyright, is_default, sort_order, is_available)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        translations
    )
    conn.commit()
    print(f"  Inserted {len(translations)} translations")


def import_kjv_verses(conn: sqlite3.Connection) -> int:
    """Import KJV verses from the cached SQLite database."""
    source_db = CACHE_DIR / SOURCES["kjv_sqlite"]["filename"]
    if not source_db.exists():
        print(f"  Error: KJV source not found at {source_db}")
        return 0

    cursor = conn.cursor()
    source_conn = sqlite3.connect(source_db)
    source_cursor = source_conn.cursor()

    # Check table structure - scrollmapper uses different formats
    # Option 1: 't_kjv' table with columns id, b, c, v, t
    # Option 2: 'verses' table with columns id, book, chapter, verse, text
    # Option 3: Separate book tables like 'Genesis', 'Exodus', etc.

    # Get list of tables
    source_cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in source_cursor.fetchall()]
    print(f"  Source tables: {tables[:5]}..." if len(tables) > 5 else f"  Source tables: {tables}")

    count = 0
    batch = []

    # Build batch with translation_id FIRST to match iOS schema order
    if 't_kjv' in tables:
        # Format 1: t_kjv table
        source_cursor.execute("SELECT b, c, v, t FROM t_kjv ORDER BY b, c, v")
        for row in source_cursor:
            book_id, chapter, verse, text = row
            text = ' '.join(str(text).split())
            batch.append(("kjv", book_id, chapter, verse, text))  # translation_id first!
    elif 'KJV_verses' in tables:
        # Format 2: scrollmapper KJV_verses table (book_id, chapter, verse, text)
        source_cursor.execute("SELECT book_id, chapter, verse, text FROM KJV_verses ORDER BY book_id, chapter, verse")
        for row in source_cursor:
            book_id, chapter, verse, text = row
            text = ' '.join(str(text).split())
            batch.append(("kjv", book_id, chapter, verse, text))  # translation_id first!
    elif 'verses' in tables:
        # Format 3: generic verses table
        source_cursor.execute("SELECT book, chapter, verse, text FROM verses ORDER BY book, chapter, verse")
        for row in source_cursor:
            book_id, chapter, verse, text = row
            text = ' '.join(str(text).split())
            batch.append(("kjv", book_id, chapter, verse, text))  # translation_id first!
    else:
        # Format 4: Try individual book tables or key_english
        if 'key_english' in tables:
            # This is the scrollmapper format with separate tables
            source_cursor.execute("""
                SELECT b, c, v, t FROM (
                    SELECT 1 as b, c, v, t FROM Genesis UNION ALL
                    SELECT 2 as b, c, v, t FROM Exodus UNION ALL
                    SELECT 3 as b, c, v, t FROM Leviticus
                    -- This would need all 66 books
                ) ORDER BY b, c, v
            """)
            for row in source_cursor:
                book_id, chapter, verse, text = row
                text = ' '.join(str(text).split())
                batch.append(("kjv", book_id, chapter, verse, text))  # translation_id first!
        else:
            print(f"  Error: Unknown database format. Tables: {tables}")
            source_conn.close()
            return 0

    # Insert in batches - iOS schema order: (translation_id, book_id, chapter, verse, text)
    for i in range(0, len(batch), 1000):
        chunk = batch[i:i+1000]
        cursor.executemany(
            "INSERT OR REPLACE INTO verses (translation_id, book_id, chapter, verse, text) VALUES (?, ?, ?, ?, ?)",
            chunk
        )
        count += len(chunk)

    source_conn.close()
    conn.commit()

    print(f"  Imported {count:,} KJV verses")
    return count


def rebuild_fts_index(conn: sqlite3.Connection):
    """Rebuild the FTS5 index from verses table.

    Uses the 'rebuild' command for external content FTS5 tables.
    The FTS table is defined with content='verses' so it syncs automatically.
    """
    cursor = conn.cursor()

    # For external content FTS5, use the rebuild command
    # This re-indexes all content from the source table
    cursor.execute("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")

    conn.commit()

    # Count indexed entries
    count = cursor.execute("SELECT COUNT(*) FROM verses_fts").fetchone()[0]
    print(f"  Built FTS5 index with {count:,} entries")


def parse_verse_ref(ref: str) -> tuple:
    """
    Parse a verse reference like 'Gen.1.1' or 'Gen.1.1-Gen.1.3' into (book_id, chapter, verse_start, verse_end).
    Returns (None, None, None, None) if parsing fails.
    """
    try:
        # Handle range references (e.g., "Gen.1.1-Gen.1.3")
        if '-' in ref:
            parts = ref.split('-')
            start_ref = parts[0]
            end_ref = parts[1] if len(parts) > 1 else parts[0]

            # Parse start
            start_parts = start_ref.split('.')
            if len(start_parts) < 3:
                return (None, None, None, None)
            book_abbrev = start_parts[0]
            chapter = int(start_parts[1])
            verse_start = int(start_parts[2])

            # Parse end
            end_parts = end_ref.split('.')
            if len(end_parts) >= 3:
                verse_end = int(end_parts[2])
            elif len(end_parts) == 1:
                # Just a verse number
                verse_end = int(end_parts[0])
            else:
                verse_end = verse_start

            book_id = OSIS_TO_BOOK_ID.get(book_abbrev)
            if book_id:
                return (book_id, chapter, verse_start, verse_end)
        else:
            # Single verse reference
            parts = ref.split('.')
            if len(parts) >= 3:
                book_abbrev = parts[0]
                chapter = int(parts[1])
                verse = int(parts[2])
                book_id = OSIS_TO_BOOK_ID.get(book_abbrev)
                if book_id:
                    return (book_id, chapter, verse, verse)
    except (ValueError, IndexError):
        pass

    return (None, None, None, None)


def import_cross_references(conn: sqlite3.Connection) -> int:
    """Import cross-references from OpenBible.info."""
    # Use the extracted file path if it's a zip
    source_config = SOURCES["crossrefs"]
    if source_config.get("is_zip"):
        source_file = CACHE_DIR / source_config.get("extract_file", source_config["filename"])
    else:
        source_file = CACHE_DIR / source_config["filename"]

    if not source_file.exists():
        print(f"  Warning: Cross-references file not found at {source_file}")
        return 0

    cursor = conn.cursor()
    count = 0
    skipped = 0
    batch = []

    # Try different encodings
    with open(source_file, 'r', encoding='utf-8', errors='replace') as f:
        first_line = True
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            # Skip header line
            if first_line:
                first_line = False
                if 'From Verse' in line or 'Votes' in line:
                    continue

            parts = line.split('\t')
            if len(parts) < 2:
                continue

            from_ref = parts[0]
            to_ref = parts[1]
            try:
                votes = int(parts[2]) if len(parts) > 2 else 1
            except ValueError:
                votes = 1

            # Parse references
            src_book, src_ch, src_vs, src_ve = parse_verse_ref(from_ref)
            tgt_book, tgt_ch, tgt_vs, tgt_ve = parse_verse_ref(to_ref)

            if None in (src_book, src_ch, src_vs, tgt_book, tgt_ch, tgt_vs):
                skipped += 1
                continue

            # Calculate weight based on votes (normalize to 0.3-1.0 range)
            weight = min(1.0, 0.3 + (votes / 100.0) * 0.7)

            batch.append((
                src_book, src_ch, src_vs, src_ve,
                tgt_book, tgt_ch, tgt_vs, tgt_ve,
                weight, "openbible"
            ))

            if len(batch) >= 5000:
                cursor.executemany(
                    """INSERT OR IGNORE INTO cross_references
                       (source_book_id, source_chapter, source_verse_start, source_verse_end,
                        target_book_id, target_chapter, target_verse_start, target_verse_end,
                        weight, source)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    batch
                )
                count += len(batch)
                batch = []

    if batch:
        cursor.executemany(
            """INSERT OR IGNORE INTO cross_references
               (source_book_id, source_chapter, source_verse_start, source_verse_end,
                target_book_id, target_chapter, target_verse_start, target_verse_end,
                weight, source)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            batch
        )
        count += len(batch)

    conn.commit()
    print(f"  Imported {count:,} cross-references (skipped {skipped:,} unparseable)")
    return count


def parse_stepbible_line(line: str, language: str) -> dict:
    """Parse a STEPBible data line into token fields."""
    # STEPBible TAHOT/TAGNT format is tab-separated:
    # Gen.1.1#01=L \t HebrewText \t Transliteration \t Gloss \t Strong's \t Morphology \t ...
    # Reference format: Book.Chapter.Verse#WordPos=Flag
    parts = line.split('\t')
    if len(parts) < 5:
        return None

    try:
        ref_col = parts[0].strip()

        # Parse reference like "Gen.1.1#01=L" or "Gen.1.1#01"
        # Remove any flag after = (like =L, =Q, =K)
        if '=' in ref_col:
            ref_col = ref_col.split('=')[0]

        # Split by # to get verse ref and word position
        if '#' not in ref_col:
            return None

        verse_ref, word_pos_str = ref_col.rsplit('#', 1)

        # Parse verse reference (Book.Chapter.Verse)
        ref_split = verse_ref.split('.')
        if len(ref_split) < 3:
            return None

        book_abbrev = ref_split[0]
        chapter = int(ref_split[1])
        verse = int(ref_split[2])
        book_id = OSIS_TO_BOOK_ID.get(book_abbrev)

        if not book_id:
            return None

        # Parse word position
        position = int(word_pos_str) if word_pos_str.isdigit() else 1

        # Extract Strong's number from the complex format
        # Format is like "H9003/{H7225G}" or "{H1254A}"
        strongs_raw = parts[4] if len(parts) > 4 else ""
        strongs = None
        if strongs_raw:
            # Extract first Strong's number found
            import re
            match = re.search(r'H(\d+[A-Z]?)', strongs_raw)
            if match:
                strongs = 'H' + match.group(1)
            else:
                match = re.search(r'G(\d+[A-Z]?)', strongs_raw)
                if match:
                    strongs = 'G' + match.group(1)

        return {
            "book_id": book_id,
            "chapter": chapter,
            "verse": verse,
            "position": position,  # iOS column name
            "surface": parts[1] if len(parts) > 1 else "",  # iOS column name
            "transliteration": parts[2] if len(parts) > 2 else None,  # Not in iOS schema, will be ignored
            "gloss": parts[3] if len(parts) > 3 else None,
            "strong_id": strongs,  # iOS column name
            "morph": parts[5] if len(parts) > 5 else None,  # iOS column name
            "lemma": None,  # Lemma is embedded in Strong's field, complex to extract
            "language": language
        }
    except (ValueError, IndexError):
        return None


def import_morphology(conn: sqlite3.Connection) -> int:
    """Import morphology data from STEPBible files."""
    cursor = conn.cursor()
    total_count = 0

    # Define file groups: (source_key_prefix, language)
    file_groups = [
        (["stepbible_hebrew_1", "stepbible_hebrew_2", "stepbible_hebrew_3", "stepbible_hebrew_4"], "hebrew"),
        (["stepbible_greek_1", "stepbible_greek_2"], "greek"),
    ]

    for source_keys, language in file_groups:
        count = 0
        skipped = 0
        batch = []

        for source_key in source_keys:
            if source_key not in SOURCES:
                continue

            source_file = CACHE_DIR / SOURCES[source_key]["filename"]
            if not source_file.exists():
                print(f"  Warning: {SOURCES[source_key]['filename']} not found")
                continue

            print(f"  Processing {SOURCES[source_key]['filename']}...")

            try:
                with open(source_file, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        # Skip header lines and comments
                        if not line or line.startswith('#') or line.startswith('$'):
                            continue

                        token = parse_stepbible_line(line, language)
                        if not token:
                            skipped += 1
                            continue

                        batch.append((
                            token["book_id"],
                            token["chapter"],
                            token["verse"],
                            token["position"],
                            token["surface"],
                            token["lemma"],
                            token["morph"],
                            token["strong_id"],
                            token["gloss"],
                            token["language"]
                        ))

                        if len(batch) >= 5000:
                            cursor.executemany(
                                """INSERT OR IGNORE INTO language_tokens
                                   (book_id, chapter, verse, position, surface,
                                    lemma, morph, strong_id, gloss, language)
                                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                                batch
                            )
                            count += len(batch)
                            batch = []
            except Exception as e:
                print(f"  Error reading {source_file}: {e}")
                continue

        if batch:
            cursor.executemany(
                """INSERT OR IGNORE INTO language_tokens
                   (book_id, chapter, verse, position, surface,
                    lemma, morph, strong_id, gloss, language)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                batch
            )
            count += len(batch)

        conn.commit()
        print(f"  Imported {count:,} {language} tokens (skipped {skipped:,})")
        total_count += count

    return total_count


def record_data_sources(conn: sqlite3.Connection, verse_count: int, crossref_count: int, token_count: int):
    """Record data source attribution in the database."""
    cursor = conn.cursor()
    now = datetime.utcnow().isoformat()

    sources = [
        ("kjv", "King James Version", "1.0",
         "https://github.com/scrollmapper/bible_databases",
         "Public Domain", None,
         "KJV text from scrollmapper/bible_databases. 1769 Cambridge Edition.",
         verse_count, now, None),

        ("openbible-crossrefs", "OpenBible Cross-References", "1.0",
         "https://www.openbible.info/labs/cross-references/",
         "CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/",
         "Cross-references compiled by OpenBible.info",
         crossref_count, now, None),

        ("stepbible-morphology", "STEPBible Morphology", "1.0",
         "https://github.com/STEPBible/STEPBible-Data",
         "CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/",
         "Hebrew and Greek morphological data from STEPBible.org",
         token_count, now, None),
    ]

    cursor.executemany(
        """INSERT OR REPLACE INTO data_sources
           (id, name, version, source_url, license, license_url, attribution, record_count, imported_at, checksum)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        sources
    )
    conn.commit()
    print(f"  Recorded {len(sources)} data sources")


def main():
    parser = argparse.ArgumentParser(description="Build Bible database from open sources")
    parser.add_argument("--output", "-o", type=Path, default=DEFAULT_OUTPUT,
                        help="Output SQLite database path")
    parser.add_argument("--skip-download", action="store_true",
                        help="Skip downloading, use cached files only")
    parser.add_argument("--skip-morphology", action="store_true",
                        help="Skip morphology import (faster for testing)")
    args = parser.parse_args()

    print("=" * 60)
    print("Bible Data Pipeline")
    print("=" * 60)

    # Step 1: Ensure source files
    print("\n[1/7] Checking source files...")
    if not ensure_cache_files(args.skip_download):
        if not args.skip_download:
            print("Error: Some source files could not be downloaded.")
            print("Run with --skip-download if files are already cached.")
            sys.exit(1)

    # Step 2: Create output database
    print(f"\n[2/7] Creating database at {args.output}...")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.output.exists():
        args.output.unlink()

    conn = sqlite3.connect(args.output)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")

    # Step 3: Create schema
    print("\n[3/7] Creating schema (migrations v1-v16)...")
    create_schema(conn)
    # Note: Books are hardcoded in Book.swift, not stored in database
    populate_translations(conn)

    # Step 4: Import verses
    print("\n[4/7] Importing KJV verses...")
    verse_count = import_kjv_verses(conn)

    # Step 5: Build FTS index
    print("\n[5/7] Building full-text search index...")
    rebuild_fts_index(conn)

    # Step 6: Import cross-references
    print("\n[6/7] Importing cross-references...")
    crossref_count = import_cross_references(conn)

    # Step 7: Import morphology (optional)
    token_count = 0
    if not args.skip_morphology:
        print("\n[7/7] Importing morphology data...")
        token_count = import_morphology(conn)
    else:
        print("\n[7/7] Skipping morphology (--skip-morphology)")

    # Record data sources
    print("\n[*] Recording data sources...")
    record_data_sources(conn, verse_count, crossref_count, token_count)

    # Optimize
    print("\n[*] Optimizing database...")
    conn.execute("VACUUM")
    conn.execute("ANALYZE")

    conn.close()

    # Report
    file_size = args.output.stat().st_size / (1024 * 1024)
    print("\n" + "=" * 60)
    print("BUILD COMPLETE")
    print("=" * 60)
    print(f"  Output: {args.output}")
    print(f"  Size: {file_size:.2f} MB")
    print(f"  Verses: {verse_count:,}")
    print(f"  Cross-references: {crossref_count:,}")
    print(f"  Language tokens: {token_count:,}")
    print("\nNext steps:")
    print("  1. Copy BibleData.sqlite to Xcode project")
    print("  2. Add to target as resource bundle")
    print("  3. Build and test the app")


if __name__ == "__main__":
    main()
