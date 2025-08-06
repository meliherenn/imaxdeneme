import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/live_stream_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/player_screen.dart';
import 'package:imaxip/services/api_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/channel_model_for_db.dart';
import '../models/epg_item_model.dart';
import '../services/database_helper.dart';

class ContentListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ContentListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  late Future<List<LiveStream>> _streamsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();

    _streamsFuture = _apiService.getLiveStreams(
      serverUrl: credentials['serverUrl']!,
      username: credentials['username']!,
      password: credentials['password']!,
      categoryId: widget.categoryId,
    ).then((list) => list.map((item) => LiveStream.fromJson(item)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: FutureBuilder<List<LiveStream>>(
        future: _streamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu kategoride içerik bulunamadı.'));
          }

          final streams = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];
              return EpgChannelTile(
                stream: stream,
                autofocus: index == 0,
                // Kanal değiştirme özelliği için eklenen parametreler
                streams: streams,
                currentIndex: index,
              );
            },
          );
        },
      ),
    );
  }
}

class EpgChannelTile extends StatefulWidget {
  final LiveStream stream;
  final bool autofocus;
  // Kanal değiştirme özelliği için eklenen parametreler
  final List<LiveStream> streams;
  final int currentIndex;

  const EpgChannelTile({
    super.key,
    required this.stream,
    this.autofocus = false,
    required this.streams,
    required this.currentIndex,
  });

  @override
  State<EpgChannelTile> createState() => _EpgChannelTileState();
}

class _EpgChannelTileState extends State<EpgChannelTile> {
  bool _isFavorite = false;
  bool _isFocused = false;
  late DatabaseHelper _dbHelper;
  final ApiService _apiService = ApiService();

  EpgItemModel? _currentProgram;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _checkIfFavorite();
    _loadEpgData();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkIfFavorite() async {
    final isFav = await _dbHelper.isFavorite(widget.stream.streamId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _loadEpgData() async {
    if (widget.stream.streamId == 0) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();
    try {
      final epgListings = await _apiService.getEpgForStream(serverUrl: credentials['serverUrl']!, username: credentials['username']!, password: credentials['password']!, streamId: widget.stream.streamId);
      if (epgListings.isNotEmpty && mounted) {
        final now = DateTime.now();
        final programs = epgListings.map((e) => EpgItemModel.fromJson(e)).toList();
        final currentProgram = programs.firstWhere((p) => now.isAfter(p.start) && now.isBefore(p.end), orElse: () => programs.first);
        setState(() {
          _currentProgram = currentProgram;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("EPG yüklenirken hata oluştu (Kanal: ${widget.stream.name}): $e");
    }
  }

  void _toggleFavorite() {
    final channelToSave = ChannelForDB(streamId: widget.stream.streamId, name: widget.stream.name, streamIcon: widget.stream.streamIcon, mediaType: 'live', categoryId: widget.stream.categoryId);
    if (_isFavorite) {
      _dbHelper.removeFavorite(widget.stream.streamId);
    } else {
      _dbHelper.addFavorite(channelToSave);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;
    if (_currentProgram != null) {
      final now = DateTime.now();
      final totalDuration = _currentProgram!.end.difference(_currentProgram!.start).inSeconds;
      final elapsed = now.difference(_currentProgram!.start).inSeconds;
      if (totalDuration > 0 && elapsed > 0) {
        progress = elapsed / totalDuration;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: _isFocused ? Colors.blueGrey.shade800 : Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        leading: CircleAvatar(
          radius: 18.r,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: (widget.stream.streamIcon != null && widget.stream.streamIcon!.isNotEmpty) ? NetworkImage(widget.stream.streamIcon!) : null,
          onBackgroundImageError: (exception, stackTrace) {},
          child: (widget.stream.streamIcon == null || widget.stream.streamIcon!.isEmpty) ? Text(widget.stream.name.isNotEmpty ? widget.stream.name[0].toUpperCase() : '#', style: TextStyle(fontSize: 9.sp)) : null,
        ),
        title: Text(
          widget.stream.name,
          style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: _currentProgram == null ? null : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 2.h),
          Text(
            _currentProgram!.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade400),
          ),
          SizedBox(height: 3.h),
          if(progress > 0) LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade700, color: Colors.amber, minHeight: 2.h,),
        ]),
        trailing: IconButton(
          icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.amber : Colors.grey, size: 18.sp),
          onPressed: _toggleFavorite,
        ),
        onTap: () {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final credentials = auth.getCredentials();
          final serverUrl = credentials['serverUrl']!;
          final username = credentials['username']!;
          final password = credentials['password']!;

          final url = '$serverUrl/live/$username/$password/${widget.stream.streamId}.ts';

          // PlayerScreen'in ihtiyacı olan List<ChannelForDB> formatına dönüştür
          final playlistForPlayer = widget.streams.map((s) => ChannelForDB(
              streamId: s.streamId,
              name: s.name,
              streamIcon: s.streamIcon,
              mediaType: 'live',
              categoryId: s.categoryId
          )).toList();

          // Tıklanan içeriğin doğru nesnesini al
          final contentToPlay = playlistForPlayer[widget.currentIndex];

          Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(
            streamUrl: url,
            content: contentToPlay,
            playlist: playlistForPlayer,       // Tüm listeyi gönder
            currentIndex: widget.currentIndex, // Mevcut sırayı gönder
          )));
        },
      ),
    );
  }
}