import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../models/qr_item.dart';
import '../services/action_helper.dart';

/// QrCard vidceti tarixçədə və ya nəticələrdə QR kodun məlumatlarını
/// gözəl kart şəklində göstərir.
class QrCard extends StatelessWidget {
  final QrItem item;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const QrCard({
    super.key,
    required this.item,
    this.onFavoriteToggle,
    this.onDelete,
    this.onTap,
  });

  // Növə uyğun ikon seçmək
  IconData _getTypeIcon(QrType type) {
    switch (type) {
      case QrType.url:
        return Icons.link_rounded;
      case QrType.whatsapp:
        return Icons.chat_rounded;
      case QrType.wifi:
        return Icons.wifi_rounded;
      case QrType.email:
        return Icons.email_outlined;
      case QrType.phone:
        return Icons.phone_outlined;
      case QrType.sms:
        return Icons.sms_outlined;
      case QrType.text:
        return Icons.text_snippet_outlined;
    }
  }

  // Növün adı
  String _getTypeLabel(BuildContext context, QrType type) {
    switch (type) {
      case QrType.url:
        return context.tr('type_url');
      case QrType.whatsapp:
        return context.tr('type_whatsapp');
      case QrType.wifi:
        return context.tr('type_wifi');
      case QrType.email:
        return context.tr('type_email');
      case QrType.phone:
        return context.tr('type_phone');
      case QrType.sms:
        return context.tr('type_sms');
      case QrType.text:
        return context.tr('type_text');
    }
  }

  Color _getTypeColor(BuildContext context, QrType type) {
    switch (type) {
      case QrType.whatsapp:
        return const Color(0xFF25D366); // WhatsApp yaşılı
      case QrType.url:
        return Colors.blueAccent;
      case QrType.wifi:
        return Colors.amber.shade700;
      case QrType.phone:
        return Colors.teal;
      case QrType.email:
        return Colors.purpleAccent;
      case QrType.sms:
        return Colors.deepOrangeAccent;
      case QrType.text:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(context, item.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap ?? () => ActionHelper.performPrimaryAction(context, item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Sol tərəfdə növə uyğun dairəvi ikon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getTypeIcon(item.type),
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Orta hissə: Başlıq, məzmun və tarix
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Növ etiketi (Badge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getTypeLabel(context, item.type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Skan olunub yoxsa Yaradılıb etiketi
                        Flexible(
                          child: Text(
                            item.isScanned
                                ? context.tr('history_badge_scanned')
                                : context.tr('history_badge_generated'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title.isNotEmpty ? item.title : item.data,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.createdAt.day.toString().padLeft(2, '0')}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.year}  ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Sağ tərəfdə əməliyyat düymələri (Sevimli və Menyular)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      item.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: item.isFavorite ? Colors.amber : Colors.grey,
                      size: 22,
                    ),
                    tooltip: context.tr('history_filter_favorites'),
                    onPressed: onFavoriteToggle,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      if (value == 'open') {
                        ActionHelper.performPrimaryAction(context, item);
                      } else if (value == 'copy') {
                        ActionHelper.copyToClipboard(context, item.data);
                      } else if (value == 'share') {
                        ActionHelper.shareText(item.data);
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            const Icon(Icons.launch_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(context.tr('action_execute')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(context.tr('scanner_copy')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            const Icon(Icons.share_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(context.tr('scanner_share')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(context.tr('history_delete'), style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
