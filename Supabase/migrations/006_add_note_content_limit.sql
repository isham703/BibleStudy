-- Add character limit constraint to notes table
-- Protects against abuse when notes have generous 50/day limit
ALTER TABLE notes
ADD CONSTRAINT notes_content_length_check
CHECK (length(content) <= 50000);

-- Add byte limit to prevent Unicode exploitation
-- Prevents character vs byte mismatch attacks (emoji/combining marks can use 4 bytes per character)
ALTER TABLE notes
ADD CONSTRAINT notes_byte_length_check
CHECK (octet_length(content) <= 200000);  -- 200KB max (4 bytes/char worst case)

-- Add comments explaining the constraints
COMMENT ON CONSTRAINT notes_content_length_check ON notes IS
'Prevents abuse by limiting note content to 50,000 characters (~25 pages)';

COMMENT ON CONSTRAINT notes_byte_length_check ON notes IS
'Prevents Unicode exploitation by limiting byte size to 200KB (worst case 4 bytes per character)';
