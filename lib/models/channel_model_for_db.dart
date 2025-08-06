import 'package:imaxip/models/history_item_model.dart';

class ChannelForDB {
  final int? id;
  final int streamId;
  final String name;
  final String? streamIcon;
  final String mediaType; // 'live', 'movie', 'series'
  final String? categoryId;
  final String? containerExtension;

  ChannelForDB({
    this.id,
    required this.streamId,
    required this.name,
    this.streamIcon,
    required this.mediaType,
    this.categoryId,
    this.containerExtension,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'streamId': streamId,
      'name': name,
      'streamIcon': streamIcon,
      'mediaType': mediaType,
      'categoryId': categoryId,
      'containerExtension': containerExtension,
    };
  }

  factory ChannelForDB.fromMap(Map<String, dynamic> map) {
    return ChannelForDB(
      id: map['id'],
      streamId: map['streamId'],
      name: map['name'],
      streamIcon: map['streamIcon'],
      mediaType: map['mediaType'],
      categoryId: map['categoryId'],
      containerExtension: map['containerExtension'],
    );
  }

  // YARDIMCI METOT (DÜZENLENMİŞ HALİ)
  factory ChannelForDB.fromHistory(HistoryItem item) {
    return ChannelForDB(
      streamId: item.streamId,
      name: item.name,
      streamIcon: item.streamIcon,
      mediaType: item.mediaType,
      // HistoryItem'dan gelen doğru containerExtension'ı kullanıyoruz
      containerExtension: item.containerExtension,
    );
  }
}