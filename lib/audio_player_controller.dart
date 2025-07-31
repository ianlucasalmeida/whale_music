import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioPlayerController {
  final AudioPlayer _audioPlayer = AudioPlayer();
  SongModel? _currentSong;

  SongModel? get currentSong => _currentSong;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Future<void> playSong(SongModel song, List<SongModel> songList) async {
    _currentSong = song;
    try {
      final playlist = ConcatenatingAudioSource(
        children: songList
            .map((s) => AudioSource.uri(Uri.parse(s.data)))
            .toList(),
      );
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: songList.indexOf(song),
      );
      _audioPlayer.play();
    } catch (e) {
      print("Erro ao tocar a música: $e");
    }
  }

  void play() {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
    _currentSong = null;
  }

  void next() {
    _audioPlayer.seekToNext();
  }

  void previous() {
    _audioPlayer.seekToPrevious();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
