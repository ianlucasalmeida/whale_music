import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:whale_music/helpers/color_helper.dart';
import 'package:whale_music/screens/player_screen.dart';
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/service_locator.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final AlbumModel album;
  const AlbumDetailsScreen({super.key, required this.album});

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final MyAudioHandler audioHandler = getIt<MyAudioHandler>();
  Color _dominantColor = Colors.blue.shade800;

  @override
  void initState() {
    super.initState();
    _updateColor();
  }

  void _updateColor() async {
    final artwork = await _audioQuery.queryArtwork(
      widget.album.id,
      ArtworkType.ALBUM,
    );
    if (artwork != null && mounted) {
      final color = await ColorHelper.getDominantColor(MemoryImage(artwork));
      setState(() {
        _dominantColor = color;
      });
    }
  }

  // Nova função para buscar outros álbuns do mesmo artista
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: _dominantColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.album.album,
                style: const TextStyle(
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
              centerTitle: true,
              background: QueryArtworkWidget(
                id: widget.album.id,
                type: ArtworkType.ALBUM,
                artworkFit: BoxFit.cover,
              ),
            ),
          ),
          FutureBuilder<List<SongModel>>(
            future: _audioQuery.queryAudiosFrom(
              AudiosFromType.ALBUM_ID,
              widget.album.id,
            ),
            builder: (context, item) {
              if (!item.hasData)
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              final songs = item.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: Text("${index + 1}"),
                    title: Text(song.title, maxLines: 1),
                    subtitle: Text(song.artist ?? "Desconhecido", maxLines: 1),
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
                  );
                }, childCount: songs.length),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Mais deste artista",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          FutureBuilder<List<AlbumModel>>(
            future: _fetchOtherAlbumsByArtist(), // Usa a nova função
            builder: (context, item) {
              if (!item.hasData)
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              final otherAlbums = item.data!;
              if (otherAlbums.isEmpty)
                return const SliverToBoxAdapter(
                  child: Center(child: Text("Nenhum outro álbum encontrado.")),
                );

              return SliverToBoxAdapter(
                child: Container(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: otherAlbums.length,
                    itemBuilder: (context, index) {
                      final otherAlbum = otherAlbums[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AlbumDetailsScreen(album: otherAlbum),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 16.0 : 8.0,
                            right: index == otherAlbums.length - 1 ? 16.0 : 8.0,
                          ),
                          child: Container(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    child: QueryArtworkWidget(
                                      id: otherAlbum.id,
                                      type: ArtworkType.ALBUM,
                                      artworkFit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    otherAlbum.album,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
