-- Feature Flags table for runtime kill switches
-- Used by the app to remotely enable/disable features without app updates.
-- The app fetches active flags on launch and caches them locally.

CREATE TABLE IF NOT EXISTS feature_flags (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    enabled BOOLEAN NOT NULL DEFAULT true,
    is_active BOOLEAN NOT NULL DEFAULT true,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

-- Public read access (all authenticated users can read flags)
CREATE POLICY "feature_flags_select"
    ON feature_flags
    FOR SELECT
    TO authenticated
    USING (true);

-- Seed the live captions kill switch (enabled by default)
INSERT INTO feature_flags (key, enabled, is_active, description)
VALUES ('live_captions_enabled', true, true, 'Controls whether live captions feature is available in the sermon recording screen.')
ON CONFLICT (key) DO NOTHING;
