enum QrType {
  text,
  url,
  whatsapp,
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

  // Məlumatın növünü avtomatik təyin etmək üçün köməkçi metod
  static QrType detectType(String data) {
    final lower = data.trim().toLowerCase();
    if (lower.startsWith('https://wa.me/') ||
        lower.startsWith('whatsapp://') ||
        lower.contains('api.whatsapp.com')) {
      return QrType.whatsapp;
    } else if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return QrType.url;
    } else if (lower.startsWith('wifi:')) {
      return QrType.wifi;
    } else if (lower.startsWith('mailto:')) {
      return QrType.email;
    } else if (lower.startsWith('tel:')) {
      return QrType.phone;
    } else if (lower.startsWith('smsto:') || lower.startsWith('sms:')) {
      return QrType.sms;
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
