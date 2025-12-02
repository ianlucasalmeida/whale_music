import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:whale_music/main.dart';
import 'package:whale_music/screens/player_screen.dart';
import 'package:whale_music/services/playlist_manager.dart';
import 'package:whale_music/widgets/glass_container.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _allSongs = [];
  List<SongModel> _foundSongs = [];
  String _query = "";

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() async {
    _allSongs = await _audioQuery.querySongs();
  }

  void _runFilter(String enteredKeyword) {
    List<SongModel> results = [];
    if (enteredKeyword.isEmpty) {
      results = [];
    } else {
      results = _allSongs
          .where((song) =>
              song.title.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
              (song.artist?.toLowerCase().contains(enteredKeyword.toLowerCase()) ?? false))
          .toList();
    }

    setState(() {
      _foundSongs = results;
      _query = enteredKeyword;
    });
  }

  void _showAddToPlaylistDialog(SongModel song) async {
    final playlists = await PlaylistManager.getPlaylists();
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Adicionar à Playlist", style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.keys.length,
            itemBuilder: (context, index) {
              String playlistName = playlists.keys.elementAt(index);
              return ListTile(
                title: Text(playlistName, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  PlaylistManager.addSongToPlaylist(playlistName, song.id.toString());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Adicionado a $playlistName")));
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade900, Colors.black],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      Expanded(
                        child: GlassContainer(
                          borderRadius: 12,
                          child: TextField(
                            onChanged: (value) => _runFilter(value),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Buscar músicas, artistas...",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.white54),
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _query.isEmpty
                      ? const Center(child: Text("Digite para buscar", style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: _foundSongs.length,
                          itemBuilder: (context, index) {
                            final song = _foundSongs[index];
                            return ListTile(
                              leading: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white)),
                              title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1),
                              subtitle: Text(song.artist ?? "Desconhecido", style: const TextStyle(color: Colors.white70), maxLines: 1),
                              trailing: IconButton(
                                icon: const Icon(Icons.playlist_add, color: Colors.white),
                                onPressed: () => _showAddToPlaylistDialog(song),
                              ),
                              onTap: () {
                                audioHandler.loadPlaylist([song]);
                                audioHandler.skipToQueueItem(0);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(audioHandler: audioHandler)));
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}