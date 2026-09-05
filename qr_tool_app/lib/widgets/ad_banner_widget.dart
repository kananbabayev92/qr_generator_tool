import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// AdBannerWidget - Tətbiqin dizaynına uyğunlaşdırılmış zərif və funksional reklam banneri.
/// Google AdMob və ya daxili sponsor bannerləri üçün tam hazırdır.
class AdBannerWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onAdClosed;

  const AdBannerWidget({
    super.key,
    this.margin,
    this.onAdClosed,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  bool _isVisible = true;

  // Nümunə sponsor / təşviqat elanları (AdMob qoşulana qədər və ya alternativ olaraq nümayiş etdirilir)
  final List<Map<String, String>> _adCampaigns = [
    {
      'title': 'QR & Barkod Təhlükəsizliyi',
      'subtitle': 'Zərərli proqramlardan və saxta linklərdən 100% qorunun.',
      'cta': 'Ətraflı',
      'url': 'https://flutter.dev',
      'icon': 'security',
    },
    {
      'title': 'Premium QR Funksiyaları',
      'subtitle': 'Yüksək dəqiqlikli vektor SVG və PNG ixracı.',
      'cta': 'Kəşf et',
      'url': 'https://flutter.dev',
      'icon': 'star',
    },
  ];

  final int _currentAdIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ad = _adCampaigns[_currentAdIndex];

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFF1F5F9),
                  const Color(0xFFE2E8F0),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final url = ad['url'];
            if (url != null) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Reklam nişanı və İkon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        ad['icon'] == 'security'
                            ? Icons.verified_user_rounded
                            : Icons.auto_awesome_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Reklam Başlığı və Mətni
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REKLAM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ad['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ad['subtitle'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Əməliyyat düyməsi (CTA)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ad['cta'] ?? 'Aç',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Reklamı bağla düyməsi
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  color: Colors.grey,
                  tooltip: 'Reklamı gizlət',
                  onPressed: () {
                    setState(() {
                      _isVisible = false;
                    });
                    widget.onAdClosed?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
