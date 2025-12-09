import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/core/extensions/is_dark_mode.dart';
import 'package:spotify/core/theme/app_colors.dart';
import 'package:spotify/domain/entities/song_entity.dart';
import 'package:spotify/presentation/home/bloc/play_list_cubit.dart';
import 'package:spotify/presentation/home/bloc/play_list_state.dart';
import 'package:spotify/presentation/song_player/pages/song_player.dart';

class ArtistListTab extends StatelessWidget {
  const ArtistListTab({super.key});

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
            // Group songs by artist
            Map<String, List<SongEntity>> groupedByArtist = {};
            for (var song in state.songs) {
              if (!groupedByArtist.containsKey(song.artist)) {
                groupedByArtist[song.artist] = [];
              }
              groupedByArtist[song.artist]!.add(song);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedByArtist.keys.length,
              itemBuilder: (context, index) {
                String artist = groupedByArtist.keys.elementAt(index);
                List<SongEntity> songs = groupedByArtist[artist]!;

                return _buildArtistCard(context, artist, songs);
              },
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildArtistCard(BuildContext context, String artist, List<SongEntity> songs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            artist[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          artist,
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
          subtitle: song.genre != null ? Text(song.genre!) : null,
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

