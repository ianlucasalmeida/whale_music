import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_session/audio_session.dart';
import 'package:whale_music/helpers/color_helper.dart';
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/favorites_manager.dart';
import 'package:whale_music/services/settings_manager.dart';
import 'package:whale_music/widgets/glass_container.dart';
import 'package:audio_service/audio_service.dart';

// Função auxiliar para formatar a duração de forma legível
String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$minutes:$seconds";
}

class PlayerScreen extends StatefulWidget {
  final MyAudioHandler audioHandler;
  const PlayerScreen({super.key, required this.audioHandler});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  MyAudioHandler get _audioHandler => widget.audioHandler;

  Color _dominantColor = Colors.blue.shade800;
  String _audioOutputName = "Carregando...";

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    if (_audioHandler.mediaItem.value != null) {
      _updateBackgroundColor(int.parse(_audioHandler.mediaItem.value!.id));
    }
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null && mounted) {
        _updateBackgroundColor(int.parse(mediaItem.id));
      }
    });
    _fetchAudioOutput();
  }

  // CORREÇÃO: Função simplificada que não usa o 'routeChangeStream'
  void _fetchAudioOutput() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices();
      final outputDevice = devices.firstWhere(
        (device) => device.isOutput,
        orElse: () => devices.first,
      );
      if (mounted) {
        setState(() {
          _audioOutputName = _getAudioOutputName(outputDevice.type);
        });
      }
    } catch (e) {
      print("Erro ao buscar dispositivo de áudio: $e");
    }
  }

  String _getAudioOutputName(AudioDeviceType? deviceType) {
    switch (deviceType) {
      case AudioDeviceType.bluetoothA2dp:
      case AudioDeviceType.bluetoothSco:
        return "Fone Bluetooth";
      case AudioDeviceType.wiredHeadset:
        return "Fone de Ouvido";
      case AudioDeviceType.builtInSpeaker:
      default:
        return "Alto-falante do aparelho";
    }
  }

  void _updateBackgroundColor(int songId) async {
    if (!SettingsManager.useDynamicColor) {
      if (mounted)
        setState(() => _dominantColor = Theme.of(context).colorScheme.primary);
      return;
    }

    final artwork = await OnAudioQuery().queryArtwork(
      songId,
      ArtworkType.AUDIO,
      size: 400,
    );
    if (artwork != null && mounted) {
      final imageProvider = MemoryImage(artwork);
      final color = await ColorHelper.getDominantColor(imageProvider);
      setState(() => _dominantColor = color);
    } else {
      if (mounted)
        setState(() => _dominantColor = Theme.of(context).colorScheme.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, snapshot) {
        final currentSong = snapshot.data;
        if (currentSong == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          body: Stack(
            children: [
              _buildDynamicBackground(int.parse(currentSong.id)),
              _buildMainContent(currentSong),
              _buildDraggablePlaylist(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicBackground(int songId) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _dominantColor.withOpacity(0.6),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          QueryArtworkWidget(
            id: songId,
            type: ArtworkType.AUDIO,
            artworkFit: BoxFit.cover,
            nullArtworkWidget: Container(),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(MediaItem currentSong) {
    return Positioned.fill(
      bottom: 100,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              _buildAppBar(currentSong),
              const Spacer(flex: 2),
              _buildAlbumArtCard(int.parse(currentSong.id)),
              const SizedBox(height: 30),
              _buildSongInfo(currentSong),
              const Spacer(),
              _buildSongProgress(),
              const SizedBox(height: 10),
              _buildMediaControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(MediaItem currentSong) {
    return GlassContainer(
      borderRadius: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              "TOCANDO AGORA",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            StreamBuilder<List<String>>(
              stream: FavoritesManager.favoritesStream,
              builder: (context, snapshot) {
                final isFav = FavoritesManager.isFavorite(currentSong.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () =>
                      FavoritesManager.toggleFavorite(currentSong.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtCard(int songId) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: const Icon(
            Icons.music_note,
            size: 80,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(MediaItem currentSong) {
    return Column(
      children: [
        Text(
          currentSong.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          currentSong.artist ?? "Artista Desconhecido",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSongProgress() {
    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        final duration = mediaItemSnapshot.data?.duration ?? Duration.zero;
        return StreamBuilder<PlaybackState>(
          stream: _audioHandler.playbackState,
          builder: (context, playbackStateSnapshot) {
            final position =
                playbackStateSnapshot.data?.updatePosition ?? Duration.zero;
            return Column(
              children: [
                Slider(
                  value: position.inMilliseconds.toDouble().clamp(
                    0.0,
                    duration.inMilliseconds.toDouble(),
                  ),
                  max: duration.inMilliseconds.toDouble() + 1.0,
                  onChanged: (value) =>
                      _audioHandler.seek(Duration(milliseconds: value.toInt())),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDuration(position),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      formatDuration(duration),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMediaControls() {
    return GlassContainer(
      borderRadius: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: StreamBuilder<PlaybackState>(
          stream: _audioHandler.playbackState,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            final processingState =
                snapshot.data?.processingState ?? AudioProcessingState.idle;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StreamBuilder<bool>(
                  stream: _audioHandler.isShufflingStream,
                  builder: (context, snapshot) {
                    final isShuffling = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: isShuffling
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        size: 28,
                      ),
                      onPressed: () => _audioHandler.setShuffleMode(
                        isShuffling
                            ? AudioServiceShuffleMode.none
                            : AudioServiceShuffleMode.all,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: _audioHandler.skipToPrevious,
                ),
                if (processingState == AudioProcessingState.loading ||
                    processingState == AudioProcessingState.buffering)
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(8.0),
                    child: const CircularProgressIndicator(color: Colors.white),
                  )
                else if (!playing)
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 60,
                    ),
                    onPressed: _audioHandler.play,
                  )
                else
                  IconButton(
                    icon: const Icon(
                      Icons.pause_circle,
                      color: Colors.white,
                      size: 60,
                    ),
                    onPressed: _audioHandler.pause,
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: _audioHandler.skipToNext,
                ),
                StreamBuilder<LoopMode>(
                  stream: _audioHandler.loopModeStream,
                  builder: (context, snapshot) {
                    final loopMode = snapshot.data ?? LoopMode.off;
                    const icons = [
                      Icons.repeat,
                      Icons.repeat_one,
                      Icons.repeat,
                    ];
                    final cycle = [
                      AudioServiceRepeatMode.none,
                      AudioServiceRepeatMode.one,
                      AudioServiceRepeatMode.all,
                    ];
                    final index = loopMode == LoopMode.off
                        ? 0
                        : (loopMode == LoopMode.one ? 1 : 2);
                    return IconButton(
                      icon: Icon(
                        icons[index],
                        color: loopMode != LoopMode.off
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        final nextIndex = (index + 1) % cycle.length;
                        _audioHandler.setRepeatMode(cycle[nextIndex]);
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDraggablePlaylist() {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.7,
      builder: (BuildContext context, ScrollController scrollController) {
        return GlassContainer(
          borderRadius: 25,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.speaker_group,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _audioOutputName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                StreamBuilder<List<MediaItem>>(
                  stream: _audioHandler.queue,
                  builder: (context, snapshot) {
                    final queue = snapshot.data ?? [];
                    final currentMediaItem = _audioHandler.mediaItem.value;
                    if (queue.isEmpty) return const SizedBox.shrink();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final mediaItem = queue[index];
                        final bool isPlaying =
                            mediaItem.id == currentMediaItem?.id;
                        return ListTile(
                          leading: QueryArtworkWidget(
                            id: int.parse(mediaItem.id),
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Icon(
                              Icons.music_note,
                              color: isPlaying
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white70,
                            ),
                          ),
                          title: Text(
                            mediaItem.title,
                            style: TextStyle(
                              color: isPlaying
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              fontWeight: isPlaying
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            mediaItem.artist ?? "Desconhecido",
                            style: TextStyle(
                              color: isPlaying
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha(200)
                                  : Colors.white70,
                            ),
                            maxLines: 1,
                          ),
                          onTap: () => _audioHandler.skipToQueueItem(index),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
