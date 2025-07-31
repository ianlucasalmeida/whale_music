import 'package:flutter/material.dart';
import 'package:whale_music/services/settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: ListView(
        children: [
          // Ouve o stream para sempre mostrar o valor correto
          StreamBuilder<bool>(
            stream: SettingsManager.dynamicColorStream,
            builder: (context, snapshot) {
              final useDynamicColor = snapshot.data ?? true;
              return SwitchListTile(
                title: const Text("Cores Dinâmicas"),
                subtitle: const Text(
                  "Muda a cor do player com base na capa do álbum.",
                ),
                value: useDynamicColor,
                onChanged: (bool value) {
                  // Ao mudar, chama o gerenciador
                  SettingsManager.toggleDynamicColor();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
