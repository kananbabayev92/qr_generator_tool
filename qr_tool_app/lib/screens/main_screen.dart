import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../services/storage_service.dart';
import '../widgets/ad_banner_widget.dart';
import 'generator/generator_screen.dart';
import 'history/history_screen.dart';
import 'scanner/scanner_screen.dart';
import 'settings/settings_screen.dart';

/// MainScreen - Tətbiqin əsas naviqasiya strukturu.
/// NavigationBar vasitəsilə 4 əsas səhifə arasında keçidi təmin edir:
/// 1. Skaner (ScannerScreen)
/// 2. Generator (GeneratorScreen)
/// 3. Tarixçə (HistoryScreen)
/// 4. Tənzimləmələr (SettingsScreen)
class MainScreen extends StatefulWidget {
  final StorageService storageService;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ThemeMode currentThemeMode;
  final String currentLocale;
  final ValueChanged<String>? onLocaleChanged;

  const MainScreen({
    super.key,
    required this.storageService,
    this.onThemeModeChanged,
    this.currentThemeMode = ThemeMode.system,
    this.currentLocale = 'en',
    this.onLocaleChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ScannerScreen(storageService: widget.storageService),
      GeneratorScreen(storageService: widget.storageService),
      HistoryScreen(storageService: widget.storageService),
      SettingsScreen(
        storageService: widget.storageService,
        onThemeModeChanged: widget.onThemeModeChanged,
        currentThemeMode: widget.currentThemeMode,
        currentLocale: widget.currentLocale,
        onLocaleChanged: widget.onLocaleChanged,
      ),
    ];

    return Scaffold(
      // IndexedStack istifadə edirik ki, səhifələr arasında keçid edərkən
      // səhifələrin vəziyyəti (state) itməsin və yenidən render olunmasın.
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            selectedIcon: const Icon(Icons.qr_code_scanner_rounded),
            label: context.tr('nav_scanner'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_2_rounded),
            selectedIcon: const Icon(Icons.qr_code_2_rounded),
            label: context.tr('nav_generator'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_rounded),
            selectedIcon: const Icon(Icons.history_rounded),
            label: context.tr('nav_history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: context.tr('nav_settings'),
          ),
        ],
      ),
    );
  }
}
