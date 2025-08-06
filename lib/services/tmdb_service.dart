import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/tmdb_details_model.dart';

class TmdbService {
  final String _apiKey = "45680ba7cc604b88d7684f99027e385e"; // Kendi anahtarın
  final String _baseUrl = "https://api.themoviedb.org/3";

  // Film adından hem temiz ismi hem de yılı ayıran yardımcı fonksiyon
  // Geriye bir Record döndürür: (String, String?) -> (isim, yıl)
  (String, String?) _extractNameAndYear(String name) {
    String? year;
    // Parantez içindeki 4 haneli yılı bul ve sakla
    final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(name);
    if (yearMatch != null) {
      year = yearMatch.group(1);
    }

    // Parantez içindeki yılları (örn: (2023)) kaldır
    name = name.replaceAll(RegExp(r'\(\d{4}\)'), '');
    // Köşeli parantez içindeki her şeyi (örn: [TR DUBLAJ]) kaldır
    name = name.replaceAll(RegExp(r'\[.*?\]'), '');
    // Özel karakterleri ve yaygın ekleri kaldır (büyük/küçük harf duyarsız)
    name = name.replaceAll(RegExp(r'1080p|720p|4k|tr dub|türkçe dublaj|dublaj|altyazılı', caseSensitive: false), '');
    // Başındaki ve sonundaki boşlukları temizle
    return (name.trim(), year);
  }

  // Bir içeriği adıyla arayıp detaylarını getiren GÜNCELLENMİŞ fonksiyon
  Future<TmdbDetailsModel?> fetchDetails({
    required String name,
    required String mediaType, // 'movie' veya 'tv'
  }) async {
    final (cleanedName, year) = _extractNameAndYear(name);

    // URL'yi oluştur. Eğer yıl bulunduysa, URL'ye ekle.
    var urlString = '$_baseUrl/search/$mediaType?api_key=$_apiKey&query=${Uri.encodeComponent(cleanedName)}&language=tr-TR';
    if (year != null && mediaType == 'movie') {
      urlString += '&primary_release_year=$year';
    }

    final url = Uri.parse(urlString);
    debugPrint("[TMDB] İstek URL'si: $url");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isEmpty) {
          debugPrint("[TMDB] Sonuç bulunamadı.");
          return null;
        }

        // EN AKILLI KISIM: Gelen sonuçlar arasından en popüler olanı bul
        Map<String, dynamic>? bestMatch = results.first;
        double maxPopularity = (results.first['popularity'] ?? 0.0).toDouble();

        for (var result in results) {
          final currentPopularity = (result['popularity'] ?? 0.0).toDouble();
          if (currentPopularity > maxPopularity) {
            maxPopularity = currentPopularity;
            bestMatch = result;
          }
        }

        debugPrint("[TMDB] En iyi eşleşme bulundu: ${bestMatch!['title'] ?? bestMatch['name']} (Popülerlik: $maxPopularity)");
        return TmdbDetailsModel.fromJson(bestMatch);

      }
      return null;
    } catch (e) {
      debugPrint("[TMDB] HATA: $e");
      return null;
    }
  }
}