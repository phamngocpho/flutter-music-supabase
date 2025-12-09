import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/core/extensions/is_dark_mode.dart';
import 'package:spotify/core/theme/app_colors.dart';
import 'package:spotify/presentation/home/bloc/news_songs_cubit.dart';
import 'package:spotify/presentation/song_player/pages/song_player.dart';

import 'package:spotify/domain/entities/song_entity.dart';
import '../bloc/news_songs_state.dart';

class NewsSongs extends StatelessWidget {
  const NewsSongs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsSongsCubit()..getNewsSongs(),
      child: SizedBox(
        height: 200,
        child: BlocBuilder<NewsSongsCubit,NewsSongsState>(
          builder: (context,state) {
            if (state is NewsSongsLoading) {
              return Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator()
              );
            } 

            if (state is NewsSongsLoaded) {
              return _songs(
                state.songs
              );
            }

            return Container();
          },
        )
        
      ),
    );
  }

  Widget _songs(List<SongEntity> songs) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context,index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
               builder: (BuildContext context) 
              => SongPlayerPage(
                songEntity: songs[index],
              )
            )
            );
          },
          child: SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: context.isDarkMode ? AppColors.darkGrey : const Color(0xffE6E6E6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover Image
                          songs[index].coverUrl != null
                              ? Image.network(
                                  songs[index].coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholder(songs[index].title, context);
                                  },
                                )
                              : _buildPlaceholder(songs[index].title, context),
                          // Play button overlay
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              height: 40,
                              width: 40,
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.isDarkMode
                                    ? AppColors.darkGrey.withValues(alpha: 0.9)
                                    : const Color(0xffE6E6E6).withValues(alpha: 0.9),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: context.isDarkMode
                                    ? const Color(0xff959595)
                                    : const Color(0xff555555),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                Text(
                  songs[index].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16
                  ),
                ),
                const SizedBox(height: 5,),
                Text(
                  songs[index].artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12
                  ),
                )
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context,index) => const SizedBox(width: 14,),
      itemCount: songs.length
    );
  }

  Widget _buildPlaceholder(String title, BuildContext context) {
    return Container(
      color: context.isDarkMode ? AppColors.darkGrey : const Color(0xffE6E6E6),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 60,
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}