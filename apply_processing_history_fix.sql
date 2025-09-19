-- ==============================================
-- CRITICAL FIX: Add missing processing_time_seconds column
-- ==============================================

-- Add the missing column if it doesn't exist
ALTER TABLE processing_history 
ADD COLUMN IF NOT EXISTS processing_time_seconds DECIMAL(5,2);

-- Ensure the table has all required columns
ALTER TABLE processing_history 
ADD COLUMN IF NOT EXISTS original_image_url TEXT;

-- Update any existing records to have default values
UPDATE processing_history 
SET processing_time_seconds = 0.0 
WHERE processing_time_seconds IS NULL;

-- Verify the fix
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'processing_history' 
AND column_name IN ('processing_time_seconds', 'original_image_url'); 