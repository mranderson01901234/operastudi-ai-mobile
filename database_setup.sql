-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to insert their own profile
CREATE POLICY "Users can insert their own profile" ON users
FOR INSERT WITH CHECK (auth.uid() = id);

-- Create policy to allow users to read their own profile  
CREATE POLICY "Users can read their own profile" ON users
FOR SELECT USING (auth.uid() = id);

-- Create policy to allow users to update their own profile
CREATE POLICY "Users can update their own profile" ON users
FOR UPDATE USING (auth.uid() = id);

-- Create storage bucket for user images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('user-images', 'user-images', true);

-- Create RLS policy for storage uploads
CREATE POLICY "Users can upload their own images" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create RLS policy for storage downloads
CREATE POLICY "Users can view their own images" ON storage.objects
FOR SELECT USING (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create RLS policy for storage updates
CREATE POLICY "Users can update their own images" ON storage.objects
FOR UPDATE USING (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create RLS policy for storage deletes
CREATE POLICY "Users can delete their own images" ON storage.objects
FOR DELETE USING (bucket_id = 'user-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create user_images table for metadata
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

-- Create policies for user_images table
CREATE POLICY "Users can insert their own image records" ON user_images
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read their own image records" ON user_images
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own image records" ON user_images
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own image records" ON user_images
FOR DELETE USING (auth.uid() = user_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_images_user_id ON user_images(user_id);
CREATE INDEX IF NOT EXISTS idx_user_images_created_at ON user_images(created_at);
