import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_strings.dart';
import '../../models/qr_item.dart';
import '../../services/action_helper.dart';
import '../../services/security_service.dart';
import '../../services/storage_service.dart';

/// GeneratorScreen - İstifadəçinin fərqli növlərdə (Mətn, URL, WhatsApp, Wi-Fi və s.)
/// xüsusi rənglərlə QR kodlar yaratması və şəkil kimi ixrac etməsi üçün olan səhifə.
class GeneratorScreen extends StatefulWidget {
  final StorageService storageService;

  const GeneratorScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  // Seçilmiş növ
  QrType _selectedType = QrType.text;

  // Qr kodun rəng tənzimləmələri
  Color _qrForegroundColor = const Color(0xFF0F172A);
  final Color _qrBackgroundColor = Colors.white;

  // RepaintBoundary üçün açar (Şəkil kimi saxlamaq üçün)
  final GlobalKey _qrRepaintKey = GlobalKey();

  // Mətn daxiletmə kontrollerləri
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _waPhoneController = TextEditingController();
  final TextEditingController _waMessageController = TextEditingController();

  String _wifiSecurity = 'WPA';
  String _generatedData = '';

  final List<Color> _presetColors = [
    const Color(0xFF0F172A), // Klassik qara/tünd
    const Color(0xFF6366F1), // İndigo bənövşəyi
    const Color(0xFF25D366), // WhatsApp yaşılı
    const Color(0xFF0284C7), // Okean mavisi
    const Color(0xFFE11D48), // Qırmızı
    const Color(0xFFD97706), // Kəhrəba / Narıncı
    const Color(0xFF7C3AED), // Tünd bənövşəyi
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateGeneratedData);
    _ssidController.addListener(_updateGeneratedData);
    _passwordController.addListener(_updateGeneratedData);
    _emailController.addListener(_updateGeneratedData);
    _emailSubjectController.addListener(_updateGeneratedData);
    _phoneController.addListener(_updateGeneratedData);
    _smsController.addListener(_updateGeneratedData);
    _waPhoneController.addListener(_updateGeneratedData);
    _waMessageController.addListener(_updateGeneratedData);
  }

  @override
  void dispose() {
    _textController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _emailSubjectController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    _waPhoneController.dispose();
    _waMessageController.dispose();
    super.dispose();
  }

  // Daxil edilmiş məlumatlara əsasən QR kodun formatını hazırlamaq
  void _updateGeneratedData() {
    setState(() {
      switch (_selectedType) {
        case QrType.text:
        case QrType.url:
          _generatedData = _textController.text.trim();
          break;

        case QrType.whatsapp:
          var phone = _waPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
          final msg = _waMessageController.text.trim();
          if (phone.isNotEmpty) {
            if (msg.isNotEmpty) {
              final encodedMsg = Uri.encodeComponent(msg);
              _generatedData = 'https://wa.me/$phone?text=$encodedMsg';
            } else {
              _generatedData = 'https://wa.me/$phone';
            }
          } else {
            _generatedData = '';
          }
          break;

        case QrType.wifi:
          final ssid = _ssidController.text.trim();
          final pass = _passwordController.text.trim();
          if (ssid.isNotEmpty) {
            _generatedData = 'WIFI:S:$ssid;T:$_wifiSecurity;P:$pass;;';
          } else {
            _generatedData = '';
          }
          break;

        case QrType.email:
          final email = _emailController.text.trim();
          final subject = _emailSubjectController.text.trim();
          if (email.isNotEmpty) {
            if (subject.isNotEmpty) {
              _generatedData =
                  'mailto:$email?subject=${Uri.encodeComponent(subject)}';
            } else {
              _generatedData = 'mailto:$email';
            }
          } else {
            _generatedData = '';
          }
          break;

        case QrType.phone:
          final phone = _phoneController.text.trim();
          if (phone.isNotEmpty) {
            _generatedData = 'tel:$phone';
          } else {
            _generatedData = '';
          }
          break;

        case QrType.sms:
          final phone = _phoneController.text.trim();
          final msg = _smsController.text.trim();
          if (phone.isNotEmpty) {
            _generatedData = 'smsto:$phone:$msg';
          } else {
            _generatedData = '';
          }
          break;
      }
    });
  }

  // QR kodu tarixçəyə yadda saxlamaq
  void _saveToHistory() {
    if (_generatedData.isEmpty) return;

    final securityResult = SecurityService.analyze(_generatedData);
    if (securityResult.isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.gpp_bad_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.tr('gen_blocked_save_msg')),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final item = QrItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: _generatedData,
      title: _getFriendlyTitle(),
      type: _selectedType,
      createdAt: DateTime.now(),
      isScanned: false,
    );

    widget.storageService.addItem(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(context.tr('gen_saved_success')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // QR kodu şəkil (PNG) olaraq paylaşmaq
  Future<void> _shareAsImage() async {
    if (_generatedData.isEmpty) return;

    final securityResult = SecurityService.analyze(_generatedData);
    if (securityResult.isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('gen_blocked_share_msg')}${securityResult.title}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final boundary = _qrRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'QR: $_generatedData',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getFriendlyTitle() {
    switch (_selectedType) {
      case QrType.whatsapp:
        return 'WhatsApp: ${_waPhoneController.text}';
      case QrType.wifi:
        return 'Wi-Fi: ${_ssidController.text}';
      case QrType.email:
        return 'Email: ${_emailController.text}';
      case QrType.phone:
        return 'Tel: ${_phoneController.text}';
      case QrType.sms:
        return 'SMS: ${_phoneController.text}';
      default:
        return _generatedData.length > 25
            ? '${_generatedData.substring(0, 25)}...'
            : _generatedData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('gen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Növ seçimi üçün Chip-lər
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // Giriş xanaları (Form)
            _buildInputFields(),
            const SizedBox(height: 24),

            // QR Kodun önizlənməsi (Preview) və Təhlükəsizlik Yoxlanışı
            if (_generatedData.isNotEmpty) ...[
              () {
                final audit = SecurityService.analyze(_generatedData);

                // ZƏRƏRLİ PROQRAM VƏ YA BLOKLANAN MƏZMUN AŞKARLANARSA:
                if (audit.isBlocked) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade400, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.gpp_bad_rounded,
                          color: Colors.red,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          audit.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          audit.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined, color: Colors.red, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('gen_blocked_title'),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // TƏHLÜKƏSİZ VƏ YA ŞÜBHƏLİ QR KODLAR ÜÇÜN:
                return Column(
                  children: [
                    // Təhlükəsizlik status indikatoru
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: audit.isSuspicious
                            ? Colors.amber.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: audit.isSuspicious ? Colors.amber : Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            audit.isSuspicious
                                ? Icons.warning_amber_rounded
                                : Icons.verified_user_rounded,
                            size: 16,
                            color: audit.isSuspicious ? Colors.amber.shade900 : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            audit.isSuspicious
                                ? context.tr('gen_status_suspicious')
                                : context.tr('gen_status_clean'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: audit.isSuspicious ? Colors.amber.shade900 : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Center(
                      child: RepaintBoundary(
                        key: _qrRepaintKey,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _qrBackgroundColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _qrForegroundColor.withValues(alpha: 0.12),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QrImageView(
                                data: _generatedData,
                                version: QrVersions.auto,
                                size: 210.0,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: _qrForegroundColor,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: _qrForegroundColor,
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _getFriendlyTitle(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _qrForegroundColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rəng seçici palitrası
                    _buildColorPicker(),
                    const SizedBox(height: 20),

                    // Əməliyyat düymələri (Yadda saxla, Şəkil kimi paylaş, Mətni kopyala)
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveToHistory,
                          icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                          label: Text(context.tr('gen_save')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _shareAsImage,
                          icon: const Icon(Icons.image_rounded, size: 18),
                          label: Text(context.tr('gen_share_img')),
                        ),
                        IconButton.filledTonal(
                          onPressed: () =>
                              ActionHelper.copyToClipboard(context, _generatedData),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: context.tr('scanner_copy'),
                        ),
                      ],
                    ),
                  ],
                );
              }(),
            ] else ...[
              // Boş olduqda göstərilən məlumat kartı
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('gen_enter_details'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Rəng seçici komponenti
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('gen_color_picker'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _presetColors.map((color) {
            final isSelected = _qrForegroundColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _qrForegroundColor = color;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Növ seçimi vidceti
  Widget _buildTypeSelector() {
    final types = [
      {'type': QrType.text, 'label': context.tr('type_text'), 'icon': Icons.text_fields_rounded},
      {'type': QrType.url, 'label': context.tr('type_url'), 'icon': Icons.link_rounded},
      {'type': QrType.whatsapp, 'label': context.tr('type_whatsapp'), 'icon': Icons.chat_rounded},
      {'type': QrType.wifi, 'label': context.tr('type_wifi'), 'icon': Icons.wifi_rounded},
      {'type': QrType.phone, 'label': context.tr('type_phone'), 'icon': Icons.phone_rounded},
      {'type': QrType.email, 'label': context.tr('type_email'), 'icon': Icons.email_rounded},
      {'type': QrType.sms, 'label': context.tr('type_sms'), 'icon': Icons.sms_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((item) {
          final type = item['type'] as QrType;
          final isSelected = _selectedType == type;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                item['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
              label: Text(item['label'] as String),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    _updateGeneratedData();
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Daxiletmə formaları
  Widget _buildInputFields() {
    switch (_selectedType) {
      case QrType.text:
        return TextField(
          controller: _textController,
          maxLines: 3,
          maxLength: SecurityService.maxSafeLength,
          decoration: InputDecoration(
            labelText: context.tr('gen_input_text_label'),
            hintText: context.tr('gen_input_text_hint'),
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
        );

      case QrType.url:
        return TextField(
          controller: _textController,
          keyboardType: TextInputType.url,
          maxLength: SecurityService.maxSafeLength,
          decoration: InputDecoration(
            labelText: context.tr('gen_input_url_label'),
            hintText: context.tr('gen_input_url_hint'),
            prefixIcon: const Icon(Icons.link_rounded),
          ),
        );

      case QrType.whatsapp:
        return Column(
          children: [
            TextField(
              controller: _waPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_wa_phone'),
                hintText: '+1234567890',
                prefixIcon: const Icon(Icons.phone_android_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _waMessageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_wa_msg'),
                hintText: context.tr('gen_input_wa_msg_hint'),
                prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
          ],
        );

      case QrType.wifi:
        return Column(
          children: [
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_wifi_ssid'),
                hintText: 'Home Wi-Fi',
                prefixIcon: const Icon(Icons.wifi_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_wifi_pass'),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _wifiSecurity,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_wifi_security'),
                prefixIcon: const Icon(Icons.security_rounded),
              ),
              items: [
                const DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2')),
                const DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                DropdownMenuItem(value: 'nopass', child: Text(context.tr('gen_wifi_open'))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _wifiSecurity = val;
                    _updateGeneratedData();
                  });
                }
              },
            ),
          ],
        );

      case QrType.phone:
        return TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: context.tr('gen_input_phone'),
            hintText: '+1 234 567 8900',
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        );

      case QrType.email:
        return Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_email'),
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailSubjectController,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_subject'),
                hintText: 'Inquiry',
                prefixIcon: const Icon(Icons.subject_rounded),
              ),
            ),
          ],
        );

      case QrType.sms:
        return Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_phone'),
                hintText: '+1 234 567 8900',
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _smsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('gen_input_sms'),
                hintText: 'Message text...',
                prefixIcon: const Icon(Icons.message_rounded),
              ),
            ),
          ],
        );
    }
  }
}
