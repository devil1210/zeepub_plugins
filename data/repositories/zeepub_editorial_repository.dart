import 'package:shared_preferences/shared_preferences.dart';

import '/features/zeepub_editorial/data/datasources/zeepub_api_client.dart';
import '/features/zeepub_editorial/data/models/zeepub_ai_suggestion.dart';
import '/features/zeepub_editorial/data/models/zeepub_channel.dart';
import '/features/zeepub_editorial/data/models/zeepub_post_item.dart';
import '/features/zeepub_editorial/data/models/zeepub_queue_item.dart';
import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_template.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/data/models/zeepub_workgroup.dart';

class ZeepubEditorialRepository {
  final ZeepubApiClient _client;
  final SharedPreferences? _prefs;

  static const _baseUrlKey = 'zeepub_editorial_base_url';
  static const _telegramIdKey = 'zeepub_editorial_telegram_id';

  ZeepubEditorialRepository({
    required ZeepubApiClient client,
    SharedPreferences? prefs,
  })  : _client = client,
        _prefs = prefs {
    if (prefs != null) {
      final savedUrl = prefs.getString(_baseUrlKey);
      final savedTgId = prefs.getString(_telegramIdKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _client.setBaseUrl(savedUrl);
      }
      if (savedTgId != null && savedTgId.isNotEmpty) {
        _client.setTelegramUserId(savedTgId);
      }
    }
  }

  String get baseUrl => _client.baseUrl;
  String get telegramUserId => _client.telegramUserId ?? '';

  Future<void> saveServerConfig({required String url, required String tgId}) async {
    _client.setBaseUrl(url);
    _client.setTelegramUserId(tgId);
    final p = _prefs;
    if (p != null) {
      await p.setString(_baseUrlKey, url);
      await p.setString(_telegramIdKey, tgId);
    }
  }

  // Workgroups
  Future<List<ZeepubWorkgroup>> getWorkgroups() => _client.getWorkgroups();

  Future<ZeepubWorkgroupDetail> getWorkgroupDetail(int id) => _client.getWorkgroupDetail(id);

  Future<Map<String, dynamic>> saveWorkgroup(Map<String, dynamic> payload) =>
      _client.saveWorkgroup(payload);

  Future<Map<String, dynamic>> deleteWorkgroup(int id) =>
      _client.deleteWorkgroup(id);

  Future<Map<String, dynamic>> purgeEmptyWorkgroups() =>
      _client.purgeEmptyWorkgroups();

  Future<Map<String, dynamic>> mergeWorkgroups({
    required int targetId,
    required List<int> sourceIds,
  }) =>
      _client.mergeWorkgroups(targetId: targetId, sourceIds: sourceIds);

  Future<Map<String, dynamic>> syncWorkgroupBooks(
    int workgroupId,
    List<String> bookIds,
  ) =>
      _client.syncWorkgroupBooks(workgroupId, bookIds);

  // Series Catalog
  Future<({List<ZeepubSeries> items, int total, int page, int totalPages})> getSeriesGrid({
    String? query,
    String? category,
    String? sortBy,
    int page = 1,
    int limit = 24,
  }) =>
      _client.getSeriesGrid(
        query: query,
        category: category,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );

  Future<ZeepubSeries> getSeriesDetail(String seriesHash) => _client.getSeriesDetail(seriesHash);

  Future<void> updateSeries(String seriesHash, Map<String, dynamic> payload) =>
      _client.updateSeries(seriesHash, payload);

  Future<Map<String, dynamic>> createSeries(Map<String, dynamic> payload) =>
      _client.createSeries(payload);

  // Volumes
  Future<({List<ZeepubVolume> items, int total, int page, int totalPages})> getVolumes({
    int page = 1,
    int pageSize = 30,
    String? query,
    String? seriesId,
    int? workgroupId,
    String? colorMode,
    bool? isUncensored,
  }) =>
      _client.getVolumes(
        page: page,
        pageSize: pageSize,
        query: query,
        seriesId: seriesId,
        workgroupId: workgroupId,
        colorMode: colorMode,
        isUncensored: isUncensored,
      );

  Future<ZeepubVolume> getVolumeDetail(String bookHash) => _client.getVolumeDetail(bookHash);

  Future<Map<String, dynamic>> createVolume(Map<String, dynamic> payload) =>
      _client.createVolume(payload);

  Future<void> updateVolume(String bookHash, Map<String, dynamic> payload) =>
      _client.updateVolume(bookHash, payload);

  Future<void> syncVolumeFile(String bookHash) => _client.syncVolumeFile(bookHash);

  Future<Map<String, dynamic>> uploadVolumeCover(String bookHash, List<int> fileBytes, String filename) =>
      _client.uploadVolumeCover(bookHash, fileBytes, filename);

  // AI Suggestion
  Future<ZeepubAiSuggestion?> getAiSuggestion(String title) => _client.getAiSuggestion(title);

  Future<Map<String, dynamic>> sendToTelegram(String bookHash) =>
      _client.sendToTelegram(bookHash);

  // Publisher
  Future<List<ZeepubChannel>> getChannels() => _client.getChannels();
  Future<void> saveChannel(Map<String, dynamic> payload) => _client.saveChannel(payload);
  Future<void> deleteChannel(int channelId) => _client.deleteChannel(channelId);

  Future<List<ZeepubTemplate>> getTemplates() => _client.getTemplates();
  Future<void> saveTemplate(Map<String, dynamic> payload) => _client.saveTemplate(payload);
  Future<void> deleteTemplate(int templateId) => _client.deleteTemplate(templateId);
  Future<void> restoreTemplates() => _client.restoreTemplates();

  Future<List<ZeepubQueueItem>> getQueue([String? status, int limit = 100]) =>
      _client.getQueue(status, limit);
  Future<void> cancelQueueItem(int id) => _client.cancelQueueItem(id);
  Future<void> retryQueueItem(int id) => _client.retryQueueItem(id);
  Future<void> updateQueueItem({
    required int id,
    String? scheduledFor,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool? sendAsFile,
    String? status,
    bool immediate = false,
  }) => _client.updateQueueItem(
    id: id,
    scheduledFor: scheduledFor,
    channelId: channelId,
    templateId: templateId,
    customCaption: customCaption,
    sendAsFile: sendAsFile,
    status: status,
    immediate: immediate,
  );

  Future<List<ZeepubPostItem>> getPostsHistory([int limit = 100]) =>
      _client.getPostsHistory(limit);
  Future<Map<String, dynamic>> syncFacebookPublications({int limit = 50, bool forceAll = false}) =>
      _client.syncFacebookPublications(limit: limit, forceAll: forceAll);

  Future<Map<String, dynamic>> publishNow({
    required String bookHash,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool sendAsFile = true,
  }) =>
      _client.publishNow(
        bookHash: bookHash,
        channelId: channelId,
        templateId: templateId,
        customCaption: customCaption,
        sendAsFile: sendAsFile,
      );

  Future<Map<String, dynamic>> schedulePublication({
    required String bookHash,
    required String scheduledAtIso,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool sendAsFile = true,
  }) =>
      _client.schedulePublication(
        bookHash: bookHash,
        scheduledAtIso: scheduledAtIso,
        channelId: channelId,
        templateId: templateId,
        customCaption: customCaption,
        sendAsFile: sendAsFile,
      );
}
