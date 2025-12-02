import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart'; // Import necessário para a correção
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whale_music/screens/album_details_screen.dart';
import 'package:whale_music/screens/player_screen.dart';
import 'package:whale_music/theme/app_theme.dart';
import 'package:whale_music/services/audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:whale_music/services/favorites_manager.dart';
import 'package:whale_music/services/settings_manager.dart';
import 'package:whale_music/widgets/app_drawer.dart';
import 'package:whale_music/widgets/glass_container.dart';
import 'package:whale_music/widgets/mini_player.dart';

// Variável global para acesso local (se necessário)
late MyAudioHandler audioHandler;

enum HomeViewType { albums, artists, songs }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa gerenciadores
  await FavoritesManager.init();
  await SettingsManager.init(); 

  // 1. Inicializa o AudioService
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ianalmeida.whalemusic.channel.audio',
      androidNotificationChannelName: 'Whale Music',
      androidNotificationOngoing: true,
    ),
  );

  // 2. REGISTRO NO GET_IT (A CORREÇÃO)
  // Isso permite que a tela de álbuns (AlbumDetailsScreen) encontre o handler
  // sem precisar passá-lo via construtor o tempo todo.
  GetIt.instance.registerSingleton<MyAudioHandler>(audioHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whale Music',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
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
      // Busca tudo uma única vez para performance
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
      // Permite que o conteúdo fique atrás da AppBar transparente
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          SafeArea(
            // Remove o bottom padding do SafeArea para o conteúdo descer até o fim
            bottom: false, 
            child: Padding(
              // Espaço superior para a AppBar flutuante não cobrir o conteúdo
              padding: const EdgeInsets.only(top: 60.0), 
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                            child: Text(
                              "Sugestão",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildSuggestionCard()),
                        _buildViewSelector(),
                        _buildCurrentView(),
                        // Espaço extra no final para o MiniPlayer não cobrir o último item
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
            ),
          ),
          _buildFloatingAppBar(),
          MiniPlayer(audioHandler: audioHandler),
        ],
      ),
    );
  }

  Widget _buildFloatingAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GlassContainer(
            borderRadius: 50,
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  },
                ),
                const Text(
                  "Whale Music",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 8.0, 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getViewTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<HomeViewType>(
              onSelected: (HomeViewType result) {
                setState(() {
                  _currentView = result;
                });
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<HomeViewType>>[
                    const PopupMenuItem<HomeViewType>(
                      value: HomeViewType.albums,
                      child: Text('Álbuns'),
                    ),
                    const PopupMenuItem<HomeViewType>(
                      value: HomeViewType.artists,
                      child: Text('Artistas'),
                    ),
                    const PopupMenuItem<HomeViewType>(
                      value: HomeViewType.songs,
                      child: Text('Músicas'),
                    ),
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
      case HomeViewType.artists:
        return 'Artistas';
      case HomeViewType.songs:
        return 'Músicas';
      case HomeViewType.albums:
      default:
        return 'Álbuns';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case HomeViewType.artists:
        return _buildArtistList();
      case HomeViewType.songs:
        return _buildSongList();
      case HomeViewType.albums:
      default:
        return _buildAlbumGrid();
    }
  }

  Widget _buildSuggestionCard() {
    if (_songs.isEmpty) return const SizedBox.shrink();

    final allSongs = _songs
        .where((song) => !song.data.contains('WhatsApp'))
        .toList();
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

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlayerScreen(audioHandler: audioHandler),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QueryArtworkWidget(
                    id: randomSong.id,
                    type: ArtworkType.AUDIO,
                    artworkWidth: 60,
                    artworkHeight: 60,
                    nullArtworkWidget: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        randomSong.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        randomSong.artist ?? "Desconhecido",
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumGrid() {
    if (_albums.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("Nenhum álbum encontrado.")),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumDetailsScreen(album: album),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: QueryArtworkWidget(
                      id: album.id,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      size: 200,
                      quality: 75,
                      nullArtworkWidget: Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.album),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  album.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  album.artist ?? "Desconhecido",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }, childCount: _albums.length),
      ),
    );
  }

  Widget _buildSongList() {
    if (_songs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("Nenhuma música encontrada.")),
      );
    }

    final displaySongs = _songs
        .where((s) => !s.data.contains('WhatsApp'))
        .toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = displaySongs[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          leading: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const Icon(Icons.music_note),
          ),
          title: Text(song.title, maxLines: 1),
          subtitle: Text(song.artist ?? "Desconhecido", maxLines: 1),
          onTap: () {
            audioHandler.loadPlaylist(displaySongs);
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
      }, childCount: displaySongs.length),
    );
  }

  Widget _buildArtistList() {
    if (_artists.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text("Nenhum artista encontrado."),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final artist = _artists[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          leading: const Icon(Icons.person),
          title: Text(artist.artist),
          subtitle: Text(
            "${artist.numberOfAlbums} Álbuns | ${artist.numberOfTracks} Músicas",
          ),
          onTap: () async {
             // Busca as músicas do artista e toca
             List<SongModel> songs = await _audioQuery.queryAudiosFrom(
               AudiosFromType.ARTIST_ID,
               artist.id,
             );
             audioHandler.loadPlaylist(songs);
             audioHandler.skipToQueueItem(0);
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) =>
                     PlayerScreen(audioHandler: audioHandler),
               ),
             );
          },
        );
      }, childCount: _artists.length),
    );
  }
}