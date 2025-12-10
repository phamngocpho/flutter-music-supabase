# Flutter Music Player with Supabase

A modern, full-featured music streaming application built with Flutter and Supabase, featuring user authentication, admin dashboard for song management, cover image support, and genre/artist categorization.

## Features

### User Features
- User authentication (Sign up / Sign in / Logout)
- Browse songs with beautiful cover images
- Play songs with fullscreen player interface
- **Synchronized lyrics display (LRC format support)**
  - Real-time lyrics highlighting
  - Auto-scroll following playback position
  - Support for both LRC and plain text lyrics
- Add/remove favorite songs
- View songs by categories:
  - News (Latest releases)
  - Artists (Grouped by artist)
  - Genres (Grouped by genre)
- Auto-login with session persistence
- Dark/Light theme support
- Responsive UI design
- Pull-to-refresh functionality

### Admin Features
- Secure admin login (separate from user login)
- Complete song management dashboard:
  - Add new songs with audio file upload
  - Upload cover images for songs
  - **Upload lyrics files (LRC format) for synchronized lyrics display**
  - Edit existing songs (title, artist, genre, cover, audio file, lyrics)
  - Delete songs with confirmation
  - Auto-detect song duration from audio file
- View all songs with cover thumbnails
- Real-time song list updates

## Tech Stack

### Frontend
- Flutter SDK (>=3.1.3)
- Dart

### Backend
- Supabase
  - Authentication (Email/Password)
  - PostgreSQL Database
  - Storage (Audio files & Cover images)
  - Row Level Security (RLS)

### State Management & Architecture
- flutter_bloc / hydrated_bloc (BLoC pattern)
- Clean Architecture (Domain, Data, Presentation layers)
- get_it (Dependency Injection)
- dartz (Functional Programming)

### Media & UI
- just_audio (Audio playback with streaming)
- flutter_svg (Vector graphics)
- file_picker (File selection for web & mobile)
- cached_network_image (Image caching)

### Security
- flutter_dotenv (Environment variables)
- Secure credential management

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants, URLs, vectors
│   ├── extensions/         # Dart extensions
│   ├── theme/             # App themes (light/dark)
│   └── usecase/           # Base usecase interface
├── data/
│   ├── models/            # Data models (JSON serialization)
│   ├── repositories/      # Repository implementations
│   └── services/          # Supabase service implementations
├── domain/
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Business logic use cases
│       └── admin/         # Admin-specific use cases
├── presentation/
│   ├── admin/             # Admin dashboard pages
│   │   └── pages/         # Add/Edit/Delete songs UI
│   ├── auth/              # Authentication pages
│   ├── home/              # Home page with tabs
│   │   └── widgets/       # News songs, playlist, artists, genres
│   ├── profile/           # User profile
│   ├── song_player/       # Music player with controls
│   └── splash/            # Splash screen
└── shared/
    └── widgets/           # Reusable widgets

