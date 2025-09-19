-- ==============================================
-- CRITICAL FIX: Create Missing Database Tables
-- ==============================================

-- Users table (extends Supabase auth.users)
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
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Processing history table
CREATE TABLE IF NOT EXISTS processing_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  image_name TEXT NOT NULL,
  processing_type TEXT NOT NULL,
  enhancement_settings JSONB NOT NULL,
  credits_consumed INTEGER NOT NULL,
  status TEXT NOT NULL,
  result_url TEXT,
  original_image_url TEXT,
  processing_time_seconds DECIMAL(5,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PATCH: Add original_image_url column if missing
ALTER TABLE processing_history ADD COLUMN IF NOT EXISTS original_image_url TEXT;

-- ==============================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================

-- Enable RLS on new tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE processing_history ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can insert their own profile" ON users
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can read their own profile" ON users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
FOR UPDATE USING (auth.uid() = id);

-- Processing history policies
CREATE POLICY "Users can insert their own processing records" ON processing_history
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read their own processing records" ON processing_history
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own processing records" ON processing_history
FOR UPDATE USING (auth.uid() = user_id);

-- ==============================================
-- PERFORMANCE INDEXES
-- ==============================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_last_login ON users(last_login);

-- Processing history indexes
CREATE INDEX IF NOT EXISTS idx_processing_history_user_id ON processing_history(user_id);
CREATE INDEX IF NOT EXISTS idx_processing_history_created_at ON processing_history(created_at);
CREATE INDEX IF NOT EXISTS idx_processing_history_processing_type ON processing_history(processing_type);
CREATE INDEX IF NOT EXISTS idx_processing_history_status ON processing_history(status);

-- ==============================================
-- HELPER FUNCTIONS
-- ==============================================

-- Function to increment numeric fields
CREATE OR REPLACE FUNCTION increment(
  table_name TEXT,
  column_name TEXT,
  amount NUMERIC,
  id UUID
) RETURNS NUMERIC AS $$
DECLARE
  result NUMERIC;
BEGIN
  EXECUTE format('UPDATE %I SET %I = %I + $1 WHERE id = $2 RETURNING %I', 
                 table_name, column_name, column_name, column_name)
  USING amount, id
  INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement numeric fields
CREATE OR REPLACE FUNCTION decrement(
  table_name TEXT,
  column_name TEXT,
  amount NUMERIC,
  id UUID
) RETURNS NUMERIC AS $$
DECLARE
  result NUMERIC;
BEGIN
  EXECUTE format('UPDATE %I SET %I = %I - $1 WHERE id = $2 RETURNING %I', 
                 table_name, column_name, column_name, column_name)
  USING amount, id
  INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;
