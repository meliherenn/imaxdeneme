class LiveStream {
  final int num;
  final String name;
  final String streamType;
  final int streamId;
  final String? streamIcon;
  final dynamic epgChannelId; // Türü dynamic olarak değiştirdik
  final String added;
  final String categoryId;
  final int tvArchive;
  final String directSource;

  LiveStream({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    this.streamIcon,
    this.epgChannelId,
    required this.added,
    required this.categoryId,
    required this.tvArchive,
    required this.directSource,
  });

  // Bu factory constructor'ı gelen JSON verisini güvenli bir şekilde modelimize dönüştürür.
  factory LiveStream.fromJson(Map<String, dynamic> json) {
    // Güvenli sayıya çevirme fonksiyonu
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    return LiveStream(
      // Her sayısal alan için güvenli çevirme işlemini uyguluyoruz
      num: safeParseInt(json['num']),
      name: json['name'] ?? 'İsimsiz Kanal',
      streamType: json['stream_type'] ?? 'live',
      streamId: safeParseInt(json['stream_id']),
      streamIcon: json['stream_icon'],
      epgChannelId: json['epg_channel_id'], // Bu alan metin veya sayı gelebilir, olduğu gibi alıyoruz
      added: json['added'] ?? '',
      categoryId: json['category_id']?.toString() ?? '0',
      tvArchive: safeParseInt(json['tv_archive']),
      directSource: json['direct_source'] ?? '',
    );
  }
}