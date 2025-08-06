class MovieModel {
  final int num;
  final String name;
  final int streamId;
  final String? streamIcon;
  final double rating;
  final String added;
  final String categoryId;
  final String containerExtension;

  MovieModel({
    required this.num,
    required this.name,
    required this.streamId,
    this.streamIcon,
    required this.rating,
    required this.added,
    required this.categoryId,
    required this.containerExtension,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    // Güvenli sayıya çevirme fonksiyonu
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    // Güvenli ondalıklı sayıya çevirme fonksiyonu
    double safeParseDouble(dynamic value) {
      if (value == null) return 0.0;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return MovieModel(
      num: safeParseInt(json['num']),
      name: json['name'] ?? 'İsimsiz Film',
      streamId: safeParseInt(json['stream_id']),
      streamIcon: json['stream_icon'],
      rating: safeParseDouble(json['rating']),
      added: json['added'] ?? '',
      categoryId: json['category_id']?.toString() ?? '0',
      containerExtension: json['container_extension'] ?? 'mp4',
    );
  }
}