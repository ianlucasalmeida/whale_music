import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

// Esta função inicializa o serviço de áudio e será chamada no service_locator.dart
Future<MyAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ianalmeida.whalemusic.channel.audio',
      androidNotificationChannelName: 'Whale Music',
      androidNotificationOngoing: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  final _isShuffling = BehaviorSubject<bool>.seeded(false);
  final _loopMode = BehaviorSubject<LoopMode>.seeded(LoopMode.off);

  Stream<bool> get isShufflingStream => _isShuffling.stream;
  Stream<LoopMode> get loopModeStream => _loopMode.stream;

  MyAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  // --- CORREÇÃO AQUI ---
  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      // Adicionamos uma verificação para garantir que o índice é válido para a lista atual
      if (index != null && playlist.isNotEmpty && index < playlist.length) {
        mediaItem.add(playlist[index]);
      }
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {MediaAction.seek},
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence != null && sequence.isNotEmpty) {
        final newQueue = sequence
            .map((source) => source.tag as MediaItem)
            .toList();
        queue.add(newQueue);
      }
    });
  }

  MediaItem _songToMediaItem(SongModel song) {
    return MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? "Artista Desconhecido",
      duration: Duration(milliseconds: song.duration ?? 0),
      extras: {'url': song.uri!},
    );
  }

  AudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(Uri.parse(mediaItem.extras!['url']), tag: mediaItem);
  }

  Future<void> loadPlaylist(List<SongModel> songs) async {
    final mediaItems = songs.map(_songToMediaItem).toList();
    final audioSources = mediaItems.map(_createAudioSource).toList();

    await _playlist.clear();
    await _playlist.addAll(audioSources);
    queue.add(mediaItems);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    _isShuffling.add(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = LoopMode.values.firstWhere(
      (e) => e.toString().split('.').last == repeatMode.name,
      orElse: () => LoopMode.off,
    );
    await _player.setLoopMode(loopMode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    _loopMode.add(loopMode);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
    play();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
}
