import 'dart:convert';

class EpgItemModel {
  final String title;
  final DateTime start;
  final DateTime end;
  final String description;

  EpgItemModel({
    required this.title,
    required this.start,
    required this.end,
    required this.description,
  });

  factory EpgItemModel.fromJson(Map<String, dynamic> json) {
    // Base64 formatındaki metni normal metne çeviren yardımcı fonksiyon
    String _decodeBase64(String str) {
      try {
        // Gelen metin Base64 değilse veya hatalıysa, olduğu gibi geri döndür
        return utf8.decode(base64.decode(str.trim()));
      } catch (e) {
        return str; // Hata olursa orijinal metni kullan
      }
    }

    // Zaman damgalarını (timestamp) DateTime nesnesine çevir
    DateTime _parseTimestamp(String timestamp) {
      // Örnek format: "2024-07-18 12:00:00 +0300"
      // Bazen +0300 kısmı olmayabilir, bunu kontrol edelim
      try {
        if (timestamp.contains(' +')) {
          final parts = timestamp.split(' +');
          return DateTime.parse(parts[0]);
        }
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now(); // Hata olursa şimdiki zamanı kullan
      }
    }

    return EpgItemModel(
      title: _decodeBase64(json['title'] ?? 'Program Bilgisi Yok'),
      start: _parseTimestamp(json['start'] ?? ''),
      end: _parseTimestamp(json['end'] ?? ''),
      description: _decodeBase64(json['description'] ?? ''),
    );
  }
}