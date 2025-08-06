import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/channel_model_for_db.dart';
import 'package:imaxip/models/live_stream_model.dart';
import 'package:imaxip/models/movie_model.dart';
import 'package:imaxip/models/series_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/movie_info_screen.dart';
import 'package:imaxip/screens/player_screen.dart';
import 'package:imaxip/screens/series_info_screen.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  final Future<List<LiveStream>> allLiveStreamsFuture;
  final Future<List<MovieModel>> allMoviesFuture;
  final Future<List<SeriesModel>> allSeriesFuture;

  const SearchScreen({
    super.key,
    required this.allLiveStreamsFuture,
    required this.allMoviesFuture,
    required this.allSeriesFuture,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allContent = [];
  List<dynamic> _filteredContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllContent();
    _searchController.addListener(_filterContent);
  }

  Future<void> _loadAllContent() async {
    try {
      final results = await Future.wait([
        widget.allLiveStreamsFuture,
        widget.allMoviesFuture,
        widget.allSeriesFuture,
      ]);
      _allContent.addAll(results[0]);
      _allContent.addAll(results[1]);
      _allContent.addAll(results[2]);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filteredContent = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Arama için içerik yüklenirken hata: $e");
    }
  }

  void _filterContent() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredContent = [];
      });
      return;
    }
    setState(() {
      _filteredContent = _allContent.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToContent(dynamic item) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();
    final serverUrl = credentials['serverUrl']!;
    final username = credentials['username']!;
    final password = credentials['password']!;

    if (item is LiveStream) {
      final url = '$serverUrl/live/$username/$password/${item.streamId}.ts';
      final content = ChannelForDB(streamId: item.streamId, name: item.name, streamIcon: item.streamIcon, mediaType: 'live');
      Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(streamUrl: url, content: content)));
    } else if (item is MovieModel) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => MovieInfoScreen(movie: item)));
    } else if (item is SeriesModel) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SeriesInfoScreen(series: item)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Kanal, film veya dizi ara...',
            hintStyle: TextStyle(fontSize: 14.sp, color: Colors.white54),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        itemCount: _filteredContent.length,
        itemBuilder: (context, index) {
          final item = _filteredContent[index];
          return FocusableSearchResultTile(
            item: item,
            autofocus: index == 0,
            onTap: () {
              _navigateToContent(item);
            },
          );
        },
      ),
    );
  }
}

class FocusableSearchResultTile extends StatefulWidget {
  final dynamic item;
  final VoidCallback onTap;
  final bool autofocus;

  const FocusableSearchResultTile({
    super.key,
    required this.item,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<FocusableSearchResultTile> createState() => _FocusableSearchResultTileState();
}

class _FocusableSearchResultTileState extends State<FocusableSearchResultTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String type;
    String? streamIcon;

    final item = widget.item;
    if (item is LiveStream) {
      icon = Icons.live_tv;
      type = "Canlı TV";
      streamIcon = item.streamIcon;
    } else if (item is MovieModel) {
      icon = Icons.movie;
      type = "Film";
      streamIcon = item.streamIcon;
    } else if (item is SeriesModel) {
      icon = Icons.tv;
      type = "Dizi";
      streamIcon = item.cover;
    } else {
      return const SizedBox.shrink();
    }

    final hasImage = streamIcon != null && streamIcon.isNotEmpty;

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
          backgroundImage: hasImage ? NetworkImage(streamIcon) : null,
          onBackgroundImageError: hasImage ? (exception, stackTrace) {} : null,
          child: !hasImage
              ? Icon(icon, size: 14.sp, color: _isFocused ? Colors.amber : Colors.white) // Küçültüldü
              : null,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 11.sp, // Küçültüldü
            fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          type,
          style: TextStyle(fontSize: 9.sp), // Küçültüldü
        ),
        onTap: widget.onTap,
      ),
    );
  }
}