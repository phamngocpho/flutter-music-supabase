import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/core/extensions/is_dark_mode.dart';
import 'package:spotify/core/theme/app_colors.dart';
import 'package:spotify/domain/entities/song_entity.dart';
import 'package:spotify/presentation/home/bloc/play_list_cubit.dart';
import 'package:spotify/presentation/home/bloc/play_list_state.dart';
import 'package:spotify/presentation/song_player/pages/song_player.dart';

class GenreListTab extends StatelessWidget {
  const GenreListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayListCubit()..getPlayList(),
      child: BlocBuilder<PlayListCubit, PlayListState>(
        builder: (context, state) {
          if (state is PlayListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlayListLoaded) {
            // Group songs by genre
            Map<String, List<SongEntity>> groupedByGenre = {'Unknown': []};
            for (var song in state.songs) {
              String genre = song.genre ?? 'Unknown';
              if (!groupedByGenre.containsKey(genre)) {
                groupedByGenre[genre] = [];
              }
              groupedByGenre[genre]!.add(song);
            }

            // Remove Unknown if empty
            if (groupedByGenre['Unknown']!.isEmpty) {
              groupedByGenre.remove('Unknown');
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedByGenre.keys.length,
              itemBuilder: (context, index) {
                String genre = groupedByGenre.keys.elementAt(index);
                List<SongEntity> songs = groupedByGenre[genre]!;

                return _buildGenreCard(context, genre, songs);
              },
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildGenreCard(BuildContext context, String genre, List<SongEntity> songs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.8),
                AppColors.primary.withValues(alpha: 0.4),
              ],
            ),
          ),
          child: const Icon(Icons.category, color: Colors.white),
        ),
        title: Text(
          genre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${songs.length} song${songs.length > 1 ? 's' : ''}'),
        children: songs.map((song) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.isDarkMode ? AppColors.darkGrey : const Color(0xffE6E6E6),
            ),
            child: song.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.music_note, color: AppColors.primary);
                      },
                    ),
                  )
                : const Icon(Icons.music_note, color: AppColors.primary),
          ),
          title: Text(song.title),
          subtitle: Text(song.artist),
          trailing: Text(
            '${song.duration ~/ 60}:${(song.duration % 60).toInt().toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongPlayerPage(songEntity: song),
              ),
            );
          },
        )).toList(),
      ),
    );
  }
}

