class ZeepubVolume {
  final String id;
  final String bookHash;
  final String title;
  final String spanishTitle;
  final String englishTitle;
  final String romajiTitle;
  final String japaneseTitle;
  final String? seriesId;
  final String seriesName;
  final String? seriesSpanish;
  final double? volume;
  final String? edition;
  final String? colorMode;
  final bool isUncensored;
  final String? author;
  final String? authorJap;
  final String? illustrator;
  final String? illustratorJap;
  final String? translator;
  final String? layoutBy;
  final String? publisher;
  final String? description;
  final String? coverUrl;
  final String? filepath;
  final String? filename;
  final int? fileSize;
  final String sizeMb;
  final String language;
  final String? publishedDate;
  final int? pageCount;
  final int? wordCount;
  final int? readingTimeMin;
  final String? isbn;
  final String? asin;
  final String? uuid;
  final String? seriesRomaji;
  final String format;
  final String epubVersion;
  final double rating;
  final int downloads;
  final String? updatedAt;
  final bool hasBadMetadata;
  final List<String> metadataIssues;
  final List<String> tags;

  const ZeepubVolume({
    required this.id,
    required this.bookHash,
    required this.title,
    this.spanishTitle = '',
    this.englishTitle = '',
    this.romajiTitle = '',
    this.japaneseTitle = '',
    this.seriesId,
    this.seriesName = '',
    this.seriesSpanish,
    this.volume,
    this.edition,
    this.colorMode,
    this.isUncensored = false,
    this.author,
    this.authorJap,
    this.illustrator,
    this.illustratorJap,
    this.translator,
    this.layoutBy,
    this.publisher,
    this.description,
    this.coverUrl,
    this.filepath,
    this.filename,
    this.fileSize,
    this.sizeMb = '',
    this.language = 'es',
    this.publishedDate,
    this.pageCount,
    this.wordCount,
    this.readingTimeMin,
    this.isbn,
    this.asin,
    this.uuid,
    this.seriesRomaji,
    this.format = 'EPUB',
    this.epubVersion = 'v3.0',
    this.rating = 0.0,
    this.downloads = 0,
    this.updatedAt,
    this.hasBadMetadata = false,
    this.metadataIssues = const [],
    this.tags = const [],
  });

  factory ZeepubVolume.fromJson(Map<String, dynamic> json) {
    double? parsedVol;
    final rawVol = json['volume'] ?? json['vol'];
    if (rawVol != null) {
      if (rawVol is num) {
        parsedVol = rawVol.toDouble();
      } else {
        parsedVol = double.tryParse(rawVol.toString().trim());
      }
    }

    final rawFSize = json['file_size'];
    final fSize = rawFSize is num ? rawFSize.toInt() : (int.tryParse(rawFSize?.toString() ?? ''));

    String computedSizeMb = json['size_mb']?.toString() ?? '';
    if (computedSizeMb.isEmpty && fSize != null && fSize > 0) {
      computedSizeMb = '${(fSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    final bHash = (json['book_hash'] ?? json['id'] ?? json['bookId'] ?? '').toString();

    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      if (raw is String && raw.isNotEmpty) {
        return raw.split(RegExp(r'[,;|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    final issues = parseList(json['metadata_issues']);
    if (json['metadata_issue'] != null && issues.isEmpty) {
      issues.add(json['metadata_issue'].toString());
    }

    final rawPages = json['page_count'] ?? json['pages'] ?? json['paginas'];
    final pages = rawPages is num ? rawPages.toInt() : (int.tryParse(rawPages?.toString() ?? ''));

    final rawWords = json['word_count'] ?? json['words'] ?? json['palabras'];
    final words = rawWords is num ? rawWords.toInt() : (int.tryParse(rawWords?.toString() ?? ''));

    final rawReading = json['reading_time_min'] ?? json['reading_time'] ?? json['reading_time_minutes'];
    final readingTime = rawReading is num ? rawReading.toInt() : (int.tryParse(rawReading?.toString() ?? ''));

    final rawRating = json['rating'];
    final rating = rawRating is num ? rawRating.toDouble() : (double.tryParse(rawRating?.toString() ?? '') ?? 0.0);

    final rawDl = json['downloads'] ?? json['download_count'];
    final downloads = rawDl is num ? rawDl.toInt() : (int.tryParse(rawDl?.toString() ?? '') ?? 0);

    final seriesInfo = json['series_info'] is Map ? json['series_info'] as Map : null;

    final cover = (json['cover_url'] ??
            json['cover'] ??
            json['cover_high'] ??
            json['cover_thumb'] ??
            json['cover_image'] ??
            (seriesInfo != null ? (seriesInfo['cover_url'] ?? seriesInfo['cover']) : null) ??
            '')
        .toString();

    final desc = json['description']?.toString() ??
        json['summary']?.toString() ??
        json['synopsis']?.toString() ??
        json['desc']?.toString() ??
        (seriesInfo != null ? (seriesInfo['description'] ?? seriesInfo['summary'])?.toString() : null);

    final authorStr = json['author']?.toString() ??
        json['author_name']?.toString() ??
        (seriesInfo != null ? seriesInfo['author']?.toString() : null);

    final illustStr = json['illustrator']?.toString() ??
        (seriesInfo != null ? seriesInfo['illustrator']?.toString() : null);

    final pubStr = json['publisher']?.toString() ??
        json['editorial']?.toString() ??
        json['group']?.toString() ??
        (seriesInfo != null ? seriesInfo['publisher']?.toString() : null);

    final tagList = parseList(
        json['tags'] ?? json['genres'] ?? json['tags_json'] ?? (seriesInfo != null ? seriesInfo['tags_json'] : null));

    final sName = (json['series_name'] ??
            json['series_english'] ??
            json['series'] ??
            (seriesInfo != null ? (seriesInfo['series_english'] ?? seriesInfo['name']) : null) ??
            '')
        .toString();

    final sSpanish = json['series_spanish']?.toString() ??
        (seriesInfo != null ? seriesInfo['series_spanish']?.toString() : null);

    return ZeepubVolume(
      id: (json['id'] ?? bHash).toString(),
      bookHash: bHash,
      title: (json['title'] ?? '').toString(),
      spanishTitle: (json['spanish_title'] ?? '').toString(),
      englishTitle: (json['english_title'] ?? json['title'] ?? '').toString(),
      romajiTitle: (json['romaji_title'] ?? json['romaji'] ?? '').toString(),
      japaneseTitle: (json['japanese_title'] ?? '').toString(),
      seriesId: (json['series_id'] ?? json['series_hash'] ?? '').toString(),
      seriesName: sName,
      seriesSpanish: sSpanish,
      volume: parsedVol,
      edition: json['edition']?.toString(),
      colorMode: json['color_mode']?.toString(),
      isUncensored: json['is_uncensored'] == true ||
          json['is_uncensored'] == 1 ||
          json['is_uncensored']?.toString() == 'true',
      author: authorStr,
      authorJap: json['author_jap']?.toString(),
      illustrator: illustStr,
      illustratorJap: json['illustrator_jap']?.toString(),
      translator: json['translator']?.toString(),
      layoutBy: json['layout_by']?.toString(),
      publisher: pubStr,
      description: desc,
      coverUrl: cover.isNotEmpty ? cover : null,
      filepath: json['filepath']?.toString(),
      filename: json['filename']?.toString(),
      fileSize: fSize,
      sizeMb: computedSizeMb,
      language: (json['language'] ?? 'es').toString(),
      publishedDate: json['published_date']?.toString() ?? json['date']?.toString() ?? json['published_at']?.toString(),
      pageCount: pages,
      wordCount: words,
      readingTimeMin: readingTime,
      isbn: json['isbn']?.toString(),
      asin: json['asin']?.toString(),
      uuid: json['uuid']?.toString(),
      seriesRomaji: json['series_romaji']?.toString() ?? (seriesInfo != null ? seriesInfo['series_romaji']?.toString() : null),
      format: (json['format'] ?? 'EPUB').toString(),
      epubVersion: (json['epub_version'] ?? 'v3.0').toString(),
      rating: rating,
      downloads: downloads,
      updatedAt: json['updated_at']?.toString(),
      hasBadMetadata: json['has_bad_metadata'] == true ||
          parsedVol == null ||
          (json['spanish_title'] ?? '').toString().trim().isEmpty ||
          (json['publisher'] ?? '').toString().trim().isEmpty ||
          issues.isNotEmpty,
      metadataIssues: issues,
      tags: tagList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_hash': bookHash,
      'title': title,
      'spanish_title': spanishTitle,
      'english_title': englishTitle,
      'romaji_title': romajiTitle,
      'japanese_title': japaneseTitle,
      'series_id': seriesId,
      'volume': volume,
      'edition': edition,
      'color_mode': colorMode,
      'is_uncensored': isUncensored,
      'author': author,
      'illustrator': illustrator,
      'translator': translator,
      'layout_by': layoutBy,
      'publisher': publisher,
      'description': description,
      'cover_url': coverUrl,
      'language': language,
      'published_date': publishedDate,
      'isbn': isbn,
      'asin': asin,
      'uuid': uuid,
      'series_romaji': seriesRomaji,
    };
  }

  ZeepubVolume copyWith({
    String? id,
    String? bookHash,
    String? title,
    String? spanishTitle,
    String? englishTitle,
    String? romajiTitle,
    String? japaneseTitle,
    String? seriesId,
    String? seriesName,
    String? seriesSpanish,
    double? volume,
    String? edition,
    String? colorMode,
    bool? isUncensored,
    String? author,
    String? authorJap,
    String? illustrator,
    String? illustratorJap,
    String? translator,
    String? layoutBy,
    String? publisher,
    String? description,
    String? coverUrl,
    String? filepath,
    String? filename,
    int? fileSize,
    String? sizeMb,
    String? language,
    String? publishedDate,
    int? pageCount,
    int? wordCount,
    int? readingTimeMin,
    String? isbn,
    String? asin,
    String? uuid,
    String? seriesRomaji,
    String? format,
    String? epubVersion,
    double? rating,
    int? downloads,
    String? updatedAt,
    bool? hasBadMetadata,
    List<String>? metadataIssues,
    List<String>? tags,
  }) {
    return ZeepubVolume(
      id: id ?? this.id,
      bookHash: bookHash ?? this.bookHash,
      title: title ?? this.title,
      spanishTitle: spanishTitle ?? this.spanishTitle,
      englishTitle: englishTitle ?? this.englishTitle,
      romajiTitle: romajiTitle ?? this.romajiTitle,
      japaneseTitle: japaneseTitle ?? this.japaneseTitle,
      seriesId: seriesId ?? this.seriesId,
      seriesName: seriesName ?? this.seriesName,
      seriesSpanish: seriesSpanish ?? this.seriesSpanish,
      volume: volume ?? this.volume,
      edition: edition ?? this.edition,
      colorMode: colorMode ?? this.colorMode,
      isUncensored: isUncensored ?? this.isUncensored,
      author: author ?? this.author,
      authorJap: authorJap ?? this.authorJap,
      illustrator: illustrator ?? this.illustrator,
      illustratorJap: illustratorJap ?? this.illustratorJap,
      translator: translator ?? this.translator,
      layoutBy: layoutBy ?? this.layoutBy,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      filepath: filepath ?? this.filepath,
      filename: filename ?? this.filename,
      fileSize: fileSize ?? this.fileSize,
      sizeMb: sizeMb ?? this.sizeMb,
      language: language ?? this.language,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      wordCount: wordCount ?? this.wordCount,
      readingTimeMin: readingTimeMin ?? this.readingTimeMin,
      isbn: isbn ?? this.isbn,
      asin: asin ?? this.asin,
      uuid: uuid ?? this.uuid,
      seriesRomaji: seriesRomaji ?? this.seriesRomaji,
      format: format ?? this.format,
      epubVersion: epubVersion ?? this.epubVersion,
      rating: rating ?? this.rating,
      downloads: downloads ?? this.downloads,
      updatedAt: updatedAt ?? this.updatedAt,
      hasBadMetadata: hasBadMetadata ?? this.hasBadMetadata,
      metadataIssues: metadataIssues ?? this.metadataIssues,
      tags: tags ?? this.tags,
    );
  }

  String get displayTitle => spanishTitle.isNotEmpty
      ? spanishTitle
      : (englishTitle.isNotEmpty ? englishTitle : (title.isNotEmpty ? title : "Tomo $bookHash"));
}
