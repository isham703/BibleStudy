-- Bible Study App - Initial Schema
-- Enable pgvector for semantic search
CREATE EXTENSION IF NOT EXISTS vector;

-- User profiles (extends auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    preferred_translation TEXT DEFAULT 'KJV',
    font_size INTEGER DEFAULT 18,
    theme TEXT DEFAULT 'system',
    devotional_mode_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Highlights
CREATE TABLE highlights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    book_id INTEGER NOT NULL,
    chapter INTEGER NOT NULL,
    verse_start INTEGER NOT NULL,
    verse_end INTEGER NOT NULL,
    color TEXT NOT NULL DEFAULT 'gold',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Notes
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    book_id INTEGER NOT NULL,
    chapter INTEGER NOT NULL,
    verse_start INTEGER NOT NULL,
    verse_end INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Saved AI explanations
CREATE TABLE saved_ai_explanations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    book_id INTEGER NOT NULL,
    chapter INTEGER NOT NULL,
    verse_start INTEGER NOT NULL,
    verse_end INTEGER NOT NULL,
    mode TEXT NOT NULL, -- 'explain', 'context', 'interpretation', 'why_linked', 'term'
    prompt_hash TEXT NOT NULL,
    response JSONB NOT NULL,
    model_used TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat threads
CREATE TABLE chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT,
    mode TEXT NOT NULL DEFAULT 'verse_anchored', -- 'verse_anchored', 'general'
    anchor_book_id INTEGER,
    anchor_chapter INTEGER,
    anchor_verse_start INTEGER,
    anchor_verse_end INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat messages
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES chat_threads(id) ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL, -- 'user', 'assistant'
    content TEXT NOT NULL,
    citations JSONB, -- [{book_id, chapter, verse_start, verse_end}]
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reading plans
CREATE TABLE reading_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    is_custom BOOLEAN DEFAULT true,
    schedule JSONB NOT NULL, -- [{day: 1, readings: [{book_id, chapter, verse_start, verse_end}]}]
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reading progress
CREATE TABLE reading_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plan_id UUID REFERENCES reading_plans(id) ON DELETE CASCADE NOT NULL,
    day_number INTEGER NOT NULL,
    completed_at TIMESTAMPTZ,
    reflection TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, plan_id, day_number)
);

-- Topics (reference data)
CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    level INTEGER DEFAULT 0, -- 0 = top-level
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Topic hierarchy
CREATE TABLE topic_edges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    child_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE(parent_id, child_id)
);

-- Topic to verse mappings
CREATE TABLE topic_verses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE NOT NULL,
    book_id INTEGER NOT NULL,
    chapter INTEGER NOT NULL,
    verse_start INTEGER NOT NULL,
    verse_end INTEGER NOT NULL,
    relevance_score FLOAT DEFAULT 1.0
);

-- Topic embeddings for semantic search
CREATE TABLE topic_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE NOT NULL,
    embedding vector(1536), -- OpenAI ada-002 dimension
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Topic feedback
CREATE TABLE topic_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE NOT NULL,
    book_id INTEGER NOT NULL,
    chapter INTEGER NOT NULL,
    verse_start INTEGER NOT NULL,
    verse_end INTEGER NOT NULL,
    is_relevant BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_highlights_user ON highlights(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_highlights_verse ON highlights(book_id, chapter, verse_start);
CREATE INDEX idx_notes_user ON notes(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_notes_verse ON notes(book_id, chapter, verse_start);
CREATE INDEX idx_saved_explanations_user ON saved_ai_explanations(user_id);
CREATE INDEX idx_saved_explanations_verse ON saved_ai_explanations(book_id, chapter, verse_start);
CREATE INDEX idx_chat_messages_thread ON chat_messages(thread_id);
CREATE INDEX idx_reading_progress_user_plan ON reading_progress(user_id, plan_id);
CREATE INDEX idx_topic_verses_topic ON topic_verses(topic_id);
CREATE INDEX idx_topic_verses_verse ON topic_verses(book_id, chapter, verse_start);
CREATE INDEX idx_topic_embeddings_vector ON topic_embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER highlights_updated_at BEFORE UPDATE ON highlights
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER notes_updated_at BEFORE UPDATE ON notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER chat_threads_updated_at BEFORE UPDATE ON chat_threads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
