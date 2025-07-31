import 'package:flutter/material.dart';
import 'package:whale_music/screens/favorites_screen.dart';
import 'package:whale_music/screens/settings_screen.dart';
import 'package:whale_music/services/audio_handler.dart';

class AppDrawer extends StatelessWidget {
  // Declara que o AppDrawer precisa de um audioHandler
  final MyAudioHandler audioHandler;

  const AppDrawer({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
                  // Usa o audioHandler que foi recebido
                  builder: (context) =>
                      FavoritesScreen(audioHandler: audioHandler),
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
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
