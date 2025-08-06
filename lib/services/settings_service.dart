import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // Ayarları saklamak için kullanacağımız anahtarlar (keys)
  static const String _audioLangKey = 'preferred_audio_language';
  static const String _subtitleLangKey = 'preferred_subtitle_language';
  static const String _categoryViewKey = 'category_view_preference';

  // --- Ses Dili Tercihleri ---

  /// Tercih edilen ses dilini kaydeder.
  Future<void> setPreferredAudioLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioLangKey, languageCode);
  }

  /// Kayıtlı ses dilini getirir.
  Future<String?> getPreferredAudioLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_audioLangKey);
  }

  // --- Altyazı Dili Tercihleri ---

  /// Tercih edilen altyazı dilini kaydeder.
  Future<void> setPreferredSubtitleLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleLangKey, languageCode);
  }

  /// Kayıtlı altyazı dilini getirir.
  Future<String?> getPreferredSubtitleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleLangKey);
  }

  // --- Kategori Görünümü Tercihleri ---

  /// Tercih edilen kategori görünümünü kaydeder ('list' veya 'grid').
  Future<void> setPreferredCategoryView(String viewType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoryViewKey, viewType);
  }

  /// Kayıtlı kategori görünümünü getirir.
  Future<String> getPreferredCategoryView() async {
    final prefs = await SharedPreferences.getInstance();
    // Eğer daha önce bir tercih kaydedilmemişse, varsayılan olarak 'list' görünümünü döndürür.
    return prefs.getString(_categoryViewKey) ?? 'list';
  }
}