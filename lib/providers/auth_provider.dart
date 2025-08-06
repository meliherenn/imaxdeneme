import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Durum değişkenleri
  UserInfo? _userInfo;
  bool _isLoading = false;
  String? _errorMessage;

  // Giriş bilgilerini saklamak için özel değişkenler
  String _serverUrl = '';
  String _userPassword = '';

  // Dışarıdan kontrollü erişim için getter'lar
  UserInfo? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _userInfo != null;

  // Diğer ekranlardan giriş bilgilerine erişmek için fonksiyon
  Map<String, String> getCredentials() {
    return {
      'serverUrl': _serverUrl,
      'username': _userInfo?.username ?? '',
      'password': _userPassword,
    };
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Değişikliği dinleyen widget'lara haber ver
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _apiService.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _userInfo = user;

      // Giriş bilgilerini sınıf içinde saklayalım
      _serverUrl = serverUrl;
      _userPassword = password;

      // Cihaza kalıcı olarak kaydedelim
      await _saveCredentials(serverUrl, username, password);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  Future<void> _saveCredentials(String url, String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', url);
    await prefs.setString('username', user);
    await prefs.setString('password', pass);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('serverUrl')) {
      return false;
    }

    final serverUrl = prefs.getString('serverUrl')!;
    final username = prefs.getString('username')!;
    final password = prefs.getString('password')!;

    // Kayıtlı bilgilerle giriş yapmayı dene
    return await login(serverUrl, username, password);
  }

  Future<void> logout() async {
    _userInfo = null;
    _serverUrl = '';
    _userPassword = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Cihazdaki tüm kayıtlı bilgileri temizle

    notifyListeners(); // Oturumun kapandığını dinleyen widget'lara bildir
  }
}