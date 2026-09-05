import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/storage_service.dart';

void main() async {
  // Flutter mühitinin tam hazır olmasını təmin edirik
  WidgetsFlutterBinding.ensureInitialized();

  // StorageService-i initialize edirik (yaddaşdakı məlumatları oxuyuruq)
  final storageService = StorageService();
  await storageService.init();

  // Saxlanılmış tema və dil tənzimləmələrini oxuyuruq
  final prefs = await SharedPreferences.getInstance();
  final savedThemeIndex = prefs.getInt('app_theme_mode') ?? 0;
  final initialThemeMode = ThemeMode.values[savedThemeIndex];

  // Qlobal default dil: İngilis dili ('en')
  final savedLocale = prefs.getString('app_language_code') ?? 'en';
  AppStrings.setLocale(savedLocale);

  runApp(QrToolApp(
    storageService: storageService,
    initialThemeMode: initialThemeMode,
    initialLocale: savedLocale,
  ));
}

/// QrToolApp - Tətbiqin kök (Root) vidceti.
/// Burada dinamik tema dəyişməsi, dillər və açılış ekranı idarə olunur.
class QrToolApp extends StatefulWidget {
  final StorageService storageService;
  final ThemeMode initialThemeMode;
  final String initialLocale;

  const QrToolApp({
    super.key,
    required this.storageService,
    this.initialThemeMode = ThemeMode.system,
    this.initialLocale = 'en',
  });

  @override
  State<QrToolApp> createState() => _QrToolAppState();
}

class _QrToolAppState extends State<QrToolApp> {
  late ThemeMode _themeMode;
  late String _currentLocale;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _currentLocale = widget.initialLocale;
    AppStrings.setLocale(_currentLocale);
  }

  void _changeThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_mode', mode.index);
  }

  void _changeLanguage(String langCode) async {
    setState(() {
      _currentLocale = langCode;
      AppStrings.setLocale(langCode);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', langCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ontero QR - Generator & Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: SplashScreen(
        storageService: widget.storageService,
        currentThemeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
        currentLocale: _currentLocale,
        onLocaleChanged: _changeLanguage,
      ),
    );
  }
}

