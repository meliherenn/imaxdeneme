class TmdbDetailsModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;

  TmdbDetailsModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
  });

  // Afiş resminin tam URL'sini oluşturan yardımcı bir getter
  String get fullPosterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';

  // Arka plan resminin tam URL'sini oluşturan yardımcı bir getter
  String get fullBackdropUrl => 'https://image.tmdb.org/t/p/w500$backdropPath';

  factory TmdbDetailsModel.fromJson(Map<String, dynamic> json) {
    return TmdbDetailsModel(
      id: json['id'] ?? 0,
      // Diziler 'name', filmler 'title' anahtarını kullanır. İkisini de kontrol edelim.
      title: json['title'] ?? json['name'] ?? 'Başlık Yok',
      overview: json['overview'] ?? 'Açıklama mevcut değil.',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
    );
  }
}