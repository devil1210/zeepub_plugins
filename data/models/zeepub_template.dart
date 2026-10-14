class ZeepubTemplate {
  final int? id;
  final String name;
  final String content;
  final String platform;
  final bool isDefault;
  final Map<String, dynamic>? extraConfig;

  const ZeepubTemplate({
    this.id,
    required this.name,
    required this.content,
    this.platform = 'telegram',
    this.isDefault = false,
    this.extraConfig,
  });

  factory ZeepubTemplate.fromJson(Map<String, dynamic> json) {
    return ZeepubTemplate(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      platform: (json['platform'] ?? 'telegram').toString(),
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
      extraConfig: json['extra_config'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'content': content,
      'platform': platform,
      'is_default': isDefault,
      if (extraConfig != null) 'extra_config': extraConfig,
    };
  }

  ZeepubTemplate copyWith({
    int? id,
    String? name,
    String? content,
    String? platform,
    bool? isDefault,
    Map<String, dynamic>? extraConfig,
  }) {
    return ZeepubTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      platform: platform ?? this.platform,
      isDefault: isDefault ?? this.isDefault,
      extraConfig: extraConfig ?? this.extraConfig,
    );
  }
}
