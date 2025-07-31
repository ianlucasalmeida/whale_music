import 'package:get_it/get_it.dart'; // CORREÇÃO: Usava '.' em vez de ':'
import 'package:whale_music/services/audio_handler.dart';

// Cria uma instância global do GetIt
final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Registra nosso AudioHandler como uma instância única (singleton)
  // A função initAudioService() está no arquivo audio_handler.dart
  getIt.registerSingleton<MyAudioHandler>(await initAudioService());
}
