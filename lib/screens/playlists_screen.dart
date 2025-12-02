import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:whale_music/main.dart'; // Para acessar o audioHandler
import 'package:whale_music/screens/player_screen.dart';
import 'package:whale_music/services/playlist_manager.dart';
import 'package:whale_music/widgets/glass_container.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  Map<String, List<String>> _playlists = {};
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() async {
    final playlists = await PlaylistManager.getPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  void _createNewPlaylist() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Nova Playlist", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Nome da playlist",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await PlaylistManager.createPlaylist(controller.text);
                _loadPlaylists();
                Navigator.pop(context);
              }
            },
            child: const Text("Criar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GlassContainer(
          borderRadius: 50,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Sob Medida", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createNewPlaylist,
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: _playlists.isEmpty
              ? const Center(child: Text("Nenhuma playlist criada.", style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: _playlists.keys.length,
                  itemBuilder: (context, index) {
                    String name = _playlists.keys.elementAt(index);
                    List<String> songIds = _playlists[name]!;
                    
                    return ListTile(
                      leading: GlassContainer(
                        borderRadius: 8,
                        child: Container(
                          width: 50, height: 50,
                          child: const Icon(Icons.queue_music, color: Colors.white),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${songIds.length} músicas", style: const TextStyle(color: Colors.white70)),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () async {
                          if (songIds.isEmpty) return;
                          // Busca as músicas reais pelos IDs
                          List<SongModel> allSongs = await _audioQuery.querySongs();
                          List<SongModel> playlistSongs = allSongs.where((s) => songIds.contains(s.id.toString())).toList();
                          
                          if (playlistSongs.isNotEmpty) {
                            audioHandler.loadPlaylist(playlistSongs);
                            audioHandler.skipToQueueItem(0);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(audioHandler: audioHandler)));
                          }
                        },
                      ),
                      onLongPress: () async {
                        await PlaylistManager.deletePlaylist(name);
                        _loadPlaylists();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}