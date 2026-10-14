class ZeepubAttachedBook {
  final String id;
  final String title;
  final String? spanishTitle;
  final String? englishTitle;
  final String? seriesSpanish;
  final String? seriesId;
  final String? author;
  final String? publisher;
  final String? filepath;
  final String? filename;
  final String? coverLow;
  final String? coverThumb;
  final String? role;
  final double? volume;
  final bool hasBadMetadata;
  final String? metadataIssue;

  const ZeepubAttachedBook({
    required this.id,
    required this.title,
    this.spanishTitle,
    this.englishTitle,
    this.seriesSpanish,
    this.seriesId,
    this.author,
    this.publisher,
    this.filepath,
    this.filename,
    this.coverLow,
    this.coverThumb,
    this.role,
    this.volume,
    this.hasBadMetadata = false,
    this.metadataIssue,
  });

  factory ZeepubAttachedBook.fromJson(Map<String, dynamic> json) {
    return ZeepubAttachedBook(
      id: (json["id"] ?? json["book_id"] ?? "").toString(),
      title: (json["title"] ?? "Sin título").toString(),
      spanishTitle: json["spanish_title"]?.toString(),
      englishTitle: json["english_title"]?.toString(),
      seriesSpanish: json["series_spanish"]?.toString(),
      seriesId: json["series_id"]?.toString(),
      author: json["author"]?.toString(),
      publisher: json["publisher"]?.toString(),
      filepath: json["filepath"]?.toString(),
      filename: json["filename"]?.toString(),
      coverLow: json["cover_low"]?.toString(),
      coverThumb: (json["cover_thumb"] ?? json["cover_low"] ?? json["cover_url"])?.toString(),
      role: json["role"]?.toString() ?? "translator",
      volume: (json["volume"] as num?)?.toDouble(),
      hasBadMetadata: json["has_bad_metadata"] == true,
      metadataIssue: json["metadata_issue"]?.toString(),
    );
  }

  String get displayTitle => spanishTitle?.isNotEmpty == true ? spanishTitle! : title;
  String get displayCover => coverThumb ?? coverLow ?? "";
}

class ZeepubWorkgroup {
  final int id;
  final String name;
  final String siglas;
  final String url;
  final String description;
  final String? preferredLink;
  final int booksCount;
  final int badMetadataCount;
  final int goodMetadataCount;
  final Map<String, String> links;
  final String? createdAt;

  const ZeepubWorkgroup({
    required this.id,
    required this.name,
    this.siglas = "",
    this.url = "",
    this.description = "",
    this.preferredLink,
    this.booksCount = 0,
    this.badMetadataCount = 0,
    this.goodMetadataCount = 0,
    this.links = const {},
    this.createdAt,
  });

  factory ZeepubWorkgroup.fromJson(Map<String, dynamic> json) {
    final rawLinks = json["links"];
    final Map<String, String> parsedLinks = {};
    if (rawLinks is Map) {
      rawLinks.forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty) {
          parsedLinks[k.toString()] = v.toString().trim();
        }
      });
    }

    final bCount = (json["books_count"] as num?)?.toInt() ?? 
                   (json["booksCount"] as num?)?.toInt() ?? 
                   ((json["books"] as List?)?.length ?? 0);
    final badCount = (json["bad_metadata_count"] as num?)?.toInt() ?? 
                     (json["badMetadataCount"] as num?)?.toInt() ?? 0;
    final goodCount = (json["good_metadata_count"] as num?)?.toInt() ?? 
                      (json["goodMetadataCount"] as num?)?.toInt() ?? (bCount - badCount);

    return ZeepubWorkgroup(
      id: json["id"] is int ? json["id"] as int : int.tryParse(json["id"].toString()) ?? 0,
      name: (json["name"] ?? "").toString(),
      siglas: (json["siglas"] ?? "").toString(),
      url: (json["url"] ?? json["website_url"] ?? parsedLinks["web"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      preferredLink: json["preferred_link"]?.toString(),
      booksCount: bCount,
      badMetadataCount: badCount,
      goodMetadataCount: goodCount,
      links: parsedLinks,
      createdAt: json["created_at"]?.toString(),
    );
  }

  ZeepubWorkgroup copyWith({
    int? id,
    String? name,
    String? siglas,
    String? url,
    String? description,
    String? preferredLink,
    int? booksCount,
    int? badMetadataCount,
    int? goodMetadataCount,
    Map<String, String>? links,
    String? createdAt,
  }) {
    return ZeepubWorkgroup(
      id: id ?? this.id,
      name: name ?? this.name,
      siglas: siglas ?? this.siglas,
      url: url ?? this.url,
      description: description ?? this.description,
      preferredLink: preferredLink ?? this.preferredLink,
      booksCount: booksCount ?? this.booksCount,
      badMetadataCount: badMetadataCount ?? this.badMetadataCount,
      goodMetadataCount: goodMetadataCount ?? this.goodMetadataCount,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => siglas.isNotEmpty ? "$name ($siglas)" : name;
  String get websiteUrl => links["web"] ?? url;
  bool get hasIssues => badMetadataCount > 0;
}

class ZeepubWorkgroupDetail {
  final ZeepubWorkgroup group;
  final List<ZeepubAttachedBook> books;
  final int totalBooks;
  final int badMetadataCount;
  final int goodMetadataCount;

  const ZeepubWorkgroupDetail({
    required this.group,
    required this.books,
    required this.totalBooks,
    required this.badMetadataCount,
    required this.goodMetadataCount,
  });

  factory ZeepubWorkgroupDetail.fromJson(Map<String, dynamic> json) {
    final rawGroup = json["group"] is Map<String, dynamic> 
        ? json["group"] as Map<String, dynamic> 
        : json;
    final groupObj = ZeepubWorkgroup.fromJson(rawGroup);

    final rawBooks = (json["books"] as List?) ?? [];
    final booksList = rawBooks
        .whereType<Map<String, dynamic>>()
        .map((e) => ZeepubAttachedBook.fromJson(e))
        .toList();

    final total = (json["total_books"] as num?)?.toInt() ?? booksList.length;
    final bad = (json["bad_metadata_count"] as num?)?.toInt() ?? 
                booksList.where((b) => b.hasBadMetadata).length;
    final good = (json["good_metadata_count"] as num?)?.toInt() ?? (total - bad);

    return ZeepubWorkgroupDetail(
      group: groupObj.copyWith(
        booksCount: total,
        badMetadataCount: bad,
        goodMetadataCount: good,
      ),
      books: booksList,
      totalBooks: total,
      badMetadataCount: bad,
      goodMetadataCount: good,
    );
  }
}
