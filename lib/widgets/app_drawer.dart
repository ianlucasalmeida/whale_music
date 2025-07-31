import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:whale_music/screens/favorites_screen.dart';
import 'package:whale_music/screens/settings_screen.dart';
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/service_locator.dart';

class AppDrawer extends StatelessWidget {
  final MyAudioHandler audioHandler;
  const AppDrawer({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor:
          Colors.transparent, // Fundo transparente para o efeito de vidro
      child: ClipRRect(
        // Corta o conteúdo para aplicar o efeito de vidro
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            // Um leve gradiente para melhorar a legibilidade
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).canvasColor.withOpacity(0.3),
                  Theme.of(context).canvasColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Whale Music',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Início'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Favoritos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoritesScreen(
                          audioHandler: getIt<MyAudioHandler>(),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configurações'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
