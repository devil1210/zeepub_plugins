import '/features/zeepub_editorial/data/models/zeepub_ai_suggestion.dart';
import '/features/zeepub_editorial/data/models/zeepub_channel.dart';
import '/features/zeepub_editorial/data/models/zeepub_post_item.dart';
import '/features/zeepub_editorial/data/models/zeepub_queue_item.dart';
import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_template.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/data/models/zeepub_workgroup.dart';

class ZeepubEditorialState {
  final bool loading;
  final bool saving;
  final bool aiLoading;
  final String? errorMessage;
  final String? successMessage;

  // Series Catalog (Exploración / Árbol)
  final List<ZeepubSeries> seriesCatalog;
  final int seriesTotalCount;
  final int seriesCurrentPage;
  final int seriesTotalPages;
  final bool loadingSeries;
  final bool loadingMoreSeries;
  final String seriesCategory;
  final String seriesSortBy;
  final String seriesSearchQuery;
  final String seriesViewMode; // 'grid' | 'list'
  final String seriesPaginationMode; // 'infinite' | 'paged'

  // Compatibility getter
  List<ZeepubSeries> get seriesList => seriesCatalog;
  int get totalSeries => seriesTotalCount;

  // Active Detail Navigation
  final ZeepubSeries? activeSeriesDetail;
  final List<ZeepubVolume> activeSeriesBooks;
  final bool loadingSeriesDetail;

  final ZeepubVolume? activeVolumeDetail;
  final bool loadingVolumeDetail;

  final ZeepubWorkgroupDetail? activeWorkgroupDetail;
  final bool loadingWorkgroupDetail;
  final int workgroupDetailInitialTab;

  // Volumes Flat List
  final List<ZeepubVolume> volumes;
  final int totalVolumes;
  final int currentPage;
  final int totalPages;
  final String searchQuery;
  final String? selectedSeriesId;
  final int? selectedWorkgroupId;
  final String? selectedColorMode;
  final bool? filterUncensored;

  // Metadata & Workgroups
  final List<ZeepubWorkgroup> workgroups;
  final List<ZeepubChannel> channels;
  final List<ZeepubTemplate> templates;
  final List<ZeepubQueueItem> queue;
  final List<ZeepubPostItem> posts;

  // Editor & Publisher Sub-views
  final ZeepubVolume? activeVolume;
  final ZeepubVolume? publishingVolume;
  final ZeepubAiSuggestion? latestAiSuggestion;
  final String baseUrl;
  final String telegramUserId;
  final double coverScale;

  const ZeepubEditorialState({
    this.loading = false,
    this.saving = false,
    this.aiLoading = false,
    this.errorMessage,
    this.successMessage,
    this.seriesCatalog = const [],
    this.seriesTotalCount = 0,
    this.seriesCurrentPage = 1,
    this.seriesTotalPages = 1,
    this.loadingSeries = false,
    this.loadingMoreSeries = false,
    this.seriesCategory = 'all',
    this.seriesSortBy = 'name_asc',
    this.seriesSearchQuery = '',
    this.seriesViewMode = 'grid',
    this.seriesPaginationMode = 'infinite',
    this.activeSeriesDetail,
    this.activeSeriesBooks = const [],
    this.loadingSeriesDetail = false,
    this.activeVolumeDetail,
    this.loadingVolumeDetail = false,
    this.activeWorkgroupDetail,
    this.loadingWorkgroupDetail = false,
    this.workgroupDetailInitialTab = 0,
    this.volumes = const [],
    this.totalVolumes = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.searchQuery = '',
    this.selectedSeriesId,
    this.selectedWorkgroupId,
    this.selectedColorMode,
    this.filterUncensored,
    this.workgroups = const [],
    this.channels = const [],
    this.templates = const [],
    this.queue = const [],
    this.posts = const [],
    this.activeVolume,
    this.publishingVolume,
    this.latestAiSuggestion,
    this.baseUrl = 'http://localhost:8001',
    this.telegramUserId = '',
    this.coverScale = 1.0,
  });

