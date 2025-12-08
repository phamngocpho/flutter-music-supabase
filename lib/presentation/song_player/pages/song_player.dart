import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/common/widgets/appbar/app_bar.dart';
import 'package:spotify/domain/entities/song/song.dart';
import 'package:spotify/presentation/song_player/bloc/song_player_cubit.dart';
import 'package:spotify/presentation/song_player/bloc/song_player_state.dart';

import '../../../common/widgets/favorite_button/favorite_button.dart';
import '../../../core/configs/theme/app_colors.dart';

class SongPlayerPage extends StatelessWidget {
  final SongEntity songEntity;
  const SongPlayerPage({
    required this.songEntity,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: BasicAppbar(
        title: const Text(
          'Now playing',
          style: TextStyle(
            fontSize: 18
          ),
        ),
        action: IconButton(
          onPressed: (){},
          icon: const Icon(
            Icons.more_vert_rounded
          )
        ),
      ),
      body: BlocProvider(
        create: (_) => SongPlayerCubit()..loadSong(
          songEntity.url
        ),
        child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16
            ),
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    _songCover(context),
                    const SizedBox(height: 20,),
                    _songDetail(),
                    const SizedBox(height: 30,),
                    _songPlayer(context)
                  ],
                );
              }
            ),
          ),
      ),
      );
  }

  Widget _songCover(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(
             'https://dummyimage.com/400x400/333/fff&text=${Uri.encodeComponent(songEntity.title)}'
          )
        )
      ),
    );
  }

  Widget _songDetail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              songEntity.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22
              ),
            ),
            const SizedBox(height: 5, ),
              Text(
                songEntity.artist,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14
                ),
              ),
          ],
        ),
          FavoriteButton(
            songEntity: songEntity
          )
      ],
    );
  }

  Widget _songPlayer(BuildContext context) {
    return BlocBuilder<SongPlayerCubit,SongPlayerState>(
      builder: (context, state) {
        if(state is SongPlayerLoading){
          return const CircularProgressIndicator();
        } 
        if(state is SongPlayerLoaded) {
          return Column(
            children: [
              Slider(
                value: state.position.inSeconds.toDouble(),
                min: 0.0,
                max: state.duration.inSeconds.toDouble(),
                onChanged: (value) {
                  context.read<SongPlayerCubit>().seekToPosition(
                    Duration(seconds: value.toInt())
                  );
                }
             ),
             const SizedBox(height: 20,),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(state.position)
                ),

                Text(
                  formatDuration(state.duration)
                )
              ],
             ),
             const SizedBox(height: 20,),

             // Player controls with skip buttons
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 // Skip backward button (-10s)
                 IconButton(
                   iconSize: 35,
                   onPressed: () {
                     context.read<SongPlayerCubit>().skipBackward();
                   },
                   icon: const Icon(Icons.replay_10),
                 ),

                 const SizedBox(width: 20),

                 // Play/Pause button (main)
                 GestureDetector(
                   onTap: () {
                     context.read<SongPlayerCubit>().playOrPauseSong();
                   },
                   child: Container(
                     height: 60,
                     width: 60,
                     decoration: const BoxDecoration(
                       shape: BoxShape.circle,
                       color: AppColors.primary
                     ),
                     child: state.isBuffering
                         ? const Padding(
                             padding: EdgeInsets.all(15.0),
                             child: CircularProgressIndicator(
                               color: Colors.white,
                               strokeWidth: 3,
                             ),
                           )
                         : Icon(
                             state.isPlaying ? Icons.pause : Icons.play_arrow,
                             size: 30,
                           ),
                   ),
                 ),

                 const SizedBox(width: 20),

                 // Skip forward button (+10s)
                 IconButton(
                   iconSize: 35,
                   onPressed: () {
                     context.read<SongPlayerCubit>().skipForward();
                   },
                   icon: const Icon(Icons.forward_10),
                 ),
               ],
             ),

             const SizedBox(height: 30),

             // Additional controls row
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 // Stop button
                 IconButton(
                   icon: const Icon(Icons.stop),
                   iconSize: 28,
                   onPressed: () {
                     context.read<SongPlayerCubit>().stopSong();
                   },
                 ),

                 // Speed control
                 PopupMenuButton<double>(
                   icon: const Icon(Icons.speed),
                   onSelected: (speed) {
                     context.read<SongPlayerCubit>().setSpeed(speed);
                   },
                   itemBuilder: (context) => [
                     const PopupMenuItem(
                       value: 0.5,
                       child: Text('0.5x'),
                     ),
                     const PopupMenuItem(
                       value: 0.75,
                       child: Text('0.75x'),
                     ),
                     const PopupMenuItem(
                       value: 1.0,
                       child: Text('1.0x (Normal)'),
                     ),
                     const PopupMenuItem(
                       value: 1.25,
                       child: Text('1.25x'),
                     ),
                     const PopupMenuItem(
                       value: 1.5,
                       child: Text('1.5x'),
                     ),
                     const PopupMenuItem(
                       value: 2.0,
                       child: Text('2.0x'),
                     ),
                   ],
                 ),

                 // Volume control
                 IconButton(
                   icon: const Icon(Icons.volume_up),
                   iconSize: 28,
                   onPressed: () {
                     // Capture the cubit before opening dialog
                     final cubit = context.read<SongPlayerCubit>();
                     // Show volume dialog
                     _showVolumeDialog(context, cubit);
                   },
                 ),
               ],
             ),
            ],
          );
        }

        if(state is SongPlayerFailure) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Container();
      },
    );
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2,'0')}:${seconds.toString().padLeft(2,'0')}';
  }

  // Show volume control dialog
  void _showVolumeDialog(BuildContext context, SongPlayerCubit songPlayerCubit) {
    double currentVolume = songPlayerCubit.currentVolume; // Get current volume from cubit

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setState) {
            return AlertDialog(
              title: const Text('Âm lượng'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: currentVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label: '${(currentVolume * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              currentVolume = value;
                            });
                            // Use the captured cubit instead of context.read
                            songPlayerCubit.setVolume(value);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  Text('${(currentVolume * 100).round()}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}