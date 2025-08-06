class EpisodeModel {
  final String id; // <-- Tekrar 'id' olarak değiştirildi
  final int episodeNum;
  final String title;
  final String containerExtension;
  final Map<String, dynamic> info;

  EpisodeModel({
    required this.id, // <-- Tekrar 'id' olarak değiştirildi
    required this.episodeNum,
    required this.title,
    required this.containerExtension,
    required this.info,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    return EpisodeModel(
      id: json['id']?.toString() ?? '', // <-- Tekrar 'id' anahtarından okunuyor
      episodeNum: safeParseInt(json['episode_num']),
      title: json['title'] ?? 'Bölüm Adı Yok',
      containerExtension: json['container_extension'] ?? 'mp4',
      info: json['info'] ?? {},
    );
  }
}