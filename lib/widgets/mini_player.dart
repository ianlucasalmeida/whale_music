import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:whale_music/screens/player_screen.dart';
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/favorites_manager.dart';
import 'package:whale_music/widgets/glass_container.dart';

class MiniPlayer extends StatelessWidget {
  final MyAudioHandler audioHandler;

  const MiniPlayer({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(audioHandler: audioHandler),
              ),
            );
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GlassContainer(
                borderRadius: 12,
                child: Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: QueryArtworkWidget(
                          id: int.parse(mediaItem.id),
                          type: ArtworkType.AUDIO,
                          artworkWidth: 50,
                          artworkHeight: 50,
                          nullArtworkWidget: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.withOpacity(0.3),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              mediaItem.artist ?? "Desconhecido",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Botão de Like funcional
                      StreamBuilder<List<String>>(
                        stream: FavoritesManager.favoritesStream,
                        builder: (context, snapshot) {
                          final isFav = FavoritesManager.isFavorite(
                            mediaItem.id,
                          );
                          return IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.redAccent : Colors.white,
                            ),
                            onPressed: () =>
                                FavoritesManager.toggleFavorite(mediaItem.id),
                          );
                        },
                      ),
                      // Botão de Play/Pause funcional
                      StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          final processingState =
                              snapshot.data?.processingState ??
                              AudioProcessingState.idle;
                          if (processingState == AudioProcessingState.loading ||
                              processingState ==
                                  AudioProcessingState.buffering) {
                            return Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            );
                          }
                          return IconButton(
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: playing
                                ? audioHandler.pause
                                : audioHandler.play,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
