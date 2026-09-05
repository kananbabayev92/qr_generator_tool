/// Təhlükə dərəcələri
enum ThreatLevel {
  safe,        // Təhlükəsiz
  suspicious,  // Şübhəli (məs: qısaldılmış link, şifrələnməmiş http, birbaşa IP)
  dangerous,   // Təhlükəli (zərərli proqram .apk, .exe, skriptlər, zərərli payload)
}

/// Təhlükəsizlik analizi nəticəsi
class SecurityAuditResult {
  final ThreatLevel level;
  final String title;
  final String description;
  final List<String> warnings;
  final bool isExecutableMalware;
  final bool isBlocked;

  const SecurityAuditResult({
    required this.level,
    required this.title,
    required this.description,
    this.warnings = const [],
    this.isExecutableMalware = false,
    this.isBlocked = false,
  });

  bool get isSafe => level == ThreatLevel.safe;
  bool get isSuspicious => level == ThreatLevel.suspicious;
  bool get isDangerous => level == ThreatLevel.dangerous;
}

/// SecurityService - QR kodlar üçün hərtərəfli təhlükəsizlik auditi və mühafizə xidməti.
/// Zərərli proqramların (.apk, .exe və s.) QR koda çevrilməsini və zərərli skriptləri aşkarlayır.
class SecurityService {
  // QR kodun maksimum təhlükəsiz simvol limiti (DoS və daşmanın qarşısını almaq üçün)
  static const int maxSafeLength = 2953;

  // İcra edilə bilən zərərli proqram və təhlükəli fayl uzantıları
  static const Set<String> executableExtensions = {
    'apk',   // Android paketi
    'exe',   // Windows icra faylı
    'bat',   // Batch faylı
    'cmd',   // Windows əmr faylı
    'msi',   // Windows quraşdırıcı
    'vbs',   // VBScript
    'vbe',   // VBScript encoded
    'js',    // JavaScript faylı
    'jse',   // JScript encoded
    'wsf',   // Windows Script File
    'wsh',   // Windows Script Host
    'ps1',   // PowerShell skripti
    'sh',    // Linux shell skripti
    'bash',  // Bash skripti
    'bin',   // Binar icra faylı
    'elf',   // Linux icra faylı
    'so',    // Paylaşılan kitabxana
    'dll',   // Windows dinamik kitabxana
    'sys',   // Sistem drayveri
    'scr',   // Windows ekran qoruyucu / icra faylı
    'pif',   // Program Information File
    'hta',   // HTML Application
    'jar',   // Java arxivi
    'reg',   // Qeydiyyat faylı
    'deb',   // Debian paketi
    'rpm',   // RedHat paketi
  };

  // Bloklanan təhlükəli sxemlər
  static const Set<String> blockedSchemes = {
    'javascript',
    'vbscript',
    'data',
    'file',
    'content',
    'intent',
  };

  // URL qısaldıcı domenlər (şübhəli sayılır, çünki son ünvan gizlədilir)
  static const Set<String> urlShorteners = {
    'bit.ly',
    'tinyurl.com',
    'goo.gl',
    't.co',
    'is.gd',
    'buff.ly',
    'ow.ly',
    'cutt.ly',
    'rb.gy',
  };

