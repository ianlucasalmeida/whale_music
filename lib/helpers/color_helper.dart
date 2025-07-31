import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorHelper {
  // Versão estável que roda na thread principal
  static Future<Color> getDominantColor(ImageProvider imageProvider) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(
          imageProvider,
          size: const Size(100, 100), // Tamanho pequeno para análise rápida
        );
    return paletteGenerator.vibrantColor?.color ??
        paletteGenerator.dominantColor?.color ??
        Colors.blue; // Cor padrão
  }
}
