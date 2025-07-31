import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/favorites_manager.dart';
import 'package:whale_music/screens/player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final MyAudioHandler audioHandler;
  const FavoritesScreen({super.key, required this.audioHandler});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Função para buscar e filtrar as músicas favoritas
  Future<List<SongModel>> _fetchFavoriteSongs(List<String> favoriteIds) async {
    // 1. Busca TODAS as músicas
    final allSongs = await _audioQuery.querySongs();
    // 2. Filtra a lista para conter apenas as que estão nos favoritos
    return allSongs
        .where((song) => favoriteIds.contains(song.id.toString()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Músicas Favoritas")),
      body: StreamBuilder<List<String>>(
        stream: FavoritesManager.favoritesStream,
        builder: (context, snapshot) {
          final favoriteIds = snapshot.data ?? [];
          if (favoriteIds.isEmpty) {
            return const Center(
              child: Text("Você ainda não favoritou nenhuma música."),
            );
          }

          // Usa a nova função para buscar as músicas
          return FutureBuilder<List<SongModel>>(
            future: _fetchFavoriteSongs(favoriteIds),
            builder: (context, item) {
              if (item.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (item.data == null || item.data!.isEmpty) {
                return const Center(
                  child: Text("Nenhuma música favorita encontrada."),
                );
              }
              final favoriteSongs = item.data!;
              return ListView.builder(
                itemCount: favoriteSongs.length,
                itemBuilder: (context, index) {
                  final song = favoriteSongs[index];
                  return ListTile(
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(Icons.music_note),
                    ),
                    title: Text(song.title),
                    subtitle: Text(song.artist ?? "Desconhecido"),
                    onTap: () {
                      widget.audioHandler.loadPlaylist(favoriteSongs);
                      widget.audioHandler.skipToQueueItem(index);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlayerScreen(audioHandler: widget.audioHandler),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
