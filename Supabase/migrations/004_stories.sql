-- Bible Study App - Narrative Cards (Stories) Feature
-- Migration 004: Stories schema for biblical narrative storytelling

-- Stories table - main story metadata
CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT,
    description TEXT NOT NULL,
    type TEXT NOT NULL, -- 'narrative', 'character', 'thematic', 'parable', 'prophecy'
    reading_level TEXT NOT NULL DEFAULT 'adult', -- 'child', 'teen', 'adult'
    is_prebuilt BOOLEAN DEFAULT false,
    verse_anchors JSONB NOT NULL, -- Array of {bookId, chapter, verseStart, verseEnd}
    estimated_minutes INTEGER NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT false,
    generation_mode TEXT NOT NULL DEFAULT 'prebuilt', -- 'prebuilt', 'ai'
    model_id TEXT,
    prompt_version INTEGER NOT NULL DEFAULT 1,
    schema_version INTEGER NOT NULL DEFAULT 1,
    generated_at TIMESTAMPTZ,
    source_passage_ids JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Story segments - individual scenes/segments within a story
CREATE TABLE story_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE NOT NULL,
    order_index INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    verse_anchor JSONB, -- {bookId, chapter, verseStart, verseEnd}
    timeline_label TEXT, -- "Day 1", "Year 10 of Reign"
    location TEXT, -- "Garden of Eden", "Mount Sinai"
    key_characters JSONB, -- Array of character UUIDs
    mood TEXT, -- 'joyful', 'solemn', 'dramatic', etc.
    reflection_question TEXT,
    key_term JSONB -- {term, originalWord, briefMeaning}
);

-- Story characters - biblical characters appearing in stories
CREATE TABLE story_characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    title TEXT,
    description TEXT NOT NULL,
    role TEXT NOT NULL, -- 'protagonist', 'antagonist', 'supporting', 'divine', 'messenger'
    first_appearance JSONB, -- {bookId, chapter, verseStart, verseEnd}
    key_verses JSONB, -- Array of verse ranges
    icon_name TEXT
);

-- Story progress - user reading progress through stories
CREATE TABLE story_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE NOT NULL,
    current_segment_index INTEGER DEFAULT 0,
    completed_segment_ids JSONB DEFAULT '[]',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    last_read_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    reflection_notes JSONB DEFAULT '{}',
    UNIQUE(user_id, story_id)
);

-- AI-generated story cache (for cost optimization)
CREATE TABLE ai_story_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT UNIQUE NOT NULL,
    verse_range JSONB NOT NULL,
    reading_level TEXT NOT NULL,
    story_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Indexes for stories
CREATE INDEX idx_stories_type ON stories(type);
CREATE INDEX idx_stories_level ON stories(reading_level);
CREATE INDEX idx_stories_user ON stories(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_stories_public ON stories(is_public) WHERE is_public = true;
CREATE INDEX idx_stories_prebuilt ON stories(is_prebuilt) WHERE is_prebuilt = true;

-- Indexes for story segments
CREATE INDEX idx_segments_story ON story_segments(story_id);
CREATE INDEX idx_segments_order ON story_segments(story_id, order_index);

-- Indexes for story characters
CREATE INDEX idx_characters_name ON story_characters(name);

-- Indexes for story progress
CREATE INDEX idx_progress_user ON story_progress(user_id);
CREATE INDEX idx_progress_story ON story_progress(story_id);
CREATE INDEX idx_progress_last_read ON story_progress(user_id, last_read_at);

-- Indexes for AI story cache
CREATE INDEX idx_ai_cache_key ON ai_story_cache(cache_key);
CREATE INDEX idx_ai_cache_expires ON ai_story_cache(expires_at) WHERE expires_at IS NOT NULL;

-- Trigger for updated_at on stories
CREATE OR REPLACE FUNCTION update_stories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stories_updated_at
    BEFORE UPDATE ON stories
    FOR EACH ROW
    EXECUTE FUNCTION update_stories_updated_at();

-- RLS Policies for stories

-- Stories: Users can view prebuilt/public stories and their own
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view prebuilt stories"
    ON stories FOR SELECT
    USING (is_prebuilt = true);

CREATE POLICY "Users can view public stories"
    ON stories FOR SELECT
    USING (is_public = true);

CREATE POLICY "Users can view own stories"
    ON stories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own stories"
    ON stories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own stories"
    ON stories FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own stories"
    ON stories FOR DELETE
    USING (auth.uid() = user_id);

-- Story segments: Same as parent story
ALTER TABLE story_segments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view segments of viewable stories"
    ON story_segments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM stories
            WHERE stories.id = story_segments.story_id
            AND (stories.is_prebuilt = true OR stories.is_public = true OR stories.user_id = auth.uid())
        )
    );

CREATE POLICY "Users can manage segments of own stories"
    ON story_segments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM stories
            WHERE stories.id = story_segments.story_id
            AND stories.user_id = auth.uid()
        )
    );

-- Story characters: Publicly readable
ALTER TABLE story_characters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view story characters"
    ON story_characters FOR SELECT
    USING (true);

-- Story progress: User owns their progress
ALTER TABLE story_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
    ON story_progress FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
    ON story_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
    ON story_progress FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own progress"
    ON story_progress FOR DELETE
    USING (auth.uid() = user_id);

-- AI story cache: Publicly readable (shared cache), system managed
ALTER TABLE ai_story_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view cached stories"
    ON ai_story_cache FOR SELECT
    USING (true);

-- Comment on tables for documentation
COMMENT ON TABLE stories IS 'Biblical narrative stories with interactive timeline segments';
COMMENT ON TABLE story_segments IS 'Individual scenes/segments within a story';
COMMENT ON TABLE story_characters IS 'Biblical characters that appear in stories';
COMMENT ON TABLE story_progress IS 'User reading progress through stories';
COMMENT ON TABLE ai_story_cache IS 'Cache for AI-generated stories to reduce API costs';
