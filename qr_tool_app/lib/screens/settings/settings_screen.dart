import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../services/storage_service.dart';
import '../../widgets/ontero_logo.dart';

/// SettingsScreen - Tətbiqin tənzimləmələri və haqqında məlumatlar səhifəsi.
class SettingsScreen extends StatelessWidget {
  final StorageService storageService;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ThemeMode currentThemeMode;
  final String currentLocale;
  final ValueChanged<String>? onLocaleChanged;

  const SettingsScreen({
    super.key,
    required this.storageService,
    this.onThemeModeChanged,
    this.currentThemeMode = ThemeMode.system,
    this.currentLocale = 'en',
    this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeLanguage = AppStrings.supportedLanguages.firstWhere(
      (lang) => lang.code == currentLocale,
      orElse: () => AppStrings.supportedLanguages.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Görünüş & Dil bölməsi
          _buildSectionHeader(context.tr('settings_section_appearance')),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(context.tr('settings_theme_mode')),
            subtitle: Text(_getThemeModeName(context, currentThemeMode)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showThemeDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(context.tr('settings_language')),
            subtitle: Text('${activeLanguage.flag}  ${activeLanguage.nativeName} (${activeLanguage.name})'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Məlumat & Yaddaş bölməsi
          _buildSectionHeader(context.tr('settings_section_storage')),
          ListenableBuilder(
            listenable: storageService,
            builder: (context, child) {
              return ListTile(
                leading: const Icon(Icons.storage_rounded),
                title: Text(context.tr('settings_saved_items')),
                subtitle: Text('${storageService.items.length} ${context.tr('settings_items_count')}'),
                trailing: TextButton(
                  onPressed: () {
                    storageService.clearAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('settings_cleared_msg'))),
                    );
                  },
                  child: Text(context.tr('settings_clear_btn'), style: const TextStyle(color: Colors.red)),
                ),
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Təhlükəsizlik & Mühafizə bölməsi
          _buildSectionHeader(context.tr('settings_section_security')),
          ListTile(
            leading: const Icon(Icons.security_rounded, color: Colors.green),
            title: Text(context.tr('settings_malware_protection')),
            subtitle: Text(context.tr('settings_malware_active')),
            trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
            onTap: () => _showSecurityReportDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(context.tr('settings_audit_report')),
            subtitle: Text(context.tr('settings_audit_report_sub')),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showSecurityReportDialog(context),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Haqqında bölməsi
          _buildSectionHeader(context.tr('settings_section_about')),
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
                        'Fast, secure and versatile QR & Barcode suite',
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
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(context.tr('settings_version')),
            subtitle: const Text('1.0.0 (Ontero Suite)'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(context.tr('settings_privacy_policy')),
            subtitle: Text(context.tr('settings_privacy_policy_sub')),
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

  String _getThemeModeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.tr('settings_theme_system');
      case ThemeMode.light:
        return context.tr('settings_theme_light');
      case ThemeMode.dark:
        return context.tr('settings_theme_dark');
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('settings_theme_dialog_title')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeTile(
              context: context,
              title: context.tr('settings_theme_system'),
              icon: Icons.brightness_auto_rounded,
              mode: ThemeMode.system,
            ),
            _buildThemeTile(
              context: context,
              title: context.tr('settings_theme_light'),
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
            ),
            _buildThemeTile(
              context: context,
              title: context.tr('settings_theme_dark'),
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language_rounded),
            const SizedBox(width: 8),
            Text(context.tr('settings_lang_dialog_title')),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppStrings.supportedLanguages.length,
            itemBuilder: (context, index) {
              final lang = AppStrings.supportedLanguages[index];
              final isSelected = currentLocale == lang.code;
              final primaryColor = Theme.of(context).colorScheme.primary;

              return ListTile(
                leading: Text(
                  lang.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  lang.nativeName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : null,
                  ),
                ),
                subtitle: Text(
                  lang.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? primaryColor.withValues(alpha: 0.8) : Colors.grey,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: primaryColor)
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  onLocaleChanged?.call(lang.code);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSecurityReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text(context.tr('sec_dialog_title'), style: const TextStyle(fontSize: 18)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('sec_dialog_intro'),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              _AuditItem(
                title: context.tr('sec_item_malware_title'),
                description: context.tr('sec_item_malware_desc'),
                isSuccess: true,
              ),
              _AuditItem(
                title: context.tr('sec_item_script_title'),
                description: context.tr('sec_item_script_desc'),
                isSuccess: true,
              ),
              _AuditItem(
                title: context.tr('sec_item_scanner_title'),
                description: context.tr('sec_item_scanner_desc'),
                isSuccess: true,
              ),
              _AuditItem(
                title: context.tr('sec_item_dos_title'),
                description: context.tr('sec_item_dos_desc'),
                isSuccess: true,
              ),
              _AuditItem(
                title: context.tr('sec_item_privacy_title'),
                description: context.tr('sec_item_privacy_desc'),
                isSuccess: true,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('settings_close')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            Text(context.tr('settings_privacy_policy'), style: const TextStyle(fontSize: 18)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data protection and privacy are our top priorities:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const _AuditItem(
                title: 'Camera Access',
                description: 'Used strictly in memory for scanning QR codes in real-time. No photos or videos are ever uploaded or saved.',
                isSuccess: true,
              ),
              const _AuditItem(
                title: 'Zero-Knowledge Storage',
                description: 'All your history and generated codes stay strictly on your local device. You can clear it anytime.',
                isSuccess: true,
              ),
              const _AuditItem(
                title: 'No Personal Data Collection',
                description: 'We do not collect your name, email, phone number, contacts or files.',
                isSuccess: true,
              ),
              const _AuditItem(
                title: 'Advertising Identifiers',
                description: 'Anonymous advertising IDs may be used strictly for measurement according to standard Google Play guidelines.',
                isSuccess: true,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('settings_close')),
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
