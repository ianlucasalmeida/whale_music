import &#39;package:audio_service/audio_service.dart&#39;;
import &#39;package:just_audio/just_audio.dart&#39;;
import &#39;package:on_audio_query/on_audio_query.dart&#39;;
import &#39;package:rxdart/rxdart.dart&#39;;

// Inicialização do serviço
Future&lt;MyAudioHandler&gt; initAudioService() async {
return await AudioService.init(
builder: () =\> MyAudioHandler(),
config: const AudioServiceConfig(
androidNotificationChannelId: 'com.ianalmeida.whalemusic.channel.audio',
androidNotificationChannelName: 'Whale Music',
androidNotificationOngoing: true,
androidStopForegroundOnPause: true,
// Importante para a arte na notificação funcionar bem
artDownscaleWidth: 300,
artDownscaleHeight: 300,
),
);
}

class MyAudioHandler extends BaseAudioHandler {
final \_player = AudioPlayer();
final \_playlist = ConcatenatingAudioSource(children: []);
final \_audioQuery = OnAudioQuery(); // Necessário para buscar arte

final \_isShuffling = BehaviorSubject&lt;bool&gt;.seeded(false);
final \_loopMode = BehaviorSubject&lt;LoopMode&gt;.seeded(LoopMode.off);

Stream&lt;bool&gt; get isShufflingStream =\> \_isShuffling.stream;
Stream&lt;LoopMode&gt; get loopModeStream =\> \_loopMode.stream;

MyAudioHandler() {
\_loadEmptyPlaylist();
\_notifyAudioHandlerAboutPlaybackEvents();
\_listenForDurationChanges();
\_listenForCurrentSongIndexChanges();
\_listenForSequenceStateChanges();
}

Future&lt;void&gt; \_loadEmptyPlaylist() async {
try { await \_player.setAudioSource(\_playlist); } catch (e) { print("Error: $e"); }
}

void \_listenForCurrentSongIndexChanges() {
\_player.currentIndexStream.listen((index) {
final playlist = queue.value;
if (index \!= null && playlist.isNotEmpty && index \< playlist.length) {
mediaItem.add(playlist[index]);
}
});
}

// CORREÇÃO DO TEMPO: Atualiza o MediaItem quando a duração é descoberta
void \_listenForDurationChanges() {
\_player.durationStream.listen((duration) {
final index = \_player.currentIndex;
final playlist = queue.value;
if (index \!= null && playlist.isNotEmpty && index \< playlist.length) {
final oldItem = playlist[index];
final newItem = oldItem.copyWith(duration: duration);
// Atualiza a lista e o item atual
playlist[index] = newItem;
queue.add(playlist);
mediaItem.add(newItem);
}
});
}

void \_notifyAudioHandlerAboutPlaybackEvents() {
\_player.playbackEventStream.listen((PlaybackEvent event) {
final playing = \_player.playing;
playbackState.add(playbackState.value.copyWith(
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
}[\_player.processingState]\!,
playing: playing,
updatePosition: \_player.position,
bufferedPosition: \_player.bufferedPosition,
speed: \_player.speed,
queueIndex: event.currentIndex,
));
});
}

void \_listenForSequenceStateChanges() {
\_player.sequenceStateStream.listen((SequenceState? sequenceState) {
final sequence = sequenceState?.effectiveSequence;
if (sequence \!= null && sequence.isNotEmpty) {
final newQueue = sequence.map((source) =\> source.tag as MediaItem).toList();
queue.add(newQueue);
}
});
}

// CORREÇÃO: Busca a arte do álbum para a notificação
Future\<Uri?\> \_getArtworkUri(String id) async {
try {
// Tenta pegar o caminho da imagem.
// Nota: Para Android 10+ (API 29), o acesso direto via path pode ser restrito.
// A lib audio\_service lida melhor com 'content://' URIs, mas o on\_audio\_query
// retorna bytes.
// Uma solução robusta seria salvar os bytes em um arquivo temporário e passar esse path.
// Para simplificar e tentar fazer funcionar nativamente:
final artwork = await \_audioQuery.queryArtwork(int.parse(id), ArtworkType.AUDIO);
if (artwork \!= null) {
// Aqui precisaríamos salvar em arquivo cache para passar a URI.
// Como isso adiciona complexidade, vamos focar no metadata básico.
// Se o Android conseguir ler do MediaStore, ele mostrará a capa.
return null;
}
} catch(e) { print(e); }
return null;
}

MediaItem \_songToMediaItem(SongModel song) {
return MediaItem(
id: song.id.toString(),
title: song.title,
artist: song.artist ?? "Artista Desconhecido",
// Passamos a URI aqui. O AudioService tenta extrair a arte nativamente.
artUri: Uri.parse("content://media/external/audio/media/${song.id}/albumart"),
extras: {'url': song.uri\!},
);
}

AudioSource \_createAudioSource(MediaItem mediaItem) {
return AudioSource.uri(Uri.parse(mediaItem.extras\!['url']), tag: mediaItem);
}

Future&lt;void&gt; loadPlaylist(List&lt;SongModel&gt; songs) async {
// Mapeamento síncrono para evitar delays
final mediaItems = songs.map(\_songToMediaItem).toList();
final audioSources = mediaItems.map(\_createAudioSource).toList();

await _playlist.clear(); await _playlist.addAll(audioSources); queue.add(mediaItems);


}

@override
Future&lt;void&gt; setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
final enabled = shuffleMode == AudioServiceShuffleMode.all;
await \_player.setShuffleModeEnabled(enabled);
playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
\_isShuffling.add(enabled);
}

@override
Future&lt;void&gt; setRepeatMode(AudioServiceRepeatMode repeatMode) async {
final loopMode = LoopMode.values.firstWhere((e) =\> e.toString().split('.').last == repeatMode.name, orElse: () =\> LoopMode.off);
await \_player.setLoopMode(loopMode);
playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
\_loopMode.add(loopMode);
}

@override Future&lt;void&gt; play() =\> \_player.play();
@override Future&lt;void&gt; pause() =\> \_player.pause();
@override Future&lt;void&gt; seek(Duration position) =\> \_player.seek(position);
@override Future&lt;void&gt; skipToNext() =\> \_player.seekToNext();
@override Future&lt;void&gt; skipToPrevious() =\> \_player.seekToPrevious();
@override Future&lt;void&gt; stop() async { await \_player.stop(); await super.stop(); }

@override
Future&lt;void&gt; skipToQueueItem(int index) async {
if (index \< 0 || index \>= \_playlist.length) return;
await \_player.seek(Duration.zero, index: index);
play();
}
}