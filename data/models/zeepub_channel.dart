class ZeepubChannel {
  final int id;
  final String name;
  final String platform;
  final String targetId;
  final bool isActive;
  final bool isFavorite;
  final String? type;
  final int? subscribersCount;

  const ZeepubChannel({
    required this.id,
    required this.name,
    this.platform = 'telegram',
    required this.targetId,
    this.isActive = true,
    this.isFavorite = false,
    this.type,
    this.subscribersCount,
  });

  factory ZeepubChannel.fromJson(Map<String, dynamic> json) {
    return ZeepubChannel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      platform: (json['platform'] ?? 'telegram').toString(),
      targetId: (json['target_id'] ?? json['targetId'] ?? '').toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      type: json['type']?.toString(),
      subscribersCount: (json['subscribers_count'] ?? json['subscribersCount']) != null
          ? (json['subscribers_count'] ?? json['subscribersCount'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'target_id': targetId,
      'is_active': isActive,
      'is_favorite': isFavorite,
      'type': type,
    };
  }

  bool get isDefault => isFavorite;
  String get channelId => targetId;
}
