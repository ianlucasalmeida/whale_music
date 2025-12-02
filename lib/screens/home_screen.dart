import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whale_music/screens/album_details_screen.dart';
import 'package:whale_music/screens/player_screen.dart';
import 'package:whale_music/screens/search_screen.dart'; // Importa a tela de busca
import 'package:whale_music/services/audio_handler.dart';
import 'package:whale_music/services/service_locator.dart';
import 'package:whale_music/widgets/app_drawer.dart';
import 'package:whale_music/widgets/glass_container.dart';

enum HomeViewType { albums, artists, songs }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final audioHandler = getIt<MyAudioHandler>();
  HomeViewType _currentView = HomeViewType.albums;
  
  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    requestPermissionsAndFetch();
  }

  void requestPermissionsAndFetch() async {
    final status = await Permission.audio.request();
    if (status.isGranted) {
      _songs = await _audioQuery.querySongs();
      _albums = await _audioQuery.queryAlbums(sortType: AlbumSortType.ARTIST);
      _artists = await _audioQuery.queryArtists();
      if (mounted) setState(() { _isLoading = false; });
    } else {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(audioHandler: audioHandler),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GlassContainer(
          borderRadius: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- AQUI VAI O SEU LOGO ---
                // Se você adicionou o arquivo em assets/logo.png, descomente a linha abaixo:
                // Image.asset('assets/logo.png', height: 24),
                // Se não, use este ícone como placeholder:
                const Icon(Icons.music_note, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text("Whale Music", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GlassContainer(
              borderRadius: 50,
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, kToolbarHeight + 40, 16.0, 0),
                    child: Text("Sugestão", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverToBoxAdapter(child: _buildSuggestionCard()),
                _buildViewSelector(),
                _buildCurrentView(),
              ],
            ),
    );
  }
  
  // ... Resto do arquivo (widgets _buildViewSelector, _buildCurrentView, etc.)
  // (Você pode manter os mesmos que já estavam funcionando do código anterior)
  // ...
  
   Widget _buildViewSelector() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 8.0, 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_getViewTitle(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            PopupMenuButton<HomeViewType>(
              onSelected: (HomeViewType result) {
                setState(() { _currentView = result; });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<HomeViewType>>[
                const PopupMenuItem<HomeViewType>(value: HomeViewType.albums, child: Text('Álbuns')),
                const PopupMenuItem<HomeViewType>(value: HomeViewType.artists, child: Text('Artistas')),
                const PopupMenuItem<HomeViewType>(value: HomeViewType.songs, child: Text('Músicas')),
              ],
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  String _getViewTitle() {
    switch (_currentView) {
      case HomeViewType.artists: return 'Artistas';
      case HomeViewType.songs: return 'Músicas';
      case HomeViewType.albums:
      default: return 'Álbuns';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case HomeViewType.artists: return _buildArtistList();
      case HomeViewType.songs: return _buildSongList();
      case HomeViewType.albums:
      default: return _buildAlbumGrid();
    }
  }

  Widget _buildSuggestionCard() {
    if (_songs.isEmpty) return const SizedBox.shrink();
    final allSongs = _songs.where((song) => !song.data.contains('WhatsApp')).toList();
    if (allSongs.isEmpty) return const SizedBox.shrink();
    final randomSong = allSongs[Random().nextInt(allSongs.length)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await audioHandler.loadPlaylist(allSongs);
            await audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
            final songIndex = allSongs.indexWhere((s) => s.id == randomSong.id);
            if (songIndex != -1) audioHandler.skipToQueueItem(songIndex);
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(audioHandler: audioHandler)));
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QueryArtworkWidget(id: randomSong.id, type: ArtworkType.AUDIO, artworkWidth: 60, artworkHeight: 60, nullArtworkWidget: Container(width: 60, height: 60, color: Colors.grey.shade800, child: const Icon(Icons.music_note))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(randomSong.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(randomSong.artist ?? "Desconhecido", style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill, size: 30)
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlbumGrid() {
    if (_albums.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text("Nenhum álbum encontrado.")));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 90.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final album = _albums[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumDetailsScreen(album: album)));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: QueryArtworkWidget(id: album.id, type: ArtworkType.ALBUM, artworkFit: BoxFit.cover, size: 200, quality: 75, nullArtworkWidget: Container(color: Colors.grey.shade800, child: const Icon(Icons.album))),
                  ),
                ),
                const SizedBox(height: 8),
                Text(album.album, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(album.artist ?? "Desconhecido", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }, childCount: _albums.length),
      ),
    );
  }

  Widget _buildSongList() {
    if (_songs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text("Nenhuma música encontrada.")));
    final displaySongs = _songs.where((s) => !s.data.contains('WhatsApp')).toList();
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 90.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final song = displaySongs[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            leading: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
            title: Text(song.title, maxLines: 1),
            subtitle: Text(song.artist ?? "Desconhecido", maxLines: 1),
            onTap: () {
              audioHandler.loadPlaylist(displaySongs);
              audioHandler.skipToQueueItem(index);
              Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(audioHandler: audioHandler)));
            },
          );
        }, childCount: displaySongs.length),
      ),
    );
  }

  Widget _buildArtistList() {
    if (_artists.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text("Nenhum artista encontrado.")));
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 90.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final artist = _artists[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            leading: const Icon(Icons.person),
            title: Text(artist.artist),
            subtitle: Text("${artist.numberOfAlbums} Álbuns | ${artist.numberOfTracks} Músicas"),
            onTap: () async {
              List<SongModel> songs = await _audioQuery.queryAudiosFrom(AudiosFromType.ARTIST_ID, artist.id);
              audioHandler.loadPlaylist(songs);
              audioHandler.skipToQueueItem(0);
              Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(audioHandler: audioHandler)));
            },
          );
        }, childCount: _artists.length),
      ),
    );
  }
}