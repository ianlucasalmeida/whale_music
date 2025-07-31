import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const _key = 'favoriteSongs';

  // --- CORREÇÃO 1: Nome do Stream corrigido ---
  static final BehaviorSubject<List<String>> _favoritesSubject =
      BehaviorSubject<List<String>>();

  static Stream<List<String>> get favoritesStream => _favoritesSubject.stream;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    _favoritesSubject.add(favorites);
  }

  static Future<void> toggleFavorite(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = _favoritesSubject.value; // Pega o valor atual

    if (favorites.contains(songId)) {
      favorites.remove(songId);
    } else {
      favorites.add(songId);
    }
    await prefs.setStringList(_key, favorites);
    _favoritesSubject.add(List.from(favorites)); // Notifica com uma nova lista
  }

  // --- CORREÇÃO 2: A função agora é síncrona ---
  static bool isFavorite(String songId) {
    // Acessa o valor mais recente do stream diretamente
    return _favoritesSubject.value.contains(songId);
  }

  static void dispose() {
    _favoritesSubject.close();
  }
}
