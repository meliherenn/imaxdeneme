import 'dart:async';
// Uint8List için bu import gerekli
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:imaxip/models/channel_model_for_db.dart';
import 'package:imaxip/models/history_item_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/services/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screen_brightness/screen_brightness.dart';

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

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late VlcPlayerController _vlcViewController;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Durum değişkenleri
  late ChannelForDB _currentContent;
  late int? _currentIndex;
  bool _showControls = true;
  Timer? _controlsTimer;
  Timer? _progressTimer;

  // Oynatıcı kontrol değişkenleri
  double _currentVolume = 100;
  double _currentBrightness = 0.5;
  double _playbackSpeed = 1.0;
  bool _isSeeking = false;

  // Ekran en boy oranı için
  double _aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.content;
    _currentIndex = widget.currentIndex;

    _initializePlayer();
    _initializeBrightness();
  }

  void _initializePlayer() {
    _vlcViewController = VlcPlayerController.network(
      widget.streamUrl,
      hwAcc: HwAcc.disabled,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(3000),
        ]),
        subtitle: VlcSubtitleOptions([
          VlcSubtitleOptions.boldStyle(true),
          VlcSubtitleOptions.fontSize(30),
          VlcSubtitleOptions.outlineColor(VlcSubtitleColor.black),
          VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
        ]),
        http: VlcHttpOptions([
          '--http-user-agent=IMAXIP Player',
        ]),
      ),
    );

    _vlcViewController.addListener(_playerListener);

    if (widget.startPosition != null) {
      _vlcViewController.seekTo(widget.startPosition!);
    }
  }

  Future<void> _initializeBrightness() async {
    try {
      _currentBrightness = await ScreenBrightness().current;
    } catch (e) {
      print("Parlaklık alınamadı: $e");
      _currentBrightness = 0.5; // Varsayılan değer
    }
  }

  void _playerListener() {
    if (!mounted) return;

    if (_vlcViewController.value.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oynatıcı Hatası: ${_vlcViewController.value.errorDescription}')),
      );
    }

    if (_vlcViewController.value.isInitialized && _vlcViewController.value.aspectRatio != 0 && _vlcViewController.value.aspectRatio != _aspectRatio) {
      if (mounted) {
        setState(() {
          _aspectRatio = _vlcViewController.value.aspectRatio;
        });
      }
    }

    if (_vlcViewController.value.isPlaying) {
      if ((_currentContent.mediaType == 'movie' || _currentContent.mediaType == 'series') && (_progressTimer == null || !_progressTimer!.isActive)) {
        _startProgressTimer();
      }
    } else {
      _progressTimer?.cancel();
    }

    if (mounted) {
      setState(() {});
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
    final newUrl = '${credentials['serverUrl']!}/live/${credentials['username']!}/${credentials['password']!}/${_currentContent.streamId}.ts';

    _vlcViewController.setMediaFromNetwork(newUrl, autoPlay: true);
    _showControlsTemporarily();
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (!mounted || _isSeeking || !_vlcViewController.value.isPlaying) return;

    final position = _vlcViewController.value.position;
    final duration = _vlcViewController.value.duration;

    if (duration.inSeconds > 30) {
      final historyItem = HistoryItem.fromChannel(_currentContent, position, duration);
      await _dbHelper.updateHistory(historyItem);
    }
  }

  void _showControlsTemporarily() {
    if (!mounted) return;
    setState(() {
      _showControls = true;
    });
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _seekRelative(Duration duration) {
    _vlcViewController.seekTo(_vlcViewController.value.position + duration);
    _showControlsTemporarily();
  }

  // DÜZELTİLMİŞ VE TAM HALİ
  Future<void> _takeSnapshot() async {
    // 1. takeSnapshot() bir Uint8List döndürür, File değil.
    // Bu yüzden değişken türünü Uint8List olarak değiştiriyoruz.
    final Uint8List imageBytes = await _vlcViewController.takeSnapshot();

    // 2. Görüntü verisinin alınıp alınamadığını kontrol et.
    if (imageBytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hata: Anlık görüntü verisi oluşturulamadı.")),
      );
      return;
    }
    final String fileName = 'IMAXIP_Snapshot_${DateTime.now().millisecondsSinceEpoch}.png';

    // 3. Benzersiz bir dosya adı oluştur.
    // Genellikle anlık zaman damgası (timestamp) kullanmak en iyisidir.
    final result = await SaverGallery.saveImage(
      imageBytes,
      fileName: fileName,
      skipIfExists: false,
    );


    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ekran görüntüsü galeriye kaydedildi!"))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: Ekran görüntüsü kaydedilemedi. ${result.errorMessage}"))
      );
    }
  }


  @override
  void dispose() {
    _vlcViewController.removeListener(_playerListener);
    _controlsTimer?.cancel();
    _progressTimer?.cancel();
    if (_currentContent.mediaType != 'live') {
      _saveProgress();
    }
    _vlcViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: _showControlsTemporarily,
          onDoubleTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.localPosition.dx < screenWidth / 2) {
              _seekRelative(const Duration(seconds: -10));
            } else {
              _seekRelative(const Duration(seconds: 10));
            }
          },
          onVerticalDragUpdate: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 2) {
              setState(() {
                _currentBrightness -= details.delta.dy / 200;
                _currentBrightness = _currentBrightness.clamp(0.0, 1.0);
                ScreenBrightness().setScreenBrightness(_currentBrightness);
              });
            }
            else {
              setState(() {
                _currentVolume -= details.delta.dy;
                _currentVolume = _currentVolume.clamp(0, 150);
                _vlcViewController.setVolume(_currentVolume.toInt());
              });
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              VlcPlayer(
                key: ValueKey(_currentContent.streamId),
                controller: _vlcViewController,
                aspectRatio: _aspectRatio,
                placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AbsorbPointer(
                  absorbing: !_showControls,
                  child: _buildControlsOverlay(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.channelUp) {
        if (_currentContent.mediaType == 'live' && _currentIndex != null) {
          _changeChannel(_currentIndex! - 1);
          return KeyEventResult.handled;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.channelDown) {
        if (_currentContent.mediaType == 'live' && _currentIndex != null) {
          _changeChannel(_currentIndex! + 1);
          return KeyEventResult.handled;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        _togglePlayPause();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _seekRelative(const Duration(seconds: -10));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _seekRelative(const Duration(seconds: 10));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _togglePlayPause() {
    if (_vlcViewController.value.isPlaying) {
      _vlcViewController.pause();
    } else {
      _vlcViewController.play();
    }
    _showControlsTemporarily();
  }

  Widget _buildControlsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopBar(),
          _buildCenterControls(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(_currentContent.name, style: TextStyle(color: Colors.white, fontSize: 16.sp), overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return IconButton(
      icon: Icon(
        _vlcViewController.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
        color: Colors.white,
        size: 60.0,
      ),
      onPressed: _togglePlayPause,
    );
  }

  Widget _buildBottomBar() {
    if (_currentContent.mediaType == 'live') {
      return const SizedBox(height: 50);
    }

    final position = _vlcViewController.value.position;
    final duration = _vlcViewController.value.duration;

    String formatDuration(Duration d) => d.toString().split('.').first.padLeft(8, "0");

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(formatDuration(position), style: const TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    setState(() {});
                  },
                  onChangeStart: (value) {
                    setState(() { _isSeeking = true; });
                  },
                  onChangeEnd: (value) {
                    _vlcViewController.seekTo(Duration(milliseconds: value.toInt()));
                    setState(() { _isSeeking = false; });
                  },
                  activeColor: Colors.red,
                  inactiveColor: Colors.white70,
                ),
              ),
              Text(formatDuration(duration), style: const TextStyle(color: Colors.white)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_currentVolume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (_currentVolume > 0) {
                      _vlcViewController.setVolume(0);
                      _currentVolume = 0;
                    } else {
                      _vlcViewController.setVolume(100);
                      _currentVolume = 100;
                    }
                  });
                },
              ),
              PopupMenuButton<double>(
                onSelected: (speed) {
                  _vlcViewController.setPlaybackSpeed(speed);
                  setState(() => _playbackSpeed = speed);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.5, child: Text("0.5x")),
                  const PopupMenuItem(value: 1.0, child: Text("1.0x (Normal)")),
                  const PopupMenuItem(value: 1.5, child: Text("1.5x")),
                  const PopupMenuItem(value: 2.0, child: Text("2.0x")),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("${_playbackSpeed}x", style: const TextStyle(color: Colors.white)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _takeSnapshot,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) async {
    final audioTracks = await _vlcViewController.getAudioTracks();
    final subtitleTracks = await _vlcViewController.getSpuTracks();
    final activeAudioIndex = await _vlcViewController.getAudioTrack();
    final activeSubtitleIndex = await _vlcViewController.getSpuTrack();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900.withOpacity(0.9),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(child: Text("Ayarlar", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white))),
                  const Divider(color: Colors.white54),
                  if (audioTracks.length > 1) ...[
                    Text("Ses Dili", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ...audioTracks.entries.map((entry) => RadioListTile<int>(
                      title: Text(entry.value, style: const TextStyle(color: Colors.white)),
                      value: entry.key,
                      groupValue: activeAudioIndex,
                      onChanged: (value) async {
                        if (value != null) {
                          await _vlcViewController.setAudioTrack(value);
                          Navigator.pop(context);
                        }
                      },
                    )),
                    const Divider(color: Colors.white54),
                  ],
                  if (subtitleTracks.isNotEmpty) ...[
                    Text("Altyazı", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ...subtitleTracks.entries.map((entry) => RadioListTile<int>(
                      title: Text(entry.value == "Disable" ? "Kapalı" : entry.value, style: const TextStyle(color: Colors.white)),
                      value: entry.key,
                      groupValue: activeSubtitleIndex,
                      onChanged: (value) async {
                        if (value != null) {
                          await _vlcViewController.setSpuTrack(value);
                          Navigator.pop(context);
                        }
                      },
                    )),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}