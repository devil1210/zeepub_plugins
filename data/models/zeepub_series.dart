import 'zeepub_volume.dart';

class ZeepubSeries {
  final String id;
  final String seriesHash;
  final String name;
  final String seriesSpanish;
  final String seriesEnglish;
  final String slug;
  final String author;
  final String authorJap;
  final String illustrator;
  final String illustratorJap;
  final String publisher;
  final String bookType;
  final List<String> demographics;
  final List<String> tags;
  final int bookCount;
  final String coverUrl;
  final String? description;
  final double rating;
  final int downloads;
  final bool hasBadMetadata;
  final int badMetadataCount;
  final int goodMetadataCount;
  final List<ZeepubVolume> books;

  const ZeepubSeries({
    required this.id,
    required this.seriesHash,
    required this.name,
    this.seriesSpanish = '',
    this.seriesEnglish = '',
    this.slug = '',
    this.author = '',
    this.authorJap = '',
    this.illustrator = '',
    this.illustratorJap = '',
    this.publisher = '',
    this.bookType = 'Novela Ligera',
    this.demographics = const [],
    this.tags = const [],
    this.bookCount = 0,
    this.coverUrl = '',
    this.description,
    this.rating = 0.0,
    this.downloads = 0,
    this.hasBadMetadata = false,
    this.badMetadataCount = 0,
    this.goodMetadataCount = 0,
    this.books = const [],
  });

  factory ZeepubSeries.fromJson(Map<String, dynamic> json) {
    List<ZeepubVolume> booksList = [];
    final rawBooks = json['books'];
    if (rawBooks is List) {
      for (final b in rawBooks) {
        if (b is Map) {
          try {
            booksList.add(ZeepubVolume.fromJson(Map<String, dynamic>.from(b)));
          } catch (_) {}
        }
      }
      booksList.sort((a, b) {
        final vA = a.volume ?? 999999.0;
        final vB = b.volume ?? 999999.0;
        if (vA != vB) return vA.compareTo(vB);
        return (a.filename ?? a.title).compareTo(b.filename ?? b.title);
      });
    }

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

    final sId = (json['id'] ?? json['series_hash'] ?? '').toString();
    var cover = (json['cover_url'] ?? '').toString();
    if (cover.isEmpty && booksList.isNotEmpty && booksList.first.coverUrl != null && booksList.first.coverUrl!.isNotEmpty) {
      cover = booksList.first.coverUrl!;
    }

    final rawCount = json['book_count'];
    final bookCount = rawCount is num ? rawCount.toInt() : (int.tryParse(rawCount?.toString() ?? '') ?? booksList.length);

    final rawRating = json['rating'];
    final rating = rawRating is num ? rawRating.toDouble() : (double.tryParse(rawRating?.toString() ?? '') ?? 0.0);

    final rawDl = json['downloads'];
    final downloads = rawDl is num ? rawDl.toInt() : (int.tryParse(rawDl?.toString() ?? '') ?? 0);

    final rawBad = json['bad_metadata_count'];
    final badCount = rawBad is num ? rawBad.toInt() : (int.tryParse(rawBad?.toString() ?? '') ?? 0);

    final rawGood = json['good_metadata_count'];
    final goodCount = rawGood is num ? rawGood.toInt() : (int.tryParse(rawGood?.toString() ?? '') ?? 0);

    return ZeepubSeries(
      id: sId,
      seriesHash: (json['series_hash'] ?? sId).toString(),
      name: (json['name'] ?? '').toString(),
      seriesSpanish: (json['series_spanish'] ?? json['name_spanish'] ?? '').toString(),
      seriesEnglish: (json['series_english'] ?? json['name_english'] ?? json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      authorJap: (json['author_jap'] ?? '').toString(),
      illustrator: (json['illustrator'] ?? '').toString(),
      illustratorJap: (json['illustrator_jap'] ?? '').toString(),
      publisher: (json['publisher'] ?? '').toString(),
      bookType: (json['book_type'] ?? 'Novela Ligera').toString(),
      demographics: parseList(json['demographics'] ?? json['demographics_json']),
      tags: parseList(json['tags'] ?? json['tags_json'] ?? json['genres']),
      bookCount: bookCount,
      coverUrl: cover,
      description: json['description']?.toString(),
      rating: rating,
      downloads: downloads,
      hasBadMetadata: json['has_bad_metadata'] == true || badCount > 0,
      badMetadataCount: badCount,
      goodMetadataCount: goodCount,
      books: booksList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'series_hash': seriesHash,
      'name': name,
      'series_spanish': seriesSpanish,
      'series_english': seriesEnglish,
      'slug': slug,
      'author': author,
      'illustrator': illustrator,
      'publisher': publisher,
      'book_type': bookType,
      'demographics': demographics,
      'tags': tags,
      'description': description,
      'cover_url': coverUrl,
    };
  }

  ZeepubSeries copyWith({
    String? id,
    String? seriesHash,
    String? name,
    String? seriesSpanish,
    String? seriesEnglish,
    String? slug,
    String? author,
    String? authorJap,
    String? illustrator,
    String? illustratorJap,
    String? publisher,
    String? bookType,
    List<String>? demographics,
    List<String>? tags,
    int? bookCount,
    String? coverUrl,
    String? description,
    double? rating,
    int? downloads,
    bool? hasBadMetadata,
    int? badMetadataCount,
    int? goodMetadataCount,
    List<ZeepubVolume>? books,
  }) {
    return ZeepubSeries(
      id: id ?? this.id,
      seriesHash: seriesHash ?? this.seriesHash,
      name: name ?? this.name,
      seriesSpanish: seriesSpanish ?? this.seriesSpanish,
      seriesEnglish: seriesEnglish ?? this.seriesEnglish,
      slug: slug ?? this.slug,
      author: author ?? this.author,
      authorJap: authorJap ?? this.authorJap,
      illustrator: illustrator ?? this.illustrator,
      illustratorJap: illustratorJap ?? this.illustratorJap,
      publisher: publisher ?? this.publisher,
      bookType: bookType ?? this.bookType,
      demographics: demographics ?? this.demographics,
      tags: tags ?? this.tags,
      bookCount: bookCount ?? this.bookCount,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      downloads: downloads ?? this.downloads,
      hasBadMetadata: hasBadMetadata ?? this.hasBadMetadata,
      badMetadataCount: badMetadataCount ?? this.badMetadataCount,
      goodMetadataCount: goodMetadataCount ?? this.goodMetadataCount,
      books: books ?? this.books,
    );
  }
}