```

## Database Schema

### Songs Table
```sql
- id (uuid, primary key)
- title (text)
- artist (text)
- duration (numeric, in seconds)
- releaseDate (timestamptz)
- created_at (timestamptz)
- url (text, song file URL)
- coverUrl (text, cover image URL)
- genre (text, nullable)
- lyricsUrl (text, nullable, lyrics file URL)
```

### Users Table
```sql
- id (uuid, primary key, references auth.users)
- name (text)
- email (text)
- created_at (timestamptz)
```

### Favorites Table
```sql
- id (uuid, primary key)
- user_id (uuid, references Users)
- song_id (uuid, references Songs)
- added_date (timestamptz)
```

## Storage Buckets

- **songs**: Audio files (.mp3, .m4a, etc.)
- **song-covers**: Cover images (.jpg, .png)
- **lyrics**: Lyrics files (.lrc, .txt)

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.1.3)
- Dart SDK (>=3.1.3)
- Supabase account
- Code editor (VS Code, Android Studio, IntelliJ IDEA)

### Installation Steps

1. **Clone the repository**
```bash
git clone https://github.com/phamngocpho/flutter-music-supabase.git
cd flutter-music-supabase
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup Supabase**
   - Create a new project on [Supabase](https://supabase.com)
   - Create the required tables (Songs, Users, Favorites)
   - Create storage buckets (songs, song-covers, lyrics)
   - Setup Row Level Security policies (see SUPABASE_CONFIG.md)

4. **Configure Environment Variables**
   - Copy `.env.example` to `.env`
   ```bash
   cp .env.example .env
   ```
   - Fill in your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_anon_key_here
   ADMIN_EMAIL=phamngocpho@duck.com
   ADMIN_PASSWORD=your_secure_password
   SONGS_BUCKET=songs
   COVERS_BUCKET=song-covers
   LYRICS_BUCKET=lyrics
   ```

5. **Run the application**
```bash
flutter run
```

### For Web
```bash
flutter run -d chrome
```

### For Mobile (Android/iOS)
```bash
flutter run
```

## Configuration Files

- `.env` - Environment variables (DO NOT COMMIT)
- `.env.example` - Environment template
- `SUPABASE_CONFIG.md` - Supabase setup guide
- `SECURITY_GUIDE.md` - Security best practices
- `USER_INTERFACE_UPDATES.md` - UI feature documentation

## Admin Access

### Default Admin Credentials
- Email: `phamngocpho@duck.com`
- Password: `phamngocpho`

**IMPORTANT**: Change these credentials in `.env` for production!

### Admin Login
1. Open the app
2. Go to Auth page
3. Click "Admin Login" button at the bottom
4. Enter admin credentials
5. Access admin dashboard

### Admin Capabilities
- Upload audio files (auto-detect duration)
- Upload cover images
- Add song metadata (title, artist, genre, release date)
- Edit existing songs
- Delete songs with confirmation
- View all songs with thumbnails

## User Guide

### Browsing Songs
- **News Tab**: See latest 3 songs with covers
- **Artists Tab**: Songs grouped by artist (expandable)
- **Genres Tab**: Songs grouped by genre (expandable)
- **Playlist**: All songs in list view

### Playing Music
- Tap any song to open player
- Fullscreen cover image display
- Playback controls (play/pause, seek, repeat)
- Add to favorites (heart button)

### Favorites
- Tap heart icon on any song
- View favorites in Profile page

### Profile
- View user information
- See favorite songs
- Logout option

## Development

### Running Tests
```bash
flutter test
```

### Building for Production

**Android**
```bash
flutter build apk --release
```

**iOS**
```bash
flutter build ios --release
```

**Web**
```bash
flutter build web --release
```

## Security Notes

1. Never commit `.env` file to version control
2. Use strong passwords for admin accounts
3. Rotate Supabase keys regularly
4. Enable RLS policies on all tables
5. Validate file uploads (type, size)
6. Use HTTPS for all connections

See `SECURITY_GUIDE.md` for detailed security practices.

## Database Migration Guide

### Adding Lyrics Feature to Existing Database

If you're upgrading from a previous version without lyrics support, follow these steps:

#### Step 1: Add lyricsUrl Column to Songs Table

Execute this SQL in your Supabase SQL Editor:

```sql
-- Add lyricsUrl column to Songs table
ALTER TABLE "Songs" 
ADD COLUMN "lyricsUrl" TEXT;

-- Add a comment to document the column
COMMENT ON COLUMN "Songs"."lyricsUrl" IS 'URL to the lyrics file (.lrc format) stored in Supabase Storage';
```

#### Step 2: Create Lyrics Storage Bucket

1. Go to your Supabase Dashboard
2. Navigate to **Storage** section
3. Click **Create a new bucket**
4. Configure the bucket:
   - **Name**: `lyrics`
   - **Public bucket**: Check this option (enable public access)
   - **Allowed MIME types**: Leave empty or add `text/plain`
   - **File size limit**: 1 MB (lyrics files are small)

#### Step 3: Set Storage Policies for Lyrics Bucket

Execute these SQL commands in Supabase SQL Editor:

```sql
-- Allow public read access to lyrics
CREATE POLICY "Public Access to Lyrics" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'lyrics');

-- Allow authenticated users to upload lyrics (for admin)
CREATE POLICY "Authenticated Upload Lyrics" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'lyrics' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to update lyrics
CREATE POLICY "Authenticated Update Lyrics" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'lyrics' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to delete lyrics
CREATE POLICY "Authenticated Delete Lyrics" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'lyrics' 
  AND auth.role() = 'authenticated'
);
```

#### Step 4: Verify the Migration

Run these queries to verify the setup:

```sql
-- Check if lyricsUrl column exists
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'Songs' AND column_name = 'lyricsUrl';

-- Check existing songs (should show NULL for lyricsUrl)
SELECT id, title, artist, "lyricsUrl" 
FROM "Songs" 
LIMIT 5;
```

#### Step 5: Update Environment Variables

Ensure your `.env` file includes:

```env
LYRICS_BUCKET=lyrics
```

#### Step 6: Test the Feature

1. Restart your Flutter application
2. Login as admin
3. Edit an existing song or add a new one
4. Upload a `.lrc` file in the lyrics section
5. Save the song
6. Play the song as a user - lyrics should display synchronized with playback

### LRC File Format Guide

LRC (Lyric) files use timestamps to sync lyrics with audio. Format:

```
[00:12.00]First line of lyrics
[00:17.20]Second line of lyrics
[00:21.10]Third line of lyrics
[mm:ss.xx]Lyrics text
```

**Example LRC File:**

```lrc
[00:00.00]Song Title - Artist Name
[00:05.00]
[00:12.50]Walking down the street
[00:15.80]Under the moonlight
[00:19.20]Feeling so alive tonight
[00:23.50]
[00:25.00]Chorus:
[00:26.30]We're dancing in the rain
[00:29.60]Nothing else matters again
[00:33.00]Just you and me, we're free
```

**Tips for Creating LRC Files:**
- Use a lyrics editor like [LRC Maker](https://lrcmaker.com/)
- Timestamps format: `[mm:ss.xx]` where mm=minutes, ss=seconds, xx=centiseconds
- Empty lines can have just `[timestamp]` without text
- Metadata can be included: `[ar:Artist]`, `[ti:Title]`, `[al:Album]`

### Rollback Instructions

If you need to remove the lyrics feature:

```sql
-- Remove lyricsUrl column
ALTER TABLE "Songs" DROP COLUMN "lyricsUrl";

