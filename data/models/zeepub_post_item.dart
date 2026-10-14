class ZeepubPostItem {
  final String id;
  final String bookHash;
  final String? title;
  final String? series;
  final double? volume;
  final String? channel;
  final String platform;
  final String publishedAt;
  final String? postUrl;
  final String? coverUrl;
  final String? caption;

  const ZeepubPostItem({
    required this.id,
    required this.bookHash,
    this.title,
    this.series,
    this.volume,
    this.channel,
    this.platform = 'telegram',
    this.publishedAt = '',
    this.postUrl,
    this.coverUrl,
    this.caption,
  });

  factory ZeepubPostItem.fromJson(Map<String, dynamic> json) {
    double? parsedVol;
    final rawVol = json['volume'] ?? json['vol'];
    if (rawVol != null) {
      if (rawVol is num) {
        parsedVol = rawVol.toDouble();
      } else {
        parsedVol = double.tryParse(rawVol.toString().trim());
      }
    }

    return ZeepubPostItem(
      id: (json['id'] ?? json['post_id'] ?? json['publication_id'] ?? '').toString(),
      bookHash: (json['book_hash'] ?? json['book_id'] ?? '').toString(),
      title: json['title']?.toString(),
      series: json['series']?.toString(),
      volume: parsedVol,
      channel: json['channel']?.toString() ?? 'Canal Oficial',
      platform: (json['platform'] ?? 'telegram').toString(),
      publishedAt: json['published_at']?.toString() ?? '',
      postUrl: json['post_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      caption: json['caption']?.toString(),
    );
  }

  String get bookTitle => title?.isNotEmpty == true ? title! : (series?.isNotEmpty == true ? series! : 'Tomo $bookHash');
  String get channelName => channel?.isNotEmpty == true ? channel! : 'Canal Oficial';
  String get channelId => channel?.isNotEmpty == true ? channel! : '1';
  String? get messageId => id.isNotEmpty ? id : null;
}
