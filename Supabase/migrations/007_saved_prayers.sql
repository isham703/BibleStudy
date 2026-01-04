-- Saved Prayers (Prayers from the Deep feature)
-- AI-generated prayers saved by users

CREATE TABLE saved_prayers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    tradition TEXT NOT NULL,
    content TEXT NOT NULL,
    amen TEXT NOT NULL,
    user_context TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_saved_prayers_user ON saved_prayers(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_saved_prayers_tradition ON saved_prayers(user_id, tradition) WHERE deleted_at IS NULL;
CREATE INDEX idx_saved_prayers_created ON saved_prayers(user_id, created_at DESC) WHERE deleted_at IS NULL;

-- Updated_at trigger
CREATE TRIGGER saved_prayers_updated_at BEFORE UPDATE ON saved_prayers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Enable RLS
ALTER TABLE saved_prayers ENABLE ROW LEVEL SECURITY;

-- RLS Policies: user-private
CREATE POLICY "Users can view own prayers" ON saved_prayers
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own prayers" ON saved_prayers
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own prayers" ON saved_prayers
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own prayers" ON saved_prayers
    FOR DELETE USING (auth.uid() = user_id);
