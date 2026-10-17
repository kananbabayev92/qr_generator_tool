import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/localization/app_strings.dart';
import '../models/qr_item.dart';
import 'security_service.dart';

/// ActionHelper - QR kodun növünə uyğun əməliyyatları (linki açmaq,
/// WhatsApp-a keçmək, zəng etmək, kopyalamaq) idarə edir.
class ActionHelper {
  /// Əsas əməliyyatı yerinə yetirir (Məs: Linki brauzerdə açır, zəng edir və s.)
  static Future<void> performPrimaryAction(
      BuildContext context, QrItem item) async {
    final data = item.data.trim();

    // Təhlükəsizlik analizi
    final securityResult = SecurityService.analyze(data);

    // Zərərli proqram və ya bloklanan təhlükə aşkarlanarsa, icra dayandırılır
    if (securityResult.isBlocked) {
      if (context.mounted) {
        _showBlockedSecurityDialog(context, securityResult);
      }
      return;
    }

    // Şübhəli link aşkar edilərsə, istifadəçidən təsdiq tələb olunur
    if (securityResult.isSuspicious) {
      final shouldProceed = await _showSuspiciousWarningDialog(context, securityResult);
      if (shouldProceed != true) return;
    }

    if (!context.mounted) return;

    try {
      switch (item.type) {
        case QrType.url:
        case QrType.whatsapp:
        case QrType.instagram:
        case QrType.telegram:
        case QrType.youtube:
          await _launchWebOrAppUrl(context, data);
          break;

        case QrType.phone:
          await _launchPhone(context, data);
          break;

        case QrType.email:
          await _launchEmail(context, data);
          break;

        case QrType.sms:
          await _launchSms(context, data);
          break;

        case QrType.wifi:
          final wifiInfo = parseWifi(data);
          final password = wifiInfo['password'] ?? '';
          if (context.mounted) {
            if (password.isNotEmpty) {
              await copyToClipboard(context, password,
                  customMessage: context.tr('action_wifi_copied'));
            } else {
              await copyToClipboard(context, data,
                  customMessage: context.tr('action_wifi_info_copied'));
            }
          }
          break;

        case QrType.text:
          // Əgər mətndə link varsa, onu açmağa cəhd edirik
          final urlMatch = RegExp(
            r'(https?:\/\/[^\s]+|www\.[^\s]+|instagram\.com\/[^\s]+|t\.me\/[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}\/[^\s]*)',
            caseSensitive: false,
          ).firstMatch(data);

          if (urlMatch != null) {
            final foundUrl = urlMatch.group(0)!;
            await _launchWebOrAppUrl(context, foundUrl);
          } else {
            if (context.mounted) {
              await copyToClipboard(context, data);
            }
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Xəta: $e');
      }
    }
  }

  /// Web və ya Tətbiq linklərini (Instagram, WhatsApp, Telegram, Saytlar) etibarlı açır
  static Future<void> _launchWebOrAppUrl(BuildContext context, String rawUrl) async {
    var formattedUrl = rawUrl.trim();

    // Əgər protokol yoxdursa (məs: instagram.com/profil və ya www.google.com), https:// əlavə edirik
    if (!formattedUrl.contains('://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final uri = Uri.tryParse(formattedUrl);
    if (uri == null) {
      if (context.mounted) {
        _showSnackBar(context, context.tr('action_link_error'));
      }
      return;
    }

    // Bloklanan təhlükəli skript protokolları yoxlanılır
    const dangerousSchemes = {'javascript', 'vbscript', 'data', 'file', 'content'};
    if (dangerousSchemes.contains(uri.scheme.toLowerCase())) {
      if (context.mounted) {
        _showSnackBar(context, context.tr('action_only_https'));
      }
      return;
    }

    bool launched = false;

    // 1-ci cəhd: Xarici tətbiqdə açmaq (Instagram, WhatsApp və ya brauzer)
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    // 2-ci cəhd: Platformanın standart rejimində açmaq
    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }

    // 3-cü cəhd: HTTP/HTTPS linklər üçün daxili brauzerdə açmaq
    if (!launched && (uri.isScheme('http') || uri.isScheme('https'))) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }

    // 4-cü cəhd: Əgər instagram:// sxemi idisə və Instagram tətbiqi yoxdursa, veb saytını açırıq
    if (!launched && uri.scheme == 'instagram') {
      try {
        final username = uri.queryParameters['username'];
        final webUri = username != null && username.isNotEmpty
            ? Uri.parse('https://instagram.com/$username')
            : Uri.parse('https://instagram.com');
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (!launched && context.mounted) {
      _showSnackBar(context, context.tr('action_link_error'));
    }
  }

  /// Telefon nömrəsinə zəng etmək
  static Future<void> _launchPhone(BuildContext context, String phoneData) async {
    final cleanDigits = phoneData.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse(cleanDigits.startsWith('tel:') ? cleanDigits : 'tel:$cleanDigits');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        _showSnackBar(context, context.tr('action_call_error'));
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, context.tr('action_call_error'));
      }
    }
  }

  /// Email proqramını açmaq
  static Future<void> _launchEmail(BuildContext context, String emailData) async {
    final uri = Uri.parse(emailData.startsWith('mailto:') ? emailData : 'mailto:$emailData');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        _showSnackBar(context, context.tr('action_email_error'));
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, context.tr('action_email_error'));
      }
    }
  }

  /// SMS proqramını açmaq
  static Future<void> _launchSms(BuildContext context, String smsData) async {
    final uri = Uri.parse(smsData.startsWith('sms:') || smsData.startsWith('smsto:')
        ? smsData.replaceFirst('smsto:', 'sms:')
        : 'sms:$smsData');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        _showSnackBar(context, context.tr('action_sms_error'));
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, context.tr('action_sms_error'));
      }
    }
  }

  /// Wi-Fi formatından SSID və Şifrəni ayırmaq
  static Map<String, String> parseWifi(String data) {
    final result = <String, String>{};
    final clean = data.replaceFirst(RegExp(r'^WIFI:', caseSensitive: false), '');
    final parts = clean.split(';');

    for (final part in parts) {
      if (part.startsWith('S:')) {
        result['ssid'] = part.substring(2);
      } else if (part.startsWith('P:')) {
        result['password'] = part.substring(2);
      } else if (part.startsWith('T:')) {
        result['security'] = part.substring(2);
      }
    }
    return result;
  }

  /// Mətni buferə kopyalamaq
  static Future<void> copyToClipboard(BuildContext context, String text,
      {String? customMessage}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      _showSnackBar(context, customMessage ?? context.tr('action_copied'));
    }
  }

  /// Məlumatı paylaşmaq
  static Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Zərərli proqram və ya təhlükəli skript aşkar edildikdə göstərilən dialoq
  static void _showBlockedSecurityDialog(
      BuildContext context, SecurityAuditResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 48),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('sec_blocked_dialog_rule'),
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('sec_understood')),
          ),
        ],
      ),
    );
  }

  /// Şübhəli link aşkar edildikdə göstərilən xəbərdarlıq və təsdiq dialoqu
  static Future<bool?> _showSuspiciousWarningDialog(
      BuildContext context, SecurityAuditResult result) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.shield_outlined, color: Colors.amber, size: 44),
        title: Text(
          context.tr('sec_suspicious_dialog_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.description,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            ...result.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('sec_suspicious_dialog_btn_back')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('sec_suspicious_dialog_btn_proceed')),
          ),
        ],
      ),
    );
  }
}
