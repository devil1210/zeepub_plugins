class ZeepubQueueItem {
  final int id;
  final String bookHash;
  final String? bookId;
  final String? channel;
  final int? channelId;
  final int? templateId;
  final String platform;
  final String? scheduledFor;
  final String status;
  final String? publishedAt;
  final String? error;
  final String? caption;
  final bool? sendAsFile;
  final Map<String, dynamic>? payload;
  final String? series;
  final String? seriesSpanish;
  final String? seriesEnglish;
  final double? volume;
  final String? author;
  final String? coverUrl;

  const ZeepubQueueItem({
    required this.id,
    required this.bookHash,
    this.bookId,
    this.channel,
    this.channelId,
    this.templateId,
    this.platform = 'telegram',
    this.scheduledFor,
    this.status = 'pending',
    this.publishedAt,
    this.error,
    this.caption,
    this.sendAsFile,
    this.payload,
    this.series,
    this.seriesSpanish,
    this.seriesEnglish,
    this.volume,
    this.author,
    this.coverUrl,
  });

  factory ZeepubQueueItem.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    final rawId = json['id'];
    if (rawId != null) {
      if (rawId is num) {
        parsedId = rawId.toInt();
      } else {
        parsedId = int.tryParse(rawId.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    }

    final payloadMap = json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : null;

    int? parsedChanId;
    final rawChanId = json['channel_id'] ?? payloadMap?['channel_id'];
    if (rawChanId != null) {
      if (rawChanId is num) {
        parsedChanId = rawChanId.toInt();
      } else {
        parsedChanId = int.tryParse(rawChanId.toString().trim());
      }
    }

    int? parsedTempId;
    final rawTempId = json['template_id'] ?? payloadMap?['template_id'];
    if (rawTempId != null) {
      if (rawTempId is num) {
        parsedTempId = rawTempId.toInt();
      } else {
        parsedTempId = int.tryParse(rawTempId.toString().trim());
      }
    }

    double? parsedVol;
    final rawVol = json['volume'] ?? json['vol'];
    if (rawVol != null) {
      if (rawVol is num) {
        parsedVol = rawVol.toDouble();
      } else {
        parsedVol = double.tryParse(rawVol.toString().trim());
      }
    }

    final rawSendAsFile = json['send_as_file'] ?? payloadMap?['send_as_file'] ?? payloadMap?['send_file'];
    final bool sendAsFile = rawSendAsFile != null
        ? (rawSendAsFile == true || rawSendAsFile.toString().toLowerCase() == 'true' || rawSendAsFile == 1)
        : true;
    final String? caption = json['caption']?.toString() ?? payloadMap?['custom_caption']?.toString() ?? payloadMap?['caption']?.toString();

    return ZeepubQueueItem(
      id: parsedId,
      bookHash: (json['book_hash'] ?? json['bookId'] ?? json['book_id'] ?? '').toString(),
      bookId: json['book_id']?.toString(),
      channel: json['channel']?.toString(),
      channelId: parsedChanId,
      templateId: parsedTempId,
      platform: (json['platform'] ?? 'telegram').toString(),
      scheduledFor: json['scheduled_for']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      publishedAt: json['published_at']?.toString(),
      error: json['error']?.toString(),
      caption: caption,
      sendAsFile: sendAsFile,
      payload: payloadMap,
      series: json['series']?.toString(),
      seriesSpanish: json['series_spanish']?.toString(),
      seriesEnglish: json['series_english']?.toString(),
      volume: parsedVol,
      author: json['author']?.toString(),
      coverUrl: json['cover_url']?.toString(),
    );
  }

  String get bookTitle => seriesSpanish?.isNotEmpty == true
      ? seriesSpanish!
      : (seriesEnglish?.isNotEmpty == true ? seriesEnglish! : (series?.isNotEmpty == true ? series! : 'Tomo $bookHash'));
  String get channelName => channel?.isNotEmpty == true ? channel! : (channelId != null ? 'Canal $channelId' : 'Canal Oficial');
  String get scheduledAt => scheduledFor ?? '';
  String? get errorMessage => error;
  bool get isScheduled => ['pending', 'scheduled', 'programado'].contains(status.toLowerCase());
}
