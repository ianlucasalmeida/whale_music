import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:whale_music/helpers/color_helper.dart';
import 'package:whale_music/screens/player_screen.dart';
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/service_locator.dart';
import 'package:whale_music/widgets/glass_container.dart';
import 'dart:ui';

class AlbumDetailsScreen extends StatefulWidget {
  final AlbumModel album;
  const AlbumDetailsScreen({super.key, required this.album});

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final MyAudioHandler audioHandler = getIt<MyAudioHandler>();
  Color _dominantColor = Colors.black;
  bool _isPlayingAll = false;

  @override
  void initState() {
    super.initState();
    _updateColor();
  }

  void _updateColor() async {
    final artwork = await _audioQuery.queryArtwork(
      widget.album.id,
      ArtworkType.ALBUM,
      size: 200,
    );
    if (artwork != null && mounted) {
      final color = await ColorHelper.getDominantColor(MemoryImage(artwork));
      setState(() {
        _dominantColor = color;
      });
    } else if (mounted) {
      setState(() {
        _dominantColor = Theme.of(context).colorScheme.primary;
      });
    }
  }

  Future<List<AlbumModel>> _fetchOtherAlbumsByArtist() async {
    if (widget.album.artistId == null) return [];
    final allAlbums = await _audioQuery.queryAlbums();
    return allAlbums
        .where(
          (album) =>
              album.artistId == widget.album.artistId &&
              album.id != widget.album.id,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // AppBar com fundo degradê e arte do álbum
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: Stack(
              fit: StackFit.expand,
              children: [
                // Fundo com arte do álbum borrado
                SizedBox.expand(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: QueryArtworkWidget(
                          id: widget.album.id,
                          type: ArtworkType.ALBUM,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Degradê sobreposto
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Conteúdo centralizado
                FlexibleSpaceBar(
                  title: Text(
                    widget.album.album,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(
                    bottom: 20,
                    left: 16,
                    right: 16,
                  ),
                  centerTitle: true,
                  background: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Capa do álbum com borda luminosa
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _dominantColor.withOpacity(0.6),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: QueryArtworkWidget(
                              id: widget.album.id,
                              type: ArtworkType.ALBUM,
                              artworkWidth: 280,
                              artworkHeight: 280,
                              artworkFit: BoxFit.cover,
                              nullArtworkWidget: Container(
                                width: 280,
                                height: 280,
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.album,
                                  size: 80,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Nome do artista
                        if (widget.album.artist != null)
                          Text(
                            widget.album.artist!,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Total de músicas
                        Text(
                          "${widget.album.numOfSongs} música${widget.album.numOfSongs == 1 ? '' : 's'}",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botão "Tocar Tudo"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: GlassContainer(
                borderRadius: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: TextButton.icon(
                    onPressed: () async {
                      final songs = await _audioQuery.queryAudiosFrom(
                        AudiosFromType.ALBUM_ID,
                        widget.album.id,
                      );
                      if (songs.isNotEmpty) {
                        audioHandler.loadPlaylist(songs);
                        audioHandler.play();
                        setState(() => _isPlayingAll = true);
                      }
                    },
                    icon: Icon(
                      _isPlayingAll ? Icons.pause : Icons.play_arrow,
                      color: _dominantColor,
                      size: 28,
                    ),
                    label: Text(
                      _isPlayingAll ? "PAUSAR TUDO" : "TOCAR TUDO",
                      style: TextStyle(
                        color: _dominantColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Lista de músicas
          FutureBuilder<List<SongModel>>(
            future: _audioQuery.queryAudiosFrom(
              AudiosFromType.ALBUM_ID,
              widget.album.id,
            ),
            builder: (context, item) {
              if (!item.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (item.data!.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Nenhuma música encontrada neste álbum.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                );
              }

              final songs = item.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist ?? "Desconhecido",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        audioHandler.loadPlaylist(songs);
                        audioHandler.skipToQueueItem(index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlayerScreen(audioHandler: audioHandler),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      audioHandler.loadPlaylist(songs);
                      audioHandler.skipToQueueItem(index);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlayerScreen(audioHandler: audioHandler),
                        ),
                      );
                    },
                    hoverColor: _dominantColor.withOpacity(0.2),
                    splashColor: _dominantColor.withOpacity(0.3),
                  );
                }, childCount: songs.length),
              );
            },
          ),

          // Seção "Mais deste artista"
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                "Mais deste artista",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          // Carrossel de outros álbuns
          FutureBuilder<List<AlbumModel>>(
            future: _fetchOtherAlbumsByArtist(),
            builder: (context, item) {
              if (!item.hasData) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final otherAlbums = item.data!;
              if (otherAlbums.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 90.0),
                      child: Text(
                        "Nenhum outro álbum encontrado.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: otherAlbums.length,
                    itemBuilder: (context, index) {
                      final album = otherAlbums[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AlbumDetailsScreen(album: album),
                            ),
                          );
                        },
                        child: Container(
                          width: 160,
                          margin: EdgeInsets.only(
                            right: index == otherAlbums.length - 1 ? 24 : 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Capa do álbum
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: QueryArtworkWidget(
                                  id: album.id,
                                  type: ArtworkType.ALBUM,
                                  artworkWidth: 160,
                                  artworkHeight: 160,
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(
                                      Icons.album,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Título do álbum
                              Text(
                                album.album,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Número de músicas
                              Text(
                                "${album.numOfSongs} música${album.numOfSongs == 1 ? '' : 's'}",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Espaço extra para o mini player
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}