-- Delete all policies for lyrics bucket
DROP POLICY IF EXISTS "Public Access to Lyrics" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload Lyrics" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Update Lyrics" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Delete Lyrics" ON storage.objects;

-- Delete lyrics bucket (via Supabase Dashboard or API)
-- This must be done through the Supabase Dashboard: Storage > lyrics > Delete bucket
```

## Troubleshooting

### Common Issues

**1. Environment variables not loading**
- Ensure `.env` file exists in project root
- Check asset path in `pubspec.yaml`
- Restart app after changing `.env`

**2. Upload fails**
- Check Supabase storage policies
- Verify bucket names match `.env`
- Ensure file size is within limits

**3. Admin login fails**
- Verify admin email exists in Supabase Auth
- Check credentials in `.env`
- Ensure RLS policies allow admin access

**4. Songs not displaying**
- Check database RLS policies
- Verify songs table has data
- Check network connection

**5. Lyrics not displaying or syncing incorrectly**
- Verify the LRC file format is correct (use [LRC Maker](https://lrcmaker.com/) to validate)
- Check if `lyricsUrl` column exists in database
- Ensure lyrics bucket has public read access
- Verify the LRC file is accessible via its public URL
- Check timestamp format: `[mm:ss.xx]` (minutes:seconds.centiseconds)
- Clear app cache and restart

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Supabase team for the backend platform
- just_audio package for audio playback
- All contributors and supporters

## Support

For issues and questions:
- Create an issue on GitHub
- Check existing documentation in `docs/` folder
- Review `SUPABASE_CONFIG.md` for setup help

## Roadmap

Future enhancements planned:
- Playlist creation and management
- Social sharing features
- Audio equalizer
- Download for offline playback
- Multi-language support
- Artist profiles
- Song recommendations
- Advanced search and filters
- Lyrics editing in admin panel
- Multiple lyrics format support (TXT, SRT)

---

**Version**: 1.0.0
**Last Updated**: December 2025
**Flutter Version**: 3.1.3+
**Supabase**: 2.0.0+

### 1. Clone the repository

```bash
git clone https://github.com/phamngocpho/flutter-music-supabase.git
cd flutter-music-supabase
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

1. Create a new project on [Supabase](https://supabase.com)
2. Update `lib/supabase_options.dart` with your credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 4. Setup Database

Run the following SQL in your Supabase SQL Editor:

```sql
-- Create Users table
CREATE TABLE public."Users" (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public."Users" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" ON public."Users"
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON public."Users"
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own data" ON public."Users"
  FOR UPDATE USING (auth.uid() = id);

-- Create Songs table
CREATE TABLE public."Songs" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  duration NUMERIC NOT NULL,
  "releaseDate" TIMESTAMP WITH TIME ZONE NOT NULL,
  url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public."Songs" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view songs" ON public."Songs"
  FOR SELECT USING (true);

-- Create Favorites table
CREATE TABLE public."Favorites" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id UUID NOT NULL REFERENCES public."Songs"(id) ON DELETE CASCADE,
  added_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, song_id)
);

ALTER TABLE public."Favorites" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own favorites" ON public."Favorites"
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites" ON public."Favorites"
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" ON public."Favorites"
  FOR DELETE USING (auth.uid() = user_id);
```

### 5. Setup Storage (Optional)

1. Create a bucket named `songs` in Supabase Storage
2. Make it public
3. Upload your music files
4. Update song URLs in the database

### 6. Run the app

```bash
flutter run
```

## Database Schema

### Users Table
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `email` (TEXT)
- `created_at` (TIMESTAMP)

### Songs Table
- `id` (UUID, Primary Key)
- `title` (TEXT)
- `artist` (TEXT)
- `duration` (NUMERIC)
- `releaseDate` (TIMESTAMP)
- `url` (TEXT)
- `created_at` (TIMESTAMP)

### Favorites Table
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key)
- `song_id` (UUID, Foreign Key)
- `added_date` (TIMESTAMP)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.
