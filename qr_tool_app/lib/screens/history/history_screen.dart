import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/qr_item.dart';
import '../../services/action_helper.dart';
import '../../services/storage_service.dart';
import '../../widgets/qr_card.dart';

/// HistoryScreen - Bütün skan edilmiş və yaradılmış QR kodların
/// siyahısını, axtarışını, filterlənməsini və detallı baxışını təqdim edən səhifə.
class HistoryScreen extends StatefulWidget {
  final StorageService storageService;

  const HistoryScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Hamısı, 1: Skan edilənlər, 2: Yaradılanlar, 3: Sevimlilər
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Tarixçəni təmizləmək üçün təsdiq dialoqu
  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarixçəni təmizlə?'),
        content: const Text(
          'Bütün saxlanılmış QR kodlar silinəcək. Bu əməliyyatı geri qaytarmaq mümkün deyil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İmtina'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.storageService.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // Elementə toxunanda detallı baxış pəncərəsi (Bottom Sheet)
  // Elementə toxunanda detallı baxış pəncərəsi (Bottom Sheet)
  void _showItemDetailSheet(BuildContext context, QrItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Yuxarı tutacaq
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // QR Kod şəkli
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: item.data,
                      version: QrVersions.auto,
                      size: 160.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Başlıq və Mətn
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: SelectableText(
                      item.data,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Əməliyyat düymələri
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ActionHelper.performPrimaryAction(context, item);
                    },
                    icon: const Icon(Icons.launch_rounded),
                    label: const Text('İcra et / Aç'),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () =>
                              ActionHelper.copyToClipboard(context, item.data),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Kopyala'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => ActionHelper.shareText(item.data),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Paylaş'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarixçə'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Tarixçəni təmizlə',
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.storageService,
        builder: (context, child) {
          // Filterə görə siyahını seçmək
          List<QrItem> items;
          switch (_selectedFilterIndex) {
            case 1:
              items = widget.storageService.scannedItems;
              break;
            case 2:
              items = widget.storageService.generatedItems;
              break;
            case 3:
              items = widget.storageService.favoriteItems;
              break;
            default:
              items = widget.storageService.items;
          }

          // Axtarış sözünə görə filterləmək
          if (_searchQuery.isNotEmpty) {
            items = items.where((item) {
              return item.data.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  item.title.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return Column(
            children: [
              // Axtarış xanası
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tarixçədə axtar...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),

              // Filter düymələri (Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip(0, 'Hamısı'),
                    _buildFilterChip(1, 'Skan edilənlər'),
                    _buildFilterChip(2, 'Yaradılanlar'),
                    _buildFilterChip(3, 'Sevimlilər'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Nəticələr siyahısı və ya Boş vəziyyət
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: Colors.redAccent,
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              widget.storageService.deleteItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Element silindi'),
                                  action: SnackBarAction(
                                    label: 'Geri qaytar',
                                    onPressed: () {
                                      widget.storageService.addItem(item);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: QrCard(
                              item: item,
                              onTap: () => _showItemDetailSheet(context, item),
                              onFavoriteToggle: () {
                                widget.storageService.toggleFavorite(item.id);
                              },
                              onDelete: () {
                                widget.storageService.deleteItem(item.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selectedColor: Theme.of(context).colorScheme.primary,
        onSelected: (val) {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Heç bir nəticə tapılmadı'
                : 'Hələ heç bir QR kod yoxdur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'Fərqli axtarış sözü yoxlayın'
                : 'QR kod skan edin və ya yeni QR kod yaradın',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
