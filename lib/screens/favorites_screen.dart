import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/channel_model_for_db.dart';
import 'package:imaxip/models/series_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/player_screen.dart';
import 'package:imaxip/screens/series_info_screen.dart';
import 'package:imaxip/services/database_helper.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<ChannelForDB>> _favoritesFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _dbHelper.getAllFavorites();
    });
  }

  void _navigateToContent(ChannelForDB item) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();
    final serverUrl = credentials['serverUrl']!;
    final username = credentials['username']!;
    final password = credentials['password']!;

    if (item.mediaType == 'live') {
      final url = '$serverUrl/live/$username/$password/${item.streamId}.ts';
      final content = ChannelForDB(streamId: item.streamId, name: item.name, streamIcon: item.streamIcon, mediaType: 'live');
      Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(streamUrl: url, content: content))).then((_) => _loadFavorites());
    } else if (item.mediaType == 'movie') {
      final url = '$serverUrl/movie/$username/$password/${item.streamId}.${item.containerExtension}';
      final content = ChannelForDB(streamId: item.streamId, name: item.name, streamIcon: item.streamIcon, mediaType: 'movie', containerExtension: item.containerExtension);
      Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(streamUrl: url, content: content))).then((_) => _loadFavorites());
    } else if (item.mediaType == 'series') {
      final seriesObject = SeriesModel(
          seriesId: item.streamId,
          name: item.name,
          cover: item.streamIcon,
          categoryId: item.categoryId ?? '',
          num: 0, plot: '', cast: '', director: '', genre: '', releaseDate: '', lastModified: '', rating: 0.0, annee: 0
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => SeriesInfoScreen(series: seriesObject)))
          .then((_) => _loadFavorites());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
      ),
      body: FutureBuilder<List<ChannelForDB>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz favori eklemediniz.'));
          }

          final favorites = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 4.h), // Küçültüldü
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
              return FocusableFavoriteTile(
                item: item,
                autofocus: index == 0,
                onTap: () => _navigateToContent(item),
                onDelete: () async {
                  await _dbHelper.removeFavorite(item.streamId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.name} favorilerden kaldırıldı.')),
                  );
                  _loadFavorites();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FocusableFavoriteTile extends StatefulWidget {
  final ChannelForDB item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool autofocus;

  const FocusableFavoriteTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.autofocus = false,
  });

  @override
  State<FocusableFavoriteTile> createState() => _FocusableFavoriteTileState();
}

class _FocusableFavoriteTileState extends State<FocusableFavoriteTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String type;
    switch (widget.item.mediaType) {
      case 'live':
        icon = Icons.live_tv;
        type = "Canlı TV";
        break;
      case 'movie':
        icon = Icons.movie;
        type = "Film";
        break;
      case 'series':
        icon = Icons.tv;
        type = "Dizi";
        break;
      default:
        icon = Icons.device_unknown;
        type = "Bilinmiyor";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: _isFocused ? Colors.blueGrey.shade800 : Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h), // Küçültüldü
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        leading: CircleAvatar(
          radius: 18.r, // Küçültüldü
          backgroundColor: Colors.grey.shade800,
          backgroundImage: (widget.item.streamIcon != null && widget.item.streamIcon!.isNotEmpty)
              ? NetworkImage(widget.item.streamIcon!)
              : null,
          onBackgroundImageError: (exception, stackTrace) {},
          child: (widget.item.streamIcon == null || widget.item.streamIcon!.isEmpty)
              ? Icon(icon, size: 14.sp, color: _isFocused ? Colors.amber : Colors.white) // Küçültüldü
              : null,
        ),
        title: Text(
          widget.item.name,
          style: TextStyle(
            fontSize: 12.sp, // Küçültüldü
            fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          type,
          style: TextStyle(fontSize: 9.sp), // Küçültüldü
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: _isFocused ? Colors.red : Colors.redAccent, size: 20.sp), // Küçültüldü
          onPressed: widget.onDelete,
        ),
        onTap: widget.onTap,
      ),
    );
  }
}