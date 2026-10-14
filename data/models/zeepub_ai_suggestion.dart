class ZeepubAiSuggestion {
  final String spanishTitle;
  final String englishTitle;
  final String author;
  final double? volume;
  final String demography;

  const ZeepubAiSuggestion({
    this.spanishTitle = '',
    this.englishTitle = '',
    this.author = '',
    this.volume,
    this.demography = '',
  });

  factory ZeepubAiSuggestion.fromJson(Map<String, dynamic> json) {
    return ZeepubAiSuggestion(
      spanishTitle: (json['spanish_title'] ?? json['series_spanish'] ?? '').toString(),
      englishTitle: (json['english_title'] ?? json['series_english'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      volume: json['volume'] != null ? (json['volume'] as num).toDouble() : null,
      demography: (json['demography'] ?? '').toString(),
    );
  }

  String get seriesSpanish => spanishTitle;
  String get illustrator => '';
  String get publisher => '';
}
