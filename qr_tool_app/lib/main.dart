import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/storage_service.dart';

void main() async {
  // Flutter mühitinin tam hazır olmasını təmin edirik
  WidgetsFlutterBinding.ensureInitialized();

  // StorageService-i initialize edirik (yaddaşdakı məlumatları oxuyuruq)
  final storageService = StorageService();
  await storageService.init();

  // Saxlanılmış tema rejimini oxuyuruq
  final prefs = await SharedPreferences.getInstance();
  final savedThemeIndex = prefs.getInt('app_theme_mode') ?? 0;
  final initialThemeMode = ThemeMode.values[savedThemeIndex];

  runApp(QrToolApp(
    storageService: storageService,
    initialThemeMode: initialThemeMode,
  ));
}

/// QrToolApp - Tətbiqin kök (Root) vidceti.
/// Burada dinamik tema dəyişməsi, rənglər və açılış ekranı idarə olunur.
class QrToolApp extends StatefulWidget {
  final StorageService storageService;
  final ThemeMode initialThemeMode;

  const QrToolApp({
    super.key,
    required this.storageService,
    this.initialThemeMode = ThemeMode.system,
  });

  @override
  State<QrToolApp> createState() => _QrToolAppState();
}

class _QrToolAppState extends State<QrToolApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _changeThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_mode', mode.index);
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
      ),
    );
  }
}