  ZeepubEditorialState copyWith({
    bool? loading,
    bool? saving,
    bool? aiLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    List<ZeepubSeries>? seriesCatalog,
    int? seriesTotalCount,
    int? seriesCurrentPage,
    int? seriesTotalPages,
    bool? loadingSeries,
    bool? loadingMoreSeries,
    String? seriesCategory,
    String? seriesSortBy,
    String? seriesSearchQuery,
    String? seriesViewMode,
    String? seriesPaginationMode,
    ZeepubSeries? activeSeriesDetail,
    bool clearSeriesDetail = false,
    List<ZeepubVolume>? activeSeriesBooks,
    bool? loadingSeriesDetail,
    ZeepubVolume? activeVolumeDetail,
    bool clearVolumeDetail = false,
    bool? loadingVolumeDetail,
    ZeepubWorkgroupDetail? activeWorkgroupDetail,
    bool clearWorkgroupDetail = false,
    bool? loadingWorkgroupDetail,
    int? workgroupDetailInitialTab,
    List<ZeepubVolume>? volumes,
    int? totalVolumes,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
    String? selectedSeriesId,
    bool clearSeriesFilter = false,
    int? selectedWorkgroupId,
    bool clearWorkgroupFilter = false,
    String? selectedColorMode,
    bool clearColorFilter = false,
    bool? filterUncensored,
    bool clearUncensoredFilter = false,
    List<ZeepubWorkgroup>? workgroups,
    List<ZeepubChannel>? channels,
    List<ZeepubTemplate>? templates,
    List<ZeepubQueueItem>? queue,
    List<ZeepubPostItem>? posts,
    ZeepubVolume? activeVolume,
    bool clearActiveVolume = false,
    ZeepubVolume? publishingVolume,
    bool clearPublishingVolume = false,
    ZeepubAiSuggestion? latestAiSuggestion,
    bool clearAiSuggestion = false,
    String? baseUrl,
    String? telegramUserId,
    double? coverScale,
  }) {
    return ZeepubEditorialState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      aiLoading: aiLoading ?? this.aiLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      seriesCatalog: seriesCatalog ?? this.seriesCatalog,
      seriesTotalCount: seriesTotalCount ?? this.seriesTotalCount,
      seriesCurrentPage: seriesCurrentPage ?? this.seriesCurrentPage,
      seriesTotalPages: seriesTotalPages ?? this.seriesTotalPages,
      loadingSeries: loadingSeries ?? this.loadingSeries,
      loadingMoreSeries: loadingMoreSeries ?? this.loadingMoreSeries,
      seriesCategory: seriesCategory ?? this.seriesCategory,
      seriesSortBy: seriesSortBy ?? this.seriesSortBy,
      seriesSearchQuery: seriesSearchQuery ?? this.seriesSearchQuery,
      seriesViewMode: seriesViewMode ?? this.seriesViewMode,
      seriesPaginationMode: seriesPaginationMode ?? this.seriesPaginationMode,
      activeSeriesDetail: clearSeriesDetail ? null : (activeSeriesDetail ?? this.activeSeriesDetail),
      activeSeriesBooks: activeSeriesBooks ?? this.activeSeriesBooks,
      loadingSeriesDetail: loadingSeriesDetail ?? this.loadingSeriesDetail,
      activeVolumeDetail: clearVolumeDetail ? null : (activeVolumeDetail ?? this.activeVolumeDetail),
      loadingVolumeDetail: loadingVolumeDetail ?? this.loadingVolumeDetail,
      activeWorkgroupDetail: clearWorkgroupDetail ? null : (activeWorkgroupDetail ?? this.activeWorkgroupDetail),
      loadingWorkgroupDetail: loadingWorkgroupDetail ?? this.loadingWorkgroupDetail,
      workgroupDetailInitialTab: workgroupDetailInitialTab ?? this.workgroupDetailInitialTab,
      volumes: volumes ?? this.volumes,
      totalVolumes: totalVolumes ?? this.totalVolumes,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSeriesId: clearSeriesFilter ? null : (selectedSeriesId ?? this.selectedSeriesId),
      selectedWorkgroupId: clearWorkgroupFilter ? null : (selectedWorkgroupId ?? this.selectedWorkgroupId),
      selectedColorMode: clearColorFilter ? null : (selectedColorMode ?? this.selectedColorMode),
      filterUncensored: clearUncensoredFilter ? null : (filterUncensored ?? this.filterUncensored),
      workgroups: workgroups ?? this.workgroups,
      channels: channels ?? this.channels,
      templates: templates ?? this.templates,
      queue: queue ?? this.queue,
      posts: posts ?? this.posts,
      activeVolume: clearActiveVolume ? null : (activeVolume ?? this.activeVolume),
      publishingVolume: clearPublishingVolume ? null : (publishingVolume ?? this.publishingVolume),
      latestAiSuggestion: clearAiSuggestion ? null : (latestAiSuggestion ?? this.latestAiSuggestion),
      baseUrl: baseUrl ?? this.baseUrl,
      telegramUserId: telegramUserId ?? this.telegramUserId,
      coverScale: coverScale ?? this.coverScale,
    );
  }
}