  /// Məlumatın təhlükəsizlik auditini aparır
  static SecurityAuditResult analyze(String rawData) {
    final trimmed = rawData.trim();

    // 1. Boş məlumat
    if (trimmed.isEmpty) {
      return const SecurityAuditResult(
        level: ThreatLevel.safe,
        title: 'Məlumat yoxdur',
        description: 'Heç bir məlumat daxil edilməyib.',
      );
    }

    // 2. DoS / Daşma (Buffer Overflow) yoxlaması
    if (trimmed.length > maxSafeLength) {
      return SecurityAuditResult(
        level: ThreatLevel.dangerous,
        title: 'Həddindən artıq böyük məlumat',
        description: 'Məlumat $maxSafeLength simvol limitini aşır (${trimmed.length} simvol). Bu, cihazda yaddaş daşmasına səbəb ola bilər.',
        warnings: const ['Həddindən artıq uzun mətn bloklandı'],
        isBlocked: true,
      );
    }

    final lower = trimmed.toLowerCase();
    final warnings = <String>[];

    // 3. Təhlükəli URL sxemlərinin yoxlanışı (XSS / Skript inyeksiyası)
    for (final scheme in blockedSchemes) {
      if (lower.startsWith('$scheme:')) {
        return SecurityAuditResult(
          level: ThreatLevel.dangerous,
          title: 'Təhlükəli Protokol Bloklandı',
          description: '"$scheme:" sxemi tətbiq daxilində kod icrasına və ya təhlükəsizlik boşluğuna yol aça bilər.',
          warnings: ['Təhlükəli sistem/skript sxemi aşkarlandı: $scheme:'],
          isBlocked: true,
        );
      }
    }

    // 4. HTML və Skript inyeksiyası aşkarlanması
    if (lower.contains('<script') ||
        lower.contains('javascript:') ||
        lower.contains('onload=') ||
        lower.contains('onerror=') ||
        lower.contains('<iframe') ||
        lower.contains('eval(')) {
      return const SecurityAuditResult(
        level: ThreatLevel.dangerous,
        title: 'Zərərli Skript Aşkarlandı (XSS)',
        description: 'QR kodun içində icra edilə bilən zərərli skript kodu aşkar edildi. Bu kod bloklandı.',
        warnings: ['Potensial XSS və ya zərərli skript inyeksiyası'],
        isBlocked: true,
      );
    }

    // 5. İcra olunan proqram və fayl aşkarlanması (.apk, .exe və s.)
    final malwareCheck = _checkExecutableMalware(lower);
    if (malwareCheck != null) {
      return SecurityAuditResult(
        level: ThreatLevel.dangerous,
        title: 'Zərərli Proqram / İcra Faylı Aşkarlandı',
        description: malwareCheck,
        warnings: [malwareCheck],
        isExecutableMalware: true,
        isBlocked: true,
      );
    }

    // 6. Şəbəkə və URL Təhlili
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      Uri? uri;
      try {
        uri = Uri.parse(trimmed);
      } catch (_) {
        return const SecurityAuditResult(
          level: ThreatLevel.dangerous,
          title: 'Düzgün olmayan URL strukturu',
          description: 'Link strukturu zədələnib və ya maskalanıb.',
          warnings: ['Qeyri-standart URL'],
          isBlocked: true,
        );
      }

      final host = uri.host.toLowerCase();

      // Birbaşa IP ünvanı (Fişinq və ya zərərli server göstəricisi ola bilər)
      final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
      if (ipRegex.hasMatch(host)) {
        warnings.add('Link birbaşa IP ünvanına istinad edir ($host)');
      }

      // Qısaldılmış linklər
      if (urlShorteners.contains(host)) {
        warnings.add('Qısaldılmış URL ($host) - Əsl hədəf sayt gizlədilib');
      }

      // Şifrələnməmiş HTTP protokolu
      if (uri.scheme == 'http') {
        warnings.add('Şifrələnməmiş bağlantı (HTTP) - Məlumatlar üçüncü tərəflər tərəfindən izlənə bilər');
      }

      if (warnings.isNotEmpty) {
        return SecurityAuditResult(
          level: ThreatLevel.suspicious,
          title: 'Şübhəli Link Aşkarlandı',
          description: 'Bu link potensial təhlükəsizlik riski daşıyır. Keçid etməzdən əvvəl diqqətli olun.',
          warnings: warnings,
          isBlocked: false,
        );
      }
    }

    // 7. Bütün yoxlamalardan uğurla keçdi
    return const SecurityAuditResult(
      level: ThreatLevel.safe,
      title: 'Təhlükəsiz Məzmun',
      description: 'Zərərli proqram, fayl və ya şübhəli skript aşkarlanmadı.',
      warnings: [],
      isBlocked: false,
    );
  }

  /// Fayl uzantılarını yoxlayır və zərərli proqram endirmə linklərini aşkarlayır
  static String? _checkExecutableMalware(String text) {
    String target = text;
    if (text.startsWith('http://') || text.startsWith('https://')) {
      final parsed = Uri.tryParse(text);
      if (parsed != null) {
        // Domen adını deyil, sırf fayl yolunu və sorğu parametrlərini yoxlayırıq
        target = '${parsed.path} ${parsed.query}';
      }
    }

    for (final ext in executableExtensions) {
      // .apk, .apk?download=1, .exe və s.
      final pattern = RegExp(r'\.' + RegExp.escape(ext) + r'($|[\s\?\#\/\&])', caseSensitive: false);
      if (pattern.hasMatch(target)) {
        return 'Təhlükəli icra faylı/proqram aşkarlandı: .$ext faylı. Tətbiq zərərli proqramların QR koda çevrilməsinə və ya yüklənməsinə icazə vermir.';
      }
    }
    return null;
  }
}
