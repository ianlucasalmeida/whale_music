import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorHelper {
  // Função para extrair a cor vibrante dominante de uma imagem
  static Future<Color> getDominantColor(ImageProvider imageProvider) async {
    final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
      imageProvider,
      size: const Size(100, 100),
    );

    return paletteGenerator.vibrantColor?.color ??
           paletteGenerator.dominantColor?.color ??
           Colors.blue;
  }
}