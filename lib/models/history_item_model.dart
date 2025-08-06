import 'package:imaxip/models/channel_model_for_db.dart';

// İzleme geçmişi için model
class HistoryItem {
  final int? id;
  final int streamId;
  final String name;
  final String? streamIcon;
  final String mediaType;
  final double lastPosition;
  final double totalDuration;
  final DateTime lastWatched;
  final String? containerExtension; // EKLENEN ALAN

  HistoryItem({
    this.id,
    required this.streamId,
    required this.name,
    this.streamIcon,
    required this.mediaType,
    required this.lastPosition,
    required this.totalDuration,
    required this.lastWatched,
    this.containerExtension, // EKLENEN ALAN
  });

  // Kolayca ChannelForDB'den HistoryItem oluşturmak için
  factory HistoryItem.fromChannel(ChannelForDB channel, Duration position, Duration duration) {
    return HistoryItem(
      streamId: channel.streamId,
      name: channel.name,
      streamIcon: channel.streamIcon,
      mediaType: channel.mediaType,
      lastPosition: position.inSeconds.toDouble(),
      totalDuration: duration.inSeconds.toDouble(),
      lastWatched: DateTime.now(),
      containerExtension: channel.containerExtension, // EKLENEN ALAN
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'streamId': streamId,
      'name': name,
      'streamIcon': streamIcon,
      'mediaType': mediaType,
      'lastPosition': lastPosition,
      'totalDuration': totalDuration,
      'lastWatched': lastWatched.toIso8601String(),
      'containerExtension': containerExtension, // EKLENEN ALAN
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      streamId: map['streamId'],
      name: map['name'],
      streamIcon: map['streamIcon'],
      mediaType: map['mediaType'],
      lastPosition: map['lastPosition'],
      totalDuration: map['totalDuration'],
      lastWatched: DateTime.parse(map['lastWatched']),
      containerExtension: map['containerExtension'], // EKLENEN ALAN
    );
  }
}