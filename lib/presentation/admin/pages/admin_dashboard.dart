import 'package:flutter/material.dart';
import 'package:spotify/core/extensions/is_dark_mode.dart';
import 'package:spotify/core/theme/app_colors.dart';
import 'package:spotify/domain/entities/song_entity.dart';
import 'package:spotify/domain/usecases/admin/delete_song_usecase.dart';
import 'package:spotify/domain/usecases/admin/get_all_songs_admin_usecase.dart';
import 'package:spotify/presentation/admin/pages/add_edit_song.dart';
import 'package:spotify/presentation/auth/pages/signup_or_siginin.dart';
import 'package:spotify/service_locator.dart';
import 'package:spotify/shared/widgets/basic_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<SongEntity> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    var result = await sl<GetAllSongsAdminUseCase>().call();

    result.fold(
      (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
      (songs) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _deleteSong(SongEntity song) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      var result = await sl<DeleteSongUseCase>().call(params: song.songId);
      result.fold(
        (error) => _showSnackBar(error, isError: true),
        (success) {
          _showSnackBar('Song deleted successfully');
          _loadSongs();
        },
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : AppColors.primary,
      ),
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignupOrSigninPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        hideBack: true,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        action: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditSongPage(),
            ),
          );
          if (result == true) {
            _loadSongs();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSongs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 80,
              color: context.isDarkMode ? Colors.white54 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No songs yet',
              style: TextStyle(
                fontSize: 18,
                color: context.isDarkMode ? Colors.white54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap + to add a new song'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSongs,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return _buildSongCard(song);
        },
      ),
    );
  }

  Widget _buildSongCard(SongEntity song) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: AppColors.primary),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(song.artist),
            Text(
              'Duration: ${_formatDuration(song.duration)}',
              style: TextStyle(
                fontSize: 12,
                color: context.isDarkMode ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditSongPage(song: song),
                  ),
                );
                if (result == true) {
                  _loadSongs();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSong(song),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(num duration) {
    int minutes = duration ~/ 60;
    int seconds = (duration % 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

