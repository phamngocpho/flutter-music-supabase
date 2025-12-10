-- Bảng Users
CREATE TABLE IF NOT EXISTS public."Users" (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng Songs
CREATE TABLE IF NOT EXISTS public."Songs" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  duration NUMERIC NOT NULL,
  "releaseDate" TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  url TEXT,
  "coverUrl" TEXT,
  genre TEXT,
  "lyricsUrl" TEXT
);

-- Bảng Favorites
CREATE TABLE IF NOT EXISTS public."Favorites" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id UUID NOT NULL REFERENCES public."Songs"(id) ON DELETE CASCADE,
  added_date TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, song_id)
);

-- Tạo indexes
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public."Favorites"(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_song_id ON public."Favorites"(song_id);
CREATE INDEX IF NOT EXISTS idx_songs_artist ON public."Songs"(artist);
CREATE INDEX IF NOT EXISTS idx_songs_genre ON public."Songs"(genre);



ALTER TABLE public."Users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Songs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Favorites" ENABLE ROW LEVEL SECURITY;



-- Users policies
CREATE POLICY "Users can view own data" ON public."Users"
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own data" ON public."Users"
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own data" ON public."Users"
  FOR UPDATE USING (auth.uid() = id);

-- Songs policies
CREATE POLICY "Anyone can view songs" ON public."Songs"
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert songs" ON public."Songs"
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update songs" ON public."Songs"
  FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete songs" ON public."Songs"
  FOR DELETE TO authenticated USING (true);

-- Favorites policies
CREATE POLICY "Users can view own favorites" ON public."Favorites"
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own favorites" ON public."Favorites"
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own favorites" ON public."Favorites"
  FOR DELETE USING (auth.uid() = user_id);



-- Bucket: songs
INSERT INTO storage.buckets (id, name, public)
VALUES ('songs', 'songs', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Public can read songs" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'songs');
CREATE POLICY "Authenticated users can upload songs" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'songs');
CREATE POLICY "Authenticated users can update songs" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'songs');
CREATE POLICY "Authenticated users can delete songs" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'songs');

-- Bucket: song-covers
INSERT INTO storage.buckets (id, name, public)
VALUES ('song-covers', 'song-covers', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Public can read covers" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'song-covers');
CREATE POLICY "Authenticated users can upload covers" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'song-covers');
CREATE POLICY "Authenticated users can update covers" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'song-covers');
CREATE POLICY "Authenticated users can delete covers" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'song-covers');

-- Bucket: lyrics
INSERT INTO storage.buckets (id, name, public)
VALUES ('lyrics', 'lyrics', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Public can read lyrics" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'lyrics');
CREATE POLICY "Authenticated users can upload lyrics" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'lyrics');
CREATE POLICY "Authenticated users can update lyrics" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'lyrics');
CREATE POLICY "Authenticated users can delete lyrics" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'lyrics');
