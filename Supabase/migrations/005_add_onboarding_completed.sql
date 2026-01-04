-- Add onboarding completed field to profiles
-- Enables cross-device onboarding state sync

ALTER TABLE profiles
ADD COLUMN has_completed_onboarding BOOLEAN DEFAULT false;

-- Add index for quick lookup
CREATE INDEX idx_profiles_onboarding ON profiles(has_completed_onboarding);

-- Update function to handle profile creation with onboarding state
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, has_completed_onboarding)
    VALUES (NEW.id, false)
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
