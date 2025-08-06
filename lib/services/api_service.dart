import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // --- GİRİŞ FONKSİYONU ---
  Future<UserInfo> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }
    final fullUrl = '$serverUrl/player_api.php?username=$username&password=$password';

    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> userData;
        if (data is List) {
          userData = data.first;
        } else {
          userData = data;
        }
        if (userData['user_info'] != null && userData['user_info']['auth'] == 1) {
          return UserInfo.fromJson(userData['user_info']);
        } else {
          throw Exception('Kullanıcı adı veya şifre hatalı.');
        }
      } else {
        throw Exception('Sunucuya bağlanılamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }

  // --- KATEGORİ FONKSİYONLARI ---
  Future<List> getLiveCategories({required String serverUrl, required String username, required String password}) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_categories';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Canlı TV kategorileri yüklenemedi.');
    }
  }

  Future<List> getVodCategories({required String serverUrl, required String username, required String password}) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_categories';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Film kategorileri yüklenemedi.');
    }
  }

  Future<List> getSeriesCategories({required String serverUrl, required String username, required String password}) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_series_categories';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Dizi kategorileri yüklenemedi.');
    }
  }

  // --- İÇERİK LİSTELEME FONKSİYONLARI ---
  Future<List> getLiveStreams({required String serverUrl, required String username, required String password, required String categoryId}) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_streams&category_id=$categoryId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      return [];
    } else {
      throw Exception('Canlı yayınlar yüklenemedi.');
    }
  }

  Future<List> getVodStreams({required String serverUrl, required String username, required String password, required String categoryId}) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_streams&category_id=$categoryId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      return [];
    } else {
      throw Exception('Filmler yüklenemedi.');
    }
  }

  Future<List> getSeries({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_series';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      return [];
    } else {
      throw Exception('Diziler yüklenemedi.');
    }
  }

  // YENİ EKLENEN METOT
  Future<List> getSeriesByCategoryId({
    required String serverUrl,
    required String username,
    required String password,
    required String categoryId,
  }) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_series&category_id=$categoryId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      return [];
    } else {
      throw Exception('Diziler yüklenemedi.');
    }
  }

  // --- ARAMA İÇİN EKLENEN YENİ FONKSİYONLAR ---
  Future<List> getAllLiveStreams({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_streams';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      return [];
    } else {
      throw Exception('Tüm canlı yayınlar yüklenemedi.');
    }
  }

  Future<List> getAllMovies({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_streams';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      return [];
    } else {
      throw Exception('Tüm filmler yüklenemedi.');
    }
  }

  // --- DETAY BİLGİ FONKSİYONU ---
  Future<Map<String, dynamic>> getSeriesInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int seriesId,
  }) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_series_info&series_id=$seriesId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('episodes')) {
        return decoded;
      } else {
        throw Exception('Bu diziye ait bölüm bilgisi bulunamadı.');
      }
    } else {
      throw Exception('Dizi bilgileri yüklenemedi: ${response.statusCode}');
    }
  }
  // --- EPG FONKSİYONU (YENİ) ---
  Future<List<dynamic>> getEpgForStream({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
  }) async {
    final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_short_epg&stream_id=$streamId';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('epg_listings') && decoded['epg_listings'] is List) {
        return decoded['epg_listings'];
      }
      return [];
    } else {
      throw Exception('EPG verisi yüklenemedi: ${response.statusCode}');
    }
  }
}