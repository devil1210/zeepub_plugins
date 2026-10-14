import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ZeepubCachedImage extends StatelessWidget {
  final String imageUrl;
  final String? baseUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double fallbackIconSize;
  final Map<String, String>? httpHeaders;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;

  const ZeepubCachedImage({
    super.key,
    required this.imageUrl,
    this.baseUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.fallbackIconSize = 36,
    this.httpHeaders,
    this.memCacheWidth = 600,
    this.memCacheHeight = 900,
    this.placeholder,
  });

  String _resolveUrl() {
    final raw = imageUrl.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (baseUrl != null && baseUrl!.trim().isNotEmpty) {
      final base = baseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
      final path = raw.startsWith('/') ? raw : '/$raw';
      return '$base$path';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveUrl();
    if (resolved.isEmpty) {
      return _buildFallback();
    }

    final headers = httpHeaders ?? {
      'X-Telegram-User-Id': '133994080',
      'X-Telegram-Data': 'debug_133994080',
    };

    final imageWidget = CachedNetworkImage(
      imageUrl: resolved,
      cacheKey: resolved,
      fit: fit,
      width: width,
      height: height,
      httpHeaders: headers,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => placeholder ?? Container(
        color: const Color(0xFF0F172A),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF0F172A),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white24,
          size: fallbackIconSize,
        ),
      ),
    );
  }
}
