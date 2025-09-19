# 🔧 Database Fix Instructions

## Problem
The app is failing with:
```
PostgrestException: new row violates row-level security policy for table "users"
```

This happens because the `users` table either:
1. Doesn't exist with the required columns
2. Has incorrect RLS policies

## Solution
Run the database fix script to create/update the schema and policies.

## Instructions

### Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `fix_database_rls_issue.sql`
4. Paste into a new query
5. Click **Run** to execute

### Option 2: Supabase CLI (if installed)
```bash
supabase db reset
# Then apply the fix
psql -h your-supabase-host -U postgres -d postgres -f fix_database_rls_issue.sql
```

### Option 3: Direct PostgreSQL Connection
If you have direct access to your PostgreSQL database:
```bash
psql -h your-host -U your-user -d your-database -f fix_database_rls_issue.sql
```

## What the Fix Does

1. **Creates `users` table** with all required columns including `preferences`
2. **Adds missing columns** to existing tables (if they exist)
3. **Sets up proper RLS policies** for authenticated users
4. **Creates `user_images` table** for image metadata
5. **Sets up storage bucket** and policies
6. **Creates performance indexes**
7. **Prepares admin user** (if auth user exists)

## After Running the Fix

1. **Restart your Flutter app** to clear any cached auth state
2. **Try the "Admin Quick Login"** button again
3. **Test image saving** functionality

## Verification

The script includes a verification query at the end that shows the `users` table structure. You should see:
- `preferences` column with `jsonb` type
- All other required columns
- Proper default values

## Expected Behavior After Fix

✅ Admin Quick Login should work without errors  
✅ User profile creation should succeed  
✅ Image saving should work for authenticated users  
✅ "My Images" section should display saved images  

## If Issues Persist

Check the Flutter logs for any remaining errors and verify:
1. Supabase URL and anon key are correct
2. The database fix was applied successfully
3. RLS policies are enabled and working 