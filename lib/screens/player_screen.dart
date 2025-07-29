import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:whale_music/helpers/color_helper.dart';
import 'package:whale_music/widgets/glass_container.dart';

class PlayerScreen extends StatefulWidget {
  final SongModel song;

  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Color _dominantColor = Colors.blue.shade800;

  @override
  void initState() {
    super.initState();
    _updateBackgroundColor();
  }

  void _updateBackgroundColor() async {
    final artwork = await OnAudioQuery().queryArtwork(
      widget.song.id,
      ArtworkType.AUDIO,
      size: 400,
    );

    if (artwork != null && mounted) {
      final imageProvider = MemoryImage(artwork);
      final color = await ColorHelper.getDominantColor(imageProvider);
      setState(() {
        _dominantColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- FUNDO DINÂMICO ---
          QueryArtworkWidget(
            id: widget.song.id,
            type: ArtworkType.AUDIO,
            artworkFit: BoxFit.cover,
            nullArtworkWidget: Container(color: Colors.grey.shade800),
            // <<< CORREÇÃO AQUI: Removi width e height
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _dominantColor.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // --- CONTEÚDO DA TELA ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.song.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.song.artist ?? "Artista Desconhecido",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GlassContainer(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Column(
                        children: [
                          Slider(
                            value: 0.3,
                            onChanged: (value) {},
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 35),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next, color: Colors.white, size: 35),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}