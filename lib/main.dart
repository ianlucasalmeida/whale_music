import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whale_music/screens/player_screen.dart'; // Importa a tela do Player
import 'package:whale_music/theme/app_theme.dart';     // Importa o nosso tema customizado

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whale Music',
      // Aplica os temas que criamos
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // O app escolhe o tema baseado no sistema do celular
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
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    // Checa a permissão assim que o app inicia
    checkAndRequestPermissions();
  }

  // Lógica para checar e pedir permissão de acesso aos arquivos
  Future<void> checkAndRequestPermissions() async {
    var status = await Permission.audio.request();
    if (mounted) { // Garante que o widget ainda está na árvore de widgets
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Temos 2 abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Whale Music'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.music_note), text: 'Músicas'),
              Tab(icon: Icon(Icons.mic_external_on), text: 'Gravações'),
            ],
          ),
        ),
        body: _hasPermission
            ? TabBarView(
                children: [
                  // Conteúdo da Aba Músicas
                  buildMusicList(),
                  // Conteúdo da Aba Gravações
                  buildRecordingsList(),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Permissão de acesso a áudio negada.'),
                    SizedBox(height: 10),
                    Text('Por favor, conceda a permissão nas configurações do app.'),
                  ],
                ),
              ),
      ),
    );
  }

  // Widget que constrói a lista de músicas
  Widget buildMusicList() {
    return FutureBuilder<List<SongModel>>(
      // Busca as músicas usando o on_audio_query
      future: _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      builder: (context, item) {
        if (item.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (item.data == null || item.data!.isEmpty) {
          return const Center(child: Text("Nenhuma música encontrada."));
        }

        // Filtra para remover áudios do WhatsApp
        final songs = item.data!.where((song) =>
            !song.data.contains('WhatsApp/Media/WhatsApp Audio')).toList();

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              leading: QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                nullArtworkWidget: const Icon(Icons.music_note),
              ),
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist ?? "Artista Desconhecido", maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                // Ação de NAVEGAÇÃO para a tela do player
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(song: song),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Widget que vai construir a lista de gravações
  Widget buildRecordingsList() {
    // No futuro, implementaremos a lógica aqui
    return const Center(child: Text("Aqui ficará a lista de gravações."));
  }
}