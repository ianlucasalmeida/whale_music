import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistManager {
  static const _key = 'user_playlists';

  // Estrutura: Map<NomeDaPlaylist, ListaDeIdsDasMusicas>
  static Future<Map<String, List<String>>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return {};
    
    // Decodifica o JSON salvo
    Map<String, dynamic> decoded = jsonDecode(data);
    // Converte para o tipo correto
    return decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  static Future<void> createPlaylist(String name) async {
    final playlists = await getPlaylists();
    if (!playlists.containsKey(name)) {
      playlists[name] = [];
      await _save(playlists);
    }
  }

  static Future<void> deletePlaylist(String name) async {
    final playlists = await getPlaylists();
    playlists.remove(name);
    await _save(playlists);
  }

  static Future<void> addSongToPlaylist(String playlistName, String songId) async {
    final playlists = await getPlaylists();
    if (playlists.containsKey(playlistName)) {
      if (!playlists[playlistName]!.contains(songId)) {
        playlists[playlistName]!.add(songId);
        await _save(playlists);
      }
    }
  }

  static Future<void> removeSongFromPlaylist(String playlistName, String songId) async {
    final playlists = await getPlaylists();
    if (playlists.containsKey(playlistName)) {
      playlists[playlistName]!.remove(songId);
      await _save(playlists);
    }
  }

  static Future<void> _save(Map<String, List<String>> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(playlists));
  }
}