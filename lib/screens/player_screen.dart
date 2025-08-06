import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/channel_model_for_db.dart';
import 'package:imaxip/models/history_item_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/services/database_helper.dart';
import 'package:imaxip/services/settings_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

class PlayerScreen extends StatefulWidget {
  final String streamUrl;
  final ChannelForDB content;
  final Duration? startPosition;
  final List<ChannelForDB>? playlist;
  final int? currentIndex;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.content,
    this.startPosition,
    this.playlist,
    this.currentIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  Timer? _progressTimer;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SettingsService _settingsService = SettingsService();

  late StreamSubscription<Tracks> _tracksSubscription;
  late StreamSubscription<bool> _playingSubscription;

  BoxFit _boxFit = BoxFit.contain;

  late ChannelForDB _currentContent;
  late int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.content;
    _currentIndex = widget.currentIndex;
    _initializePlayer(widget.streamUrl);

    _tracksSubscription = player.stream.tracks.listen((_) => _applySavedPreferences());

    _playingSubscription = player.stream.playing.listen((playing) {
      if (playing && (_currentContent.mediaType == 'movie' || _currentContent.mediaType == 'series')) {
        if (_progressTimer == null || !_progressTimer!.isActive) {
          _startProgressTimer();
        }
      } else {
        _progressTimer?.cancel();
      }
    });
  }

  Future<void> _initializePlayer(String url) async {
    await player.open(Media(url), play: true);
    if (widget.startPosition != null) {
      await player.seek(widget.startPosition!);
    }
  }

  void _changeChannel(int newIndex) {
    if (widget.playlist == null || newIndex < 0 || newIndex >= widget.playlist!.length) {
      return;
    }

    setState(() {
      _currentIndex = newIndex;
      _currentContent = widget.playlist![newIndex];
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();
    final serverUrl = credentials['serverUrl']!;
    final username = credentials['username']!;
    final password = credentials['password']!;

    final newUrl = '$serverUrl/live/$username/$password/${_currentContent.streamId}.ts';

    print("Kanal değiştiriliyor: ${_currentContent.name}");
    player.open(Media(newUrl), play: true);
  }

  String _getTrackDisplayName(dynamic track) {
    if (track.title != null) return track.title!;
    const languageMap = {'tur': 'Türkçe', 'eng': 'English', 'deu': 'Deutsch', 'ger': 'Deutsch', 'rus': 'Русский', 'ara': 'العربية', 'fra': 'Français', 'fre': 'Français', 'spa': 'Español'};
    if (track.id == 'auto') return 'Otomatik';
    if (track.id == 'no') return 'Kapalı';
    if (track.language != null && languageMap.containsKey(track.language)) {
      return languageMap[track.language]!;
    }
    return track.language ?? track.id;
  }

  Future<void> _applySavedPreferences() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final preferredAudio = await _settingsService.getPreferredAudioLanguage();
    final preferredSubtitle = await _settingsService.getPreferredSubtitleLanguage();
    if (preferredAudio != null) {
      final audioTracks = player.state.tracks.audio;
      final targetAudioTrack = audioTracks.firstWhere((track) => track.language == preferredAudio, orElse: () => AudioTrack.no());
      if (targetAudioTrack.id != 'no') {
        await player.setAudioTrack(targetAudioTrack);
      }
    }
    if (preferredSubtitle != null) {
      final subtitleTracks = player.state.tracks.subtitle;
      final targetSubtitleTrack = subtitleTracks.firstWhere((track) => track.language == preferredSubtitle, orElse: () => SubtitleTrack.no());
      if (preferredSubtitle == 'no') {
        await player.setSubtitleTrack(SubtitleTrack.no());
      } else if (targetSubtitleTrack.id != 'no') {
        await player.setSubtitleTrack(targetSubtitleTrack);
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    final position = player.state.position;
    final duration = player.state.duration;
    if (player.state.playing && duration > const Duration(seconds: 30)) {
      final historyItem = HistoryItem.fromChannel(_currentContent, position, duration);
      await _dbHelper.updateHistory(historyItem);
    }
  }

  @override
  void dispose() {
    _tracksSubscription.cancel();
    _playingSubscription.cancel();
    _progressTimer?.cancel();
    if (_currentContent.mediaType != 'live') {
      _saveProgress();
    }
    player.dispose();
    super.dispose();
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.grey.shade900, builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        final audioTracks = player.state.tracks.audio;
        final subtitleTracks = player.state.tracks.subtitle;
        final activeAudio = player.state.track.audio;
        final activeSubtitle = player.state.track.subtitle;
        return Container(padding: EdgeInsets.all(16.w), child: ListView(shrinkWrap: true, children: [
          if (audioTracks.length > 1) ...[
            Text("Ses Dili", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ...audioTracks.where((track) => track.id != 'no').map((track) => RadioListTile<AudioTrack>(title: Text(_getTrackDisplayName(track)), value: track, groupValue: activeAudio, onChanged: (value) async {
              if (value != null) {
                await player.setAudioTrack(value);
                if(value.language != null) await _settingsService.setPreferredAudioLanguage(value.language!);
                Navigator.pop(context);
              }
            })),
            const Divider(),
          ],
          if (subtitleTracks.isNotEmpty) ...[
            Text("Altyazı", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ...subtitleTracks.map((track) => RadioListTile<SubtitleTrack>(title: Text(_getTrackDisplayName(track)), value: track, groupValue: activeSubtitle, onChanged: (value) async {
              if (value != null) {
                await player.setSubtitleTrack(value);
                final langToSave = value.id == 'no' ? 'no' : value.language;
                if(langToSave != null) await _settingsService.setPreferredSubtitleLanguage(langToSave);
                Navigator.pop(context);
              }
            })),
            const Divider(),
          ],
          Text("Ekran Boyutu", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          RadioListTile<BoxFit>(title: const Text("Ekrana Sığdır"), value: BoxFit.contain, groupValue: _boxFit, onChanged: (value) {
            if (value != null) {
              setState(() => _boxFit = value);
              this.setState(() {});
              Navigator.pop(context);
            }
          },
          ),
          RadioListTile<BoxFit>(title: const Text("Ekranı Doldur (Yakınlaştır)"), value: BoxFit.cover, groupValue: _boxFit, onChanged: (value) {
            if (value != null) {
              setState(() => _boxFit = value);
              this.setState(() {});
              Navigator.pop(context);
            }
          },
          ),
        ],
        ),
        );
      },
      );
    },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && _currentContent.mediaType == 'live') {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.channelUp) {
            if (_currentIndex != null) _changeChannel(_currentIndex! - 1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.channelDown) {
            if (_currentIndex != null) _changeChannel(_currentIndex! + 1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: MaterialVideoControlsTheme(
            normal: MaterialVideoControlsThemeData(topButtonBar: [const BackButton(color: Colors.white), const Spacer(), IconButton(icon: const Icon(Icons.settings, color: Colors.white), tooltip: 'Ayarlar', onPressed: () => _showSettingsMenu(context))]),
            fullscreen: MaterialVideoControlsThemeData(topButtonBar: [const BackButton(color: Colors.white), const Spacer(), IconButton(icon: const Icon(Icons.settings, color: Colors.white), tooltip: 'Ayarlar', onPressed: () => _showSettingsMenu(context))]),
            child: Video(
              controller: controller,
              fit: _boxFit,
              controls: MaterialVideoControls,
            ),
          ),
        ),
      ),
    );
  }
}