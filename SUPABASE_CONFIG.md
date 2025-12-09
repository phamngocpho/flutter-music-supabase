# Supabase Configuration Guide

This document provides detailed instructions for setting up and configuring Supabase for the Flutter Music Player application.

## Create Supabase Project

1. Visit https://supabase.com and sign in
2. Click on "New Project"
3. Fill in the information:
   - Project name: flutter-music-app (or your preferred name)
   - Database Password: Create a strong password and save it
   - Region: Choose the region closest to you
4. Click "Create new project" and wait a few minutes for Supabase to initialize

## Get API Keys

After the project is created:

1. Go to "Settings" → "API"
2. Copy the following information:
   - Project URL (format: https://xxxxx.supabase.co)
   - anon public key
3. Paste into your `.env` file

## Create Database Tables

### Step 1: Create Users Table

Go to "SQL Editor" in Supabase Dashboard and run:

```sql
-- Create Users table
CREATE TABLE public."Users" (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public."Users" ENABLE ROW LEVEL SECURITY;

-- Users can only view their own data
CREATE POLICY "Users can view own data" 
ON public."Users"
FOR SELECT 
USING (auth.uid() = id);

-- Users can create their own data
CREATE POLICY "Users can insert own data" 
ON public."Users"
FOR INSERT 
WITH CHECK (true);

-- Users can update their own data
CREATE POLICY "Users can update own data" 
ON public."Users"
FOR UPDATE 
USING (auth.uid() = id);
```

### Step 2: Create Songs Table

```sql
-- Create Songs table
CREATE TABLE public."Songs" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  duration NUMERIC NOT NULL,
  "releaseDate" TIMESTAMP WITH TIME ZONE NOT NULL,
  url TEXT,
  "coverUrl" TEXT,
  genre TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public."Songs" ENABLE ROW LEVEL SECURITY;

-- Allow everyone to view songs
CREATE POLICY "Anyone can view songs" 
ON public."Songs"
FOR SELECT 
USING (true);

-- Only authenticated users can add songs
CREATE POLICY "Authenticated users can insert songs" 
ON public."Songs"
FOR INSERT 
TO authenticated
WITH CHECK (true);

-- Only authenticated users can update songs
CREATE POLICY "Authenticated users can update songs" 
ON public."Songs"
FOR UPDATE 
TO authenticated
USING (true)
WITH CHECK (true);

-- Only authenticated users can delete songs
CREATE POLICY "Authenticated users can delete songs" 
ON public."Songs"
FOR DELETE 
TO authenticated
USING (true);
```

### Step 3: Create Favorites Table

```sql
-- Create Favorites table
CREATE TABLE public."Favorites" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id UUID NOT NULL REFERENCES public."Songs"(id) ON DELETE CASCADE,
  added_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, song_id)
);

-- Enable Row Level Security
ALTER TABLE public."Favorites" ENABLE ROW LEVEL SECURITY;

-- Users can only view their own favorites
CREATE POLICY "Users can view own favorites" 
ON public."Favorites"
FOR SELECT 
USING (auth.uid() = user_id);

-- Users can only add their own favorites
CREATE POLICY "Users can insert own favorites" 
ON public."Favorites"
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own favorites
CREATE POLICY "Users can delete own favorites" 
ON public."Favorites"
FOR DELETE 
USING (auth.uid() = user_id);
```

## Create Storage Buckets

### Bucket 1: songs (Contains music files)

1. Go to "Storage" in Supabase Dashboard
2. Click "New bucket"
3. Fill in:
   - Name: `songs`
   - Public bucket: Enable (to allow music playback)
4. Click "Create bucket"

### Bucket 2: song-covers (Contains cover images)

1. Click "New bucket"
2. Fill in:
   - Name: `song-covers`
   - Public bucket: Enable (to display images)
3. Click "Create bucket"

## Configure Storage Policies

### Policies for "songs" bucket

Go to Storage → songs → Policies and add:

```sql
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload songs"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'songs');

-- Allow public to read
CREATE POLICY "Public can read songs"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'songs');

-- Allow authenticated users to update
CREATE POLICY "Authenticated users can update songs"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'songs')
WITH CHECK (bucket_id = 'songs');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated users can delete songs"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'songs');
```

### Policies for "song-covers" bucket

```sql
-- Allow authenticated users to upload covers
CREATE POLICY "Authenticated users can upload covers"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'song-covers');

-- Allow public to read covers
CREATE POLICY "Public can read covers"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'song-covers');

-- Allow authenticated users to update covers
CREATE POLICY "Authenticated users can update covers"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'song-covers')
WITH CHECK (bucket_id = 'song-covers');

-- Allow authenticated users to delete covers
CREATE POLICY "Authenticated users can delete covers"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'song-covers');
```

## Configure Authentication

### Enable Email Authentication

1. Go to "Authentication" → "Providers"
2. Ensure "Email" is enabled
3. Options:
   - Confirm email: Enable if you want email verification
   - Secure email change: Enable for increased security

### Create Admin User

1. Go to "Authentication" → "Users"
2. Click "Add user"
3. Fill in:
   - Email: phamngocpho@duck.com (or your admin email)
   - Password: Create a strong password
   - Auto confirm user: Enable
4. Click "Create user"

## Configure Admin-only Policies (Optional)

If you want only admin to manage songs:

```sql
-- Create function to check admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN auth.jwt()->>'email' = 'phamngocpho@duck.com';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only admin can insert songs
DROP POLICY IF EXISTS "Authenticated users can insert songs" ON public."Songs";
CREATE POLICY "Only admin can insert songs"
ON public."Songs"
FOR INSERT
TO authenticated
WITH CHECK (is_admin());

-- Only admin can update songs
DROP POLICY IF EXISTS "Authenticated users can update songs" ON public."Songs";
CREATE POLICY "Only admin can update songs"
ON public."Songs"
FOR UPDATE
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- Only admin can delete songs
DROP POLICY IF EXISTS "Authenticated users can delete songs" ON public."Songs";
CREATE POLICY "Only admin can delete songs"
ON public."Songs"
FOR DELETE
TO authenticated
USING (is_admin());
```

## Verify Configuration

### Test Database Connection

1. Go to "Table Editor"
2. Check that tables have been created:
   - Users
   - Songs
   - Favorites

### Test Storage

1. Go to "Storage"
2. Check 2 buckets:
   - songs
   - song-covers
3. Try uploading a test file to verify policies

### Test Authentication

1. Run Flutter app
2. Try registering a new user
3. Try logging in
4. Check that user appears in Authentication → Users

## Common Error Handling

### Error: "new row violates row-level security policy"

Cause: Missing policy or incorrect policy

Solution:
1. Check if RLS is enabled
2. Verify policies are correct
3. Check if user is authenticated

### Error: "permission denied for table"

Cause: Missing access permissions

Solution:
1. Create policy for that table
2. Ensure RLS is enabled
3. Check user role (anon/authenticated)

### Error: "Failed to upload file"

Cause: Missing storage policy

Solution:
1. Check if bucket exists
2. Add policies for bucket
3. Ensure bucket is public if needed

### Error: "Invalid API key"

Cause: Incorrect or expired API key

Solution:
1. Recheck API key in Settings → API
2. Copy the correct anon key
3. Update .env file

## Advanced Security

### Limit File Size

Go to Settings → Storage and configure:
- Maximum file size: 50MB (for audio)
- Maximum file size: 5MB (for images)

### Rate Limiting

Go to Settings → API and configure:
- Rate limit: 100 requests/minute
- Increase if needed for production

### CORS Settings

If deploying web, configure CORS:
1. Go to Settings → API
2. Add your domain to CORS allowed origins

## Monitoring and Logs

### View Database Logs

1. Go to "Logs" → "Database"
2. Check slow queries
3. Monitor errors

### View API Logs

1. Go to "Logs" → "API"
2. Check request patterns
3. Monitor failed requests

### View Storage Logs

1. Go to "Logs" → "Storage"
2. Check upload/download activity
3. Monitor storage usage

## Backup and Recovery

### Backup Database

1. Go to Settings → Database
2. Enable daily backups
3. Configure retention period

### Restore from Backup

1. Go to Settings → Database → Backups
2. Select backup point
3. Click "Restore"

## Production Upgrade

When moving to production:

1. Upgrade plan if needed
2. Setup custom domain
3. Enable SSL
4. Configure monitoring alerts
5. Setup CI/CD pipelines
6. Review all security policies

## Reference Documentation

- Supabase Documentation: https://supabase.com/docs
- Authentication Guide: https://supabase.com/docs/guides/auth
- Storage Guide: https://supabase.com/docs/guides/storage
- Row Level Security: https://supabase.com/docs/guides/auth/row-level-security

## Support

If you encounter issues:
1. Check Supabase Status: https://status.supabase.com
2. Visit Supabase Discord: https://discord.supabase.com
3. Read docs: https://supabase.com/docs
4. Create an issue on the project's GitHub

