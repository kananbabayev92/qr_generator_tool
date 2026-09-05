import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_item.dart';

/// StorageService sinfi QR kodların yerli yaddaşda (local storage)
/// saxlanılması və idarə edilməsinə cavabdehdir.
/// ChangeNotifier interfeysi sayəsində məlumat dəyişdikdə UI avtomatik yenilənə bilir.
class StorageService extends ChangeNotifier {
  static const String _storageKey = 'qr_history_items';
  final List<QrItem> _items = [];

  List<QrItem> get items => List.unmodifiable(_items);

  // Yalnız skan edilmişləri gətirmək
  List<QrItem> get scannedItems =>
      _items.where((item) => item.isScanned).toList();

  // Yalnız yaradılmışları gətirmək
  List<QrItem> get generatedItems =>
      _items.where((item) => !item.isScanned).toList();

  // Yalnız sevimliləri gətirmək
  List<QrItem> get favoriteItems =>
      _items.where((item) => item.isFavorite).toList();

  /// Proqram açılanda yaddaşdakı məlumatları oxumaq
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _items.clear();
        for (final item in jsonList) {
          _items.add(QrItem.fromJson(item as Map<String, dynamic>));
        }
        // Ən sonuncu əlavə edilən birinci görünsün
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      } catch (e) {
        debugPrint('Storage oxunarkən xəta baş verdi: $e');
      }
    }
  }

  /// Yeni QR kodu yaddaşa əlavə etmək
  Future<void> addItem(QrItem item) async {
    // Eyni data varsa təkrar etməmək və ya ən başa çəkmək
    _items.removeWhere((i) => i.data == item.data && i.isScanned == item.isScanned);
    _items.insert(0, item);
    await _saveToDisk();
    notifyListeners();
  }

  /// Sevimli statusunu dəyişmək (toggle favorite)
  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isFavorite = !_items[index].isFavorite;
      await _saveToDisk();
      notifyListeners();
    }
  }

  /// Bir elementi silmək
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveToDisk();
    notifyListeners();
  }

  /// Bütün tarixçəni təmizləmək
  Future<void> clearAll() async {
    _items.clear();
    await _saveToDisk();
    notifyListeners();
  }

  /// SharedPreferences-ə məlumatları JSON formatında yazmaq
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}
