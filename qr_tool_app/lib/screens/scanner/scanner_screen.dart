import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/qr_item.dart';
import '../../services/action_helper.dart';
import '../../services/security_service.dart';
import '../../services/storage_service.dart';

/// ScannerScreen - Kameradan və ya Qalereyadan seçilən şəkildən
/// QR və barkodları oxuyan müasir skaner səhifəsi.
class ScannerScreen extends StatefulWidget {
  final StorageService storageService;

  const ScannerScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    formats: const [BarcodeFormat.all],
    returnImage: false,
    autoStart: true,
  );

  late final AnimationController _animationController;
  late final Animation<double> _animation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Lazer animasiyası üçün nəzarətçi
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  // QR kod oxunduqda çağırılan funksiya
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final data = barcode.rawValue ?? barcode.displayValue;
      if (data != null && data.trim().isNotEmpty) {
        _handleScannedData(data.trim());
        break;
      }
    }
  }

  // Qalereyadan şəkil seçib skan etmək
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      final barcodeCapture = await _controller.analyzeImage(image.path);
      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        for (final barcode in barcodeCapture.barcodes) {
          final data = barcode.rawValue ?? barcode.displayValue;
          if (data != null && data.trim().isNotEmpty) {
            _handleScannedData(data.trim());
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seçilmiş şəkildə heç bir QR kod tapılmadı'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şəkil oxunarkən xəta: $e')),
        );
      }
    }
  }

  void _handleScannedData(String rawValue) {
    setState(() {
      _isProcessing = true;
    });

    final item = QrItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: rawValue,
      title: rawValue.length > 30 ? '${rawValue.substring(0, 30)}...' : rawValue,
      type: QrItem.detectType(rawValue),
      createdAt: DateTime.now(),
      isScanned: true,
    );

    widget.storageService.addItem(item);

    // Titrəmə effekti (Haptic feedback)
    HapticFeedback.mediumImpact();

    // Nəticə pəncərəsini göstər
    _showResultBottomSheet(item);
  }

  // Nəticə pəncərəsi (Bottom Sheet)
  void _showResultBottomSheet(QrItem item) {
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Yuxarı tutacaq
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Uğurlu skan ikonu və başlıq
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QR Kod Oxundu!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTypeName(item.type),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Təhlükəsizlik Auditi Kartı
              () {
                final audit = SecurityService.analyze(item.data);
                final Color cardColor;
                final Color borderColor;
                final Color textColor;
                final IconData iconData;

                if (audit.isBlocked) {
                  cardColor = Colors.red.withValues(alpha: 0.1);
                  borderColor = Colors.red;
                  textColor = Colors.red.shade900;
                  iconData = Icons.gpp_bad_rounded;
                } else if (audit.isSuspicious) {
                  cardColor = Colors.amber.withValues(alpha: 0.15);
                  borderColor = Colors.amber.shade700;
                  textColor = Colors.amber.shade900;
                  iconData = Icons.warning_amber_rounded;
                } else {
                  cardColor = Colors.green.withValues(alpha: 0.1);
                  borderColor = Colors.green;
                  textColor = Colors.green.shade900;
                  iconData = Icons.verified_user_rounded;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(iconData, color: borderColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audit.isBlocked
                                  ? 'TƏHLÜKƏLİ: ${audit.title}'
                                  : audit.isSuspicious
                                      ? 'DİQQƏT: ${audit.title}'
                                      : 'TƏHLÜKƏSİZLİK AUDİTİ: Təmiz',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              audit.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: textColor.withValues(alpha: 0.9),
                              ),
                            ),
                            if (audit.warnings.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...audit.warnings.map(
                                (w) => Text(
                                  '• $w',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }(),

              // Oxunmuş məzmun qutusu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: SelectableText(
                  item.data,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Əsas əməliyyat düyməsi (Aç, Zəng et və s.)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: SecurityService.analyze(item.data).isBlocked
                      ? Colors.red
                      : null,
                  foregroundColor: SecurityService.analyze(item.data).isBlocked
                      ? Colors.white
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ActionHelper.performPrimaryAction(context, item);
                },
                icon: Icon(
                  SecurityService.analyze(item.data).isBlocked
                      ? Icons.block_rounded
                      : _getPrimaryIcon(item.type),
                ),
                label: Text(
                  SecurityService.analyze(item.data).isBlocked
                      ? 'Təhlükəli: İcra Bloklanıb'
                      : _getPrimaryLabel(item.type),
                ),
              ),
              const SizedBox(height: 10),

              // Köməkçi düymələr (Kopyala & Paylaş)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        ActionHelper.copyToClipboard(context, item.data);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Kopyala'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        ActionHelper.shareText(item.data);
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Paylaş'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yenidən Skan Et'),
              ),
            ],
          ),
        ),
      ),
    );
  },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  String _getTypeName(QrType type) {
    switch (type) {
      case QrType.url:
        return 'Veb Sayt Linki';
      case QrType.whatsapp:
        return 'WhatsApp Çatı';
      case QrType.wifi:
        return 'Wi-Fi Şəbəkəsi';
      case QrType.phone:
        return 'Telefon Nömrəsi';
      case QrType.email:
        return 'Email Ünvanı';
      case QrType.sms:
        return 'SMS Mesajı';
      case QrType.text:
        return 'Düz Mətn';
    }
  }

  IconData _getPrimaryIcon(QrType type) {
    switch (type) {
      case QrType.url:
        return Icons.open_in_browser_rounded;
      case QrType.whatsapp:
        return Icons.chat_rounded;
      case QrType.phone:
        return Icons.call_rounded;
      case QrType.email:
        return Icons.email_rounded;
      case QrType.sms:
        return Icons.sms_rounded;
      case QrType.wifi:
      case QrType.text:
        return Icons.copy_rounded;
    }
  }

  String _getPrimaryLabel(QrType type) {
    switch (type) {
      case QrType.url:
        return 'Brauzerdə Aç';
      case QrType.whatsapp:
        return 'WhatsApp-da Yaz';
      case QrType.phone:
        return 'Zəng Et';
      case QrType.email:
        return 'Email Göndər';
      case QrType.sms:
        return 'SMS Göndər';
      case QrType.wifi:
        return 'Wi-Fi Şifrəsini Kopyala';
      case QrType.text:
        return 'Mətni Kopyala';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera görünüşü
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return _buildCameraErrorWidget(context, error);
            },
          ),

          // Skaner çərçivəsi və animasiyalı lazer xətti
          _buildScannerOverlay(),

          // Yuxarı idarəetmə paneli (Fənər, Kamera dəyişdirici, Qalereyadan seç)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'QR Skaner',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Qalereyadan şəkil seç düyməsi
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        icon: const Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Qalereyadan seç',
                        onPressed: _pickImageFromGallery,
                      ),
                      const SizedBox(width: 6),

                      // Fənər düyməsi (Flashlight)
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        icon: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, state, child) {
                            return Icon(
                              state.torchState == TorchState.on
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: state.torchState == TorchState.on
                                  ? Colors.amber
                                  : Colors.white,
                            );
                          },
                        ),
                        onPressed: () => _controller.toggleTorch(),
                      ),
                      const SizedBox(width: 6),

                      // Ön/Arxa kamera keçidi
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        icon: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => _controller.switchCamera(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kamera açılmadıqda və ya xəta olduqda göstərilən xəbərdarlıq vidceti
  Widget _buildCameraErrorWidget(BuildContext context, MobileScannerException error) {
    String message = 'Kamera başladılarkən xəta baş verdi.';
    IconData icon = Icons.videocam_off_rounded;

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = 'Kamera icazəsi verilməyib.\nZəhmət olmasa tətbiq tənzimləmələrindən kamera icazəsini aktivləşdirin.';
        icon = Icons.no_photography_rounded;
        break;
      case MobileScannerErrorCode.unsupported:
        message = 'Bu cihazda kamera dəstəklənmir və ya mövcud deyil.';
        icon = Icons.camera_alt_outlined;
        break;
      default:
        message = 'Kamera hazır deyil və ya başqa tətbiq tərəfindən istifadə olunur.';
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _controller.start(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenidən yoxla'),
            ),
          ],
        ),
      ),
    );
  }

  // Skaner üçün vizual çərçivə və animasiyalı lazer xətti
  Widget _buildScannerOverlay() {
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? 360.0;
    final scanSize = screenWidth > 50 ? (screenWidth * 0.70).clamp(200.0, 270.0) : 240.0;
    final innerBoxSize = (scanSize - 8.0).clamp(100.0, 300.0);
    final laserWidth = (scanSize - 16.0).clamp(100.0, 300.0);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Çərçivə
          Container(
            width: scanSize,
            height: scanSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
          ),

          // Lazer animasiyası
          SizedBox(
            width: innerBoxSize,
            height: innerBoxSize,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(0.0, (_animation.value * 2) - 1),
                  child: Container(
                    height: 2.5,
                    width: laserWidth,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
