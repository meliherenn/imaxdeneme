
class UserInfo {
  final String username;
  final String password;
  final String message;
  final int auth;
  final String status;
  final String expDate;
  final bool isTrial;
  final int maxConnections;

  UserInfo({
    required this.username,
    required this.password,
    required this.message,
    required this.auth,
    required this.status,
    required this.expDate,
    required this.isTrial,
    required this.maxConnections,
  });

  // JSON'dan UserInfo nesnesi oluşturan factory constructor
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // Sunucudan gelen 'exp_date' null veya 'null' string olabilir, kontrol edelim.
    var expDateRaw = json['exp_date'];
    String expDateString = "N/A";
    if (expDateRaw != null) {
      // Bazen 0 olarak gelebilir, bunu da kontrol edelim.
      if (expDateRaw is int && expDateRaw == 0) {
        expDateString = "Süresiz";
      } else {
        // Unix timestamp'i normal tarihe çevirelim.
        try {
          final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(expDateRaw.toString()) * 1000);
          expDateString = "${dt.day}.${dt.month}.${dt.year}";
        } catch (e) {
          expDateString = "Geçersiz Tarih";
        }
      }
    }

    return UserInfo(
      username: json['username'] ?? 'Bilinmiyor',
      password: json['password'] ?? '',
      message: json['message'] ?? '',
      auth: json['auth'] ?? 0,
      status: json['status'] ?? 'Aktif Değil',
      expDate: expDateString,
      isTrial: json['is_trial'] == '1',
      maxConnections: int.tryParse(json['max_connections'] ?? '0') ?? 0,
    );
  }
}