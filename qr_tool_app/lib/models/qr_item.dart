enum QrType {
  text,
  url,
  whatsapp,
  instagram,
  telegram,
  youtube,
  wifi,
  email,
  phone,
  sms,
}

/// QrItem modeli generasiya olunmuş və ya skan edilmiş hər bir QR kodun
/// məlumatlarını saxlamaq üçün istifadə olunur.
class QrItem {
  final String id;
  final String data;
  final String title;
  final QrType type;
  final DateTime createdAt;
  bool isFavorite;
  final bool isScanned; // true: skan olunub, false: proqramda yaradılıb

  QrItem({
    required this.id,
    required this.data,
    required this.title,
    required this.type,
    required this.createdAt,
    this.isFavorite = false,
    required this.isScanned,
  });

  // Məlumatın növünü avtomatik və dəqiq təyin etmək üçün köməkçi metod
  static QrType detectType(String data) {
    final trimmed = data.trim();
    final lower = trimmed.toLowerCase();

    // 1. WhatsApp
    if (lower.startsWith('https://wa.me/') ||
        lower.startsWith('http://wa.me/') ||
        lower.startsWith('whatsapp://') ||
        lower.contains('api.whatsapp.com') ||
        lower.startsWith('wa.me/')) {
      return QrType.whatsapp;
    }

    // 2. Instagram
    if (lower.contains('instagram.com') || lower.startsWith('instagram://')) {
      return QrType.instagram;
    }

    // 3. Telegram
    if (lower.startsWith('https://t.me/') ||
        lower.startsWith('http://t.me/') ||
        lower.startsWith('t.me/') ||
        lower.startsWith('tg://')) {
      return QrType.telegram;
    }

    // 4. YouTube
    if (lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.startsWith('vnd.youtube:')) {
      return QrType.youtube;
    }

    // 5. Wi-Fi
    if (lower.startsWith('wifi:')) {
      return QrType.wifi;
    }

    // 6. Email
    if (lower.startsWith('mailto:') ||
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return QrType.email;
    }

    // 7. SMS
    if (lower.startsWith('smsto:') || lower.startsWith('sms:')) {
      return QrType.sms;
    }

    // 8. Telefon
    if (lower.startsWith('tel:') ||
        (RegExp(r'^\+?[0-9\s\-()]{7,18}$').hasMatch(trimmed) &&
            trimmed.replaceAll(RegExp(r'[^0-9]'), '').length >= 7 &&
            trimmed.replaceAll(RegExp(r'[^0-9]'), '').length <= 15)) {
      return QrType.phone;
    }

    // 9. Ümumi Veb və Tətbiq Linkləri
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('tiktok.com') ||
        lower.startsWith('facebook.com') ||
        lower.startsWith('fb.me') ||
        lower.startsWith('x.com') ||
        lower.startsWith('twitter.com') ||
        lower.startsWith('www.') ||
        RegExp(r'^[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}(\/.*)?$', caseSensitive: false).hasMatch(trimmed)) {
      return QrType.url;
    }

    return QrType.text;
  }

  // Modeli JSON formatına çevirmək (SharedPreferences-də saxlamaq üçün)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'title': title,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'isScanned': isScanned,
    };
  }

  // JSON formatından QrItem obyekti yaratmaq
  factory QrItem.fromJson(Map<String, dynamic> json) {
    return QrItem(
      id: json['id'] as String,
      data: json['data'] as String,
      title: json['title'] as String,
      type: QrType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QrType.text,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isScanned: json['isScanned'] as bool? ?? false,
    );
  }
}
