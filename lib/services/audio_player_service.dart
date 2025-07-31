import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_session/audio_session.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;

  AudioPlayerService() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playSong(SongModel song, List<SongModel> songList) async {
    try {
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: songList
            .map((s) => AudioSource.uri(Uri.parse(s.uri ?? '')))
            .toList(),
      );
      final initialIndex = songList.indexWhere((s) => s.id == song.id);
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: initialIndex >= 0 ? initialIndex : 0,
      );
      _audioPlayer.play();
    } catch (e) {
      print("Erro ao tocar a música: $e");
    }
  }

  void pause() => _audioPlayer.pause();
  void resume() => _audioPlayer.play();
  void seek(Duration position) => _audioPlayer.seek(position);

  // --- MÉTODO ADICIONADO ---
  // Pula para uma música específica na playlist e começa a tocar
  void seekToIndex(int index) {
    _audioPlayer.seek(Duration.zero, index: index);
    if (!_audioPlayer.playing) {
      _audioPlayer.play();
    }
  }

  void seekToNext() => _audioPlayer.seekToNext();
  void seekToPrevious() => _audioPlayer.seekToPrevious();

  Future<void> setShuffleMode(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
