import 'dart:ui'; // CORREÇÃO AQUI
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

// Esta função será executada em um Isolate separado
Future<Color> _generatePaletteInIsolate(ImageProvider imageProvider) async {
  final PaletteGenerator paletteGenerator =
      await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
      );
  return paletteGenerator.vibrantColor?.color ??
      paletteGenerator.dominantColor?.color ??
      Colors.blue;
}

class ColorHelper {
  // A função principal agora usa 'compute' para chamar a função do Isolate
  static Future<Color> getDominantColor(ImageProvider imageProvider) async {
    return compute(_generatePaletteInIsolate, imageProvider);
  }
}
