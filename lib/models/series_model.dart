class SeriesModel {
  final int num;
  final String name;
  final int seriesId;
  final String? cover;
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final String lastModified;
  final double rating;
  final int annee;
  final String categoryId; // <-- EKLENEN SATIR

  SeriesModel({
    required this.num,
    required this.name,
    required this.seriesId,
    this.cover,
    required this.plot,
    required this.cast,
    required this.director,
    required this.genre,
    required this.releaseDate,
    required this.lastModified,
    required this.rating,
    required this.annee,
    required this.categoryId, // <-- EKLENEN SATIR
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    double safeParseDouble(dynamic value) {
      if (value == null) return 0.0;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return SeriesModel(
      num: json['num'] ?? 0,
      name: json['name'] ?? 'İsimsiz Dizi',
      seriesId: json['series_id'] ?? 0,
      cover: json['cover'],
      plot: json['plot'] ?? 'Açıklama yok.',
      cast: json['cast'] ?? 'Bilinmiyor',
      director: json['director'] ?? 'Bilinmiyor',
      genre: json['genre'] ?? 'Bilinmiyor',
      releaseDate: json['releaseDate'] ?? 'Bilinmiyor',
      lastModified: json['last_modified'] ?? '',
      rating: safeParseDouble(json['rating']),
      annee: json['year'] ?? 0,
      // API'den gelen category_id'yi modele ekliyoruz.
      categoryId: json['category_id']?.toString() ?? '0', // <-- EKLENEN SATIR
    );
  }
}