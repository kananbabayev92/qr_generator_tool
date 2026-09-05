import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../widgets/ontero_logo.dart';

/// SettingsScreen - Tətbiqin tənzimləmələri və haqqında məlumatlar səhifəsi.
class SettingsScreen extends StatelessWidget {
  final StorageService storageService;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const SettingsScreen({
    super.key,
    required this.storageService,
    this.onThemeModeChanged,
    this.currentThemeMode = ThemeMode.system,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tənzimləmələr'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Görünüş bölməsi
          _buildSectionHeader('GÖRÜNÜŞ & TEMA'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Görünüş rejimi'),
            subtitle: Text(_getThemeModeName(currentThemeMode)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showThemeDialog(context),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Məlumat & Yaddaş bölməsi
          _buildSectionHeader('YADDAŞ & TARİXÇƏ'),
          ListenableBuilder(
            listenable: storageService,
            builder: (context, child) {
              return ListTile(
                leading: const Icon(Icons.storage_rounded),
                title: const Text('Saxlanılmış QR kodlar'),
                subtitle: Text('${storageService.items.length} element saxlanılıb'),
                trailing: TextButton(
                  onPressed: () {
                    storageService.clearAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tarixçə təmizləndi')),
                    );
                  },
                  child: const Text('Təmizlə', style: TextStyle(color: Colors.red)),
                ),
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Təhlükəsizlik & Mühafizə bölməsi
          _buildSectionHeader('TƏHLÜKƏSİZLİK VƏ AUDİT'),
          ListTile(
            leading: const Icon(Icons.security_rounded, color: Colors.green),
            title: const Text('Zərərli Proqram Mühafizəsi'),
            subtitle: const Text('Aktiv (Zərərli fayllar və skriptlər bloklanır)'),
            trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
            onTap: () => _showSecurityReportDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Təhlükəsizlik Auditi Hesabatı'),
            subtitle: const Text('Parametrlər və audit nəticələrinə bax'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showSecurityReportDialog(context),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Haqqında bölməsi
          _buildSectionHeader('HAQQINDA'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const OnteroLogo(size: 56, showGlow: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ontero QR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Generator & Scanner',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sürətli, təhlükəsiz və çoxfunksiyalı QR & Barkod aləti',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Versiya'),
            subtitle: Text('1.0.0 (Ontero Suite)'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Məxfilik Siyasəti (Privacy Policy)'),
            subtitle: const Text('Məlumatlarınızın təhlükəsizliyi və icazələr haqqında'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistem rejimi (Avtomatik)';
      case ThemeMode.light:
        return 'Açıq rejim';
      case ThemeMode.dark:
        return 'Qaranlıq rejim';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görünüş rejimini seçin'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeTile(
              context: context,
              title: 'Sistem rejimi',
              icon: Icons.brightness_auto_rounded,
              mode: ThemeMode.system,
            ),
            _buildThemeTile(
              context: context,
              title: 'Açıq rejim',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
            ),
            _buildThemeTile(
              context: context,
              title: 'Qaranlıq rejim',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final isSelected = currentThemeMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: primaryColor)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        onThemeModeChanged?.call(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showSecurityReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Təhlükəsizlik Auditi', style: TextStyle(fontSize: 18)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tətbiq üzrə aparılmış təhlükəsizlik auditi və aktiv mühafizə parametrləri:',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              _AuditItem(
                title: 'Zərərli Proqram Filtrləməsi',
                description: '.apk, .exe, .bat, .vbs, .sh və digər 25+ icra olunan zərərli proqram fayllarının QR koda çevrilməsi və açılması tam bloklanıb.',
                isSuccess: true,
              ),
              _AuditItem(
                title: 'Skript & XSS Mühafizəsi',
                description: 'javascript:, data:, file: kimi təhlükəli sistem protokolları və skript inyeksiyaları qadağan edilib.',
                isSuccess: true,
              ),
              _AuditItem(
                title: 'Skaner Risk Təhlili',
                description: 'Skan edilən hər bir kod real-vaxt rejimində təhlil edilir və şübhəli/təhlükəli linklər barədə xəbərdarlıq verilir.',
                isSuccess: true,
              ),
              _AuditItem(
                title: 'Yaddaş və DoS Qorunması',
                description: 'QR kod generatorunda daşma və dondurma hücumlarının qarşısını almaq üçün 2953 simvol həddi tətbiq edilir.',
                isSuccess: true,
              ),
              _AuditItem(
                title: 'Lokal Məxfilik (Zero-Knowledge)',
                description: 'Bütün QR məlumatları yalnız lokal cihazda (SharedPreferences) saxlanılır, heç bir xarici serverə göndərilmir.',
                isSuccess: true,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bağla'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Məxfilik Siyasəti', style: TextStyle(fontSize: 18)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Məlumatlarınızın qorunması bizim üçün prioritetdir:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 12),
              _AuditItem(
                title: 'Kamera və Media İcazəsi',
                description: 'Kameranız yalnız real vaxtda QR kodları oxumaq üçün istifadə olunur. Heç bir görüntü və ya video yaddaşa yazılmır və ya ötürülmür.',
                isSuccess: true,
              ),
              _AuditItem(
                title: 'Lokal Emal və Yaddaş',
                description: 'Skan olunmuş və yaradılmış bütün kodlar yalnız telefonunuzun daxili yaddaşında saxlanılır. İstənilən vaxt təmizləyə bilərsiniz.',
                isSuccess: true,
              ),
              _AuditItem(
                title: 'Şəxsi Məlumatların Toplanmaması',
                description: 'Tətbiq ad, soyad, e-poçt və ya əlaqə nömrələri kimi şəxsi məlumatları toplamır və heç bir kənar serverə ötürmür.',
                isSuccess: true,
              ),
              _AuditItem(
                title: 'Reklam Tərəfdaşları',
                description: 'Tətbiqdaxili reklamların təqdim edilməsi üçün anonim cihaz identifikatorundan (Google Advertising ID) istifadə oluna bilər.',
                isSuccess: true,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bağla'),
          ),
        ],
      ),
    );
  }
}

class _AuditItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isSuccess;

  const _AuditItem({
    required this.title,
    required this.description,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
