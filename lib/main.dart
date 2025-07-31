import 'package:flutter/material.dart';
import 'package:whale_music/screens/home_screen.dart'; // Importa a nova home_screen
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/favorites_manager.dart';
import 'package:whale_music/services/settings_manager.dart';
import 'package:whale_music/services/service_locator.dart';
import 'package:whale_music/theme/app_theme.dart';
import 'package:whale_music/widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator(); // Configura o service locator
  await FavoritesManager.init();
  await SettingsManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whale Music',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // A home agora é um widget que empilha a navegação e o mini-player
      home: const RootScreen(),
    );
  }
}

// O RootScreen gerencia a exibição do MiniPlayer sobre as outras telas
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // A HomeScreen agora é a base
          const HomeScreen(),
          // O MiniPlayer fica em cima, pegando o handler do service locator
          MiniPlayer(audioHandler: getIt<MyAudioHandler>()),
        ],
      ),
    );
  }
}
