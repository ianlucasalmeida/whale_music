import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static const _key = 'useDynamicColor';

  // Stream para que a UI possa ouvir a mudança em tempo real.
  // Inicia com 'true' (ligado) por padrão.
  static final BehaviorSubject<bool> _dynamicColorSubject =
      BehaviorSubject<bool>.seeded(true);

  static Stream<bool> get dynamicColorStream => _dynamicColorSubject.stream;
  static bool get useDynamicColor => _dynamicColorSubject.value;

  // Carrega a configuração salva no dispositivo.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Se não houver nada salvo, o padrão é 'true'.
    final useDynamic = prefs.getBool(_key) ?? true;
    _dynamicColorSubject.add(useDynamic);
  }

  // Alterna a configuração e salva no dispositivo.
  static Future<void> toggleDynamicColor() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_dynamicColorSubject.value;
    await prefs.setBool(_key, newValue);
    _dynamicColorSubject.add(newValue);
  }
}
