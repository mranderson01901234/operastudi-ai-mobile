-- ==============================================
-- CRITICAL FIX: Database Schema and RLS Policies
-- ==============================================
-- This script fixes the authentication issue by:
-- 1. Creating the users table with all required columns
-- 2. Setting up proper RLS policies
-- 3. Ensuring compatibility with existing data

-- ==============================================
-- STEP 1: Create Users Table (if not exists)
-- ==============================================

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can read their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

-- Create users table with all required columns
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  profile_picture_url TEXT,
  credits_remaining INTEGER DEFAULT 10,
  total_enhancements INTEGER DEFAULT 0,
  storage_used_mb DECIMAL(10,2) DEFAULT 0,
  preferences JSONB DEFAULT '{}',
  subscription_type TEXT DEFAULT 'free',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if table already exists (for existing databases)
DO $$
BEGIN
  -- Add preferences column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'preferences'
  ) THEN
    ALTER TABLE users ADD COLUMN preferences JSONB DEFAULT '{}';
  END IF;
  
  -- Add total_enhancements column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'total_enhancements'
  ) THEN
    ALTER TABLE users ADD COLUMN total_enhancements INTEGER DEFAULT 0;
  END IF;
  
  -- Add credits_remaining column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'credits_remaining'
  ) THEN
    ALTER TABLE users ADD COLUMN credits_remaining INTEGER DEFAULT 10;
  END IF;
  
  -- Add storage_used_mb column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'storage_used_mb'
  ) THEN
    ALTER TABLE users ADD COLUMN storage_used_mb DECIMAL(10,2) DEFAULT 0;
  END IF;
  
  -- Add subscription_type column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'subscription_type'
  ) THEN
    ALTER TABLE users ADD COLUMN subscription_type TEXT DEFAULT 'free';
  END IF;
  
  -- Add other potentially missing columns
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'name'
  ) THEN
    ALTER TABLE users ADD COLUMN name TEXT;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'profile_picture_url'
  ) THEN
    ALTER TABLE users ADD COLUMN profile_picture_url TEXT;
  END IF;
  
  -- Add created_at column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE users ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
  
  -- Add updated_at column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- ==============================================
-- STEP 2: Enable RLS and Create Policies
-- ==============================================

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies with proper error handling
CREATE POLICY "Users can insert their own profile" ON users
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can read their own profile" ON users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
FOR UPDATE USING (auth.uid() = id);

-- ==============================================
-- STEP 3: Create User Images Table and Policies
-- ==============================================

-- Create user_images table for metadata (if not exists)
CREATE TABLE IF NOT EXISTS user_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  original_filename TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processing_type TEXT DEFAULT 'general_enhancement',
  credits_consumed INTEGER DEFAULT 1
);

-- Enable RLS on user_images table
ALTER TABLE user_images ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can insert their own image records" ON user_images;
DROP POLICY IF EXISTS "Users can read their own image records" ON user_images;
DROP POLICY IF EXISTS "Users can update their own image records" ON user_images;
DROP POLICY IF EXISTS "Users can delete their own image records" ON user_images;

-- Create policies for user_images table
CREATE POLICY "Users can insert their own image records" ON user_images
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read their own image records" ON user_images
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own image records" ON user_images
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own image records" ON user_images
FOR DELETE USING (auth.uid() = user_id);

-- ==============================================
-- STEP 4: Storage Bucket and Policies
-- ==============================================

-- Create storage bucket for user images (if not exists)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('user-images', 'user-images', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Users can upload their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own images" ON storage.objects;

-- Create RLS policies for storage
CREATE POLICY "Users can upload their own images" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own images" ON storage.objects
FOR SELECT USING (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own images" ON storage.objects
FOR UPDATE USING (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own images" ON storage.objects
FOR DELETE USING (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ==============================================
-- STEP 5: Performance Indexes
-- ==============================================

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_user_images_user_id ON user_images(user_id);
CREATE INDEX IF NOT EXISTS idx_user_images_created_at ON user_images(created_at);

-- ==============================================
-- STEP 6: Test Admin User Creation
-- ==============================================

-- Create test admin user profile (if auth user exists)
-- This will help with the admin quick login functionality
DO $$
DECLARE
  admin_user_id UUID;
  admin_email TEXT := 'admin@operastudio.io';
BEGIN
  -- Get admin user ID from auth.users if it exists
  SELECT id INTO admin_user_id FROM auth.users WHERE email = admin_email;
  
  -- Only proceed if admin user exists in auth
  IF admin_user_id IS NOT NULL THEN
    -- Insert or update admin user profile with dynamic column handling
    INSERT INTO users (id, email)
    VALUES (admin_user_id, admin_email)
    ON CONFLICT (id) DO NOTHING;
    
    -- Update specific columns that exist
    UPDATE users SET
      credits_remaining = CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'credits_remaining')
        THEN GREATEST(COALESCE(credits_remaining, 0), 100)
        ELSE credits_remaining
      END,
      total_enhancements = CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'total_enhancements')
        THEN COALESCE(total_enhancements, 0)
        ELSE total_enhancements
      END,
      storage_used_mb = CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'storage_used_mb')
        THEN COALESCE(storage_used_mb, 0.0)
        ELSE storage_used_mb
      END,
      subscription_type = CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'subscription_type')
        THEN 'admin'
        ELSE subscription_type
      END,
      preferences = CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'preferences')
        THEN COALESCE(preferences, '{}'::jsonb)
        ELSE preferences
      END
    WHERE id = admin_user_id;
    
    RAISE NOTICE 'Admin user profile created/updated successfully for %', admin_email;
  ELSE
    RAISE NOTICE 'Admin user % not found in auth.users - skipping profile creation', admin_email;
  END IF;
END $$;

-- ==============================================
-- VERIFICATION
-- ==============================================

-- Show table structure for verification
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position; 