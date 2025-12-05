# Flutter Music Player with Supabase

A modern music streaming application built with Flutter and Supabase, featuring authentication, song management, and favorites functionality.

## Features

- User authentication (Sign up / Sign in)
- Browse and play songs
- Add/remove favorite songs
- Auto-login with session persistence
- Dark/Light theme support
- Responsive UI design

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase
  - Authentication
  - PostgreSQL Database
  - Storage
- **State Management**: flutter_bloc, hydrated_bloc
- **Audio Player**: just_audio
- **Dependency Injection**: get_it

## Project Structure

```
lib/
├── core/                   # Core configurations and constants
├── data/                   # Data layer
│   ├── models/            # Data models
│   ├── repository/        # Repository implementations
│   └── sources/           # Data sources (Supabase services)
├── domain/                # Domain layer
│   ├── entities/          # Business entities
│   ├── repository/        # Repository interfaces
│   └── usecases/          # Business logic
└── presentation/          # UI layer
    ├── home/              # Home page
    ├── auth/              # Authentication pages
    ├── profile/           # User profile
    └── song_player/       # Music player
```

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.1.3)
- Dart SDK
- Supabase account

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
