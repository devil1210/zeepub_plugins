import 'dart:convert';
import 'dart:io';

import '/features/zeepub_editorial/data/models/zeepub_ai_suggestion.dart';
import '/features/zeepub_editorial/data/models/zeepub_channel.dart';
import '/features/zeepub_editorial/data/models/zeepub_post_item.dart';
import '/features/zeepub_editorial/data/models/zeepub_queue_item.dart';
import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_template.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/data/models/zeepub_workgroup.dart';

class ZeepubApiClient {
  String baseUrl;
  String? telegramUserId;
  final HttpClient _httpClient;

  ZeepubApiClient({String? baseUrl, this.telegramUserId})
      : baseUrl = baseUrl ?? 'http://localhost:8001',
        _httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 15);

  void setBaseUrl(String url) {
    if (url.trim().isNotEmpty) {
      baseUrl = url.trim().replaceAll(RegExp(r"/+$"), "");
    }
  }

  void setTelegramUserId(String? tgId) {
    telegramUserId = tgId?.trim();
  }

  void _applyAuthHeaders(HttpClientRequest request) {
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final uid = (telegramUserId != null && telegramUserId!.trim().isNotEmpty)
        ? telegramUserId!.trim()
        : '133994080';
    request.headers.set('X-Telegram-User-Id', uid);
    request.headers.set('x-telegram-user-id', uid);
    request.headers.set('X-Telegram-Id', uid);
    request.headers.set('x-telegram-id', uid);
    request.headers.set('X-Telegram-Data', 'debug_$uid');
    request.headers.set('x-telegram-init-data', 'debug_$uid');
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? queryParams]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final request = await _httpClient.getUrl(uri);
    _applyAuthHeaders(request);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'items': decoded, 'success': true};
    } else {
      throw HttpException('Error HTTP ${response.statusCode}: $responseBody', uri: uri);
    }
  }

  Future<dynamic> _getRaw(String path, [Map<String, String>? queryParams]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final request = await _httpClient.getUrl(uri);
    _applyAuthHeaders(request);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseBody);
    } else {
      throw HttpException('Error HTTP ${response.statusCode}: $responseBody', uri: uri);
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = await _httpClient.postUrl(uri);
    _applyAuthHeaders(request);

    final jsonBytes = utf8.encode(jsonEncode(body));
    request.contentLength = jsonBytes.length;
    request.add(jsonBytes);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.trim().isEmpty) return {'success': true};
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded, 'success': true};
    } else {
      throw HttpException('Error HTTP ${response.statusCode}: $responseBody', uri: uri);
    }
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = await _httpClient.putUrl(uri);
    _applyAuthHeaders(request);

    final jsonBytes = utf8.encode(jsonEncode(body));
    request.contentLength = jsonBytes.length;
    request.add(jsonBytes);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.trim().isEmpty) return {'success': true};
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw HttpException('Error HTTP ${response.statusCode}: $responseBody', uri: uri);
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = await _httpClient.deleteUrl(uri);
    _applyAuthHeaders(request);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.trim().isEmpty) return {'success': true};
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw HttpException('Error HTTP ${response.statusCode}: $responseBody', uri: uri);
    }
  }

  // --- Workgroups ---
  Future<List<ZeepubWorkgroup>> getWorkgroups() async {
    try {
      final data = await _getRaw('/api/editorial/workgroups');
      if (data is List) {
        return data.map((e) => ZeepubWorkgroup.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['workgroups'] ?? data['items'] ?? data['data'] ?? []) as List;
        return list.map((e) => ZeepubWorkgroup.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    try {
      final res = await _post('/api/bot', {'action': 'workgroup_get_all', 'data': {}});
      final list = (res['workgroups'] ?? res['items'] ?? res['data'] ?? []) as List;
      return list.map((e) => ZeepubWorkgroup.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}

    return [];
  }

  Future<ZeepubWorkgroupDetail> getWorkgroupDetail(int id) async {
    try {
      final res = await _get('/api/editorial/workgroups/$id');
      return ZeepubWorkgroupDetail.fromJson(res);
    } catch (_) {}

    try {
      final res = await _post('/api/bot', {
        'action': 'workgroup_get_detail',
        'data': {'id': id}
      });
      return ZeepubWorkgroupDetail.fromJson(res);
    } catch (e) {
      throw Exception('No se pudo cargar el detalle del fansub: $e');
    }
  }

  Future<Map<String, dynamic>> saveWorkgroup(Map<String, dynamic> payload) async {
    try {
      return await _post('/api/editorial/workgroups', payload);
    } catch (_) {
      return await _post('/api/bot', {
        'action': 'workgroup_save',
        'data': payload,
      });
    }
  }

  Future<Map<String, dynamic>> deleteWorkgroup(int id) async {
    try {
      return await _delete('/api/editorial/workgroups/$id');
    } catch (_) {
      return await _post('/api/bot', {
        'action': 'workgroup_delete',
        'data': {'id': id},
      });
    }
  }

  Future<Map<String, dynamic>> purgeEmptyWorkgroups() async {
    try {
      return await _post('/api/editorial/workgroups/purge-empty', {});
    } catch (_) {
      return await _post('/api/bot', {
        'action': 'workgroup_purge_empty',
        'data': {},
      });
    }
  }

  Future<Map<String, dynamic>> mergeWorkgroups({required int targetId, required List<int> sourceIds}) async {
    final payload = {'target_id': targetId, 'source_ids': sourceIds};
    try {
      return await _post('/api/editorial/workgroups/merge', payload);
    } catch (_) {
      return await _post('/api/bot', {
        'action': 'workgroup_merge',
        'data': payload,
      });
    }
  }

  Future<Map<String, dynamic>> syncWorkgroupBooks(int workgroupId, List<String> bookIds) async {
    final payload = {'group_id': workgroupId, 'book_ids': bookIds};
    try {
      return await _post('/api/editorial/workgroups/$workgroupId/sync-books', payload);
    } catch (_) {
      return await _post('/api/bot', {
        'action': 'workgroup_sync_books',
        'data': payload,
      });
    }
  }

  // --- Series Catalog ---
  Future<({List<ZeepubSeries> items, int total, int page, int totalPages})> getSeriesGrid({
    String? query,
    String? category,
    String? sortBy,
    int page = 1,
    int limit = 24,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'page_size': limit.toString(),
    };
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (sortBy != null && sortBy.isNotEmpty) params['sort_by'] = sortBy;
    if (category != null && category.isNotEmpty && category != 'all') {
      if (['Novela Ligera', 'Manga', 'Web Novel'].contains(category)) {
        params['book_type'] = category;
      } else {
        params['demography'] = category;
      }
    }

    try {
      final res = await _get('/api/editorial/series/grid', params);
      final rawList = (res['series'] ?? res['items'] ?? res['results'] ?? res['data']) as List?;
      if (rawList != null && rawList.isNotEmpty) {
        final items = rawList.map((e) => ZeepubSeries.fromJson(e as Map<String, dynamic>)).toList();
        final total = (res['total'] ?? res['total_series'] ?? res['totalItems'] ?? items.length) as num;
        final totalPages = (res['total_pages'] ?? res['totalPages'] ?? ((total.toInt() + limit - 1) ~/ limit)) as num;
        return (items: items, total: total.toInt(), page: page, totalPages: totalPages.toInt() > 0 ? totalPages.toInt() : 1);
      }
    } catch (_) {}

    try {
      final res = await _get('/api/editorial/series', params);
      final rawList = (res['items'] ?? res['series'] ?? res['results'] ?? res['data']) as List?;
      if (rawList != null && rawList.isNotEmpty) {
        final items = rawList.map((e) => ZeepubSeries.fromJson(e as Map<String, dynamic>)).toList();
        final total = (res['total'] ?? res['total_series'] ?? res['totalItems'] ?? items.length) as num;
        final totalPages = (res['total_pages'] ?? res['totalPages'] ?? ((total.toInt() + limit - 1) ~/ limit)) as num;
        return (items: items, total: total.toInt(), page: page, totalPages: totalPages.toInt() > 0 ? totalPages.toInt() : 1);
      }
    } catch (_) {}

    try {
      final res = await _post('/api/bot', {
        'action': 'admin_get_library_grid',
        'data': {
          'query': query,
          'category': category,
          'sort_by': sortBy,
          'page': page,
          'limit': limit,
        }
      });
      final rawList = (res['series'] ?? res['items'] ?? res['results'] ?? []) as List;
      final items = rawList.map((e) => ZeepubSeries.fromJson(e as Map<String, dynamic>)).toList();
      final total = (res['total'] ?? res['total_series'] ?? items.length) as num;
      final totalPages = (res['total_pages'] ?? ((total.toInt() + limit - 1) ~/ limit)) as num;
      return (items: items, total: total.toInt(), page: page, totalPages: totalPages.toInt() > 0 ? totalPages.toInt() : 1);
    } catch (_) {}

    return (items: <ZeepubSeries>[], total: 0, page: page, totalPages: 1);
  }

  Future<ZeepubSeries> getSeriesDetail(String seriesHash) async {
    try {
      final res = await _post('/api/bot', {
        'action': 'admin_get_series_detail',
        'data': {'series_id': seriesHash, 'series_hash': seriesHash}
      });
      if (res['series'] != null) {
        return ZeepubSeries.fromJson(Map<String, dynamic>.from(res['series'] as Map));
      }
      return ZeepubSeries.fromJson(res);
    } catch (_) {}

    try {
      final res = await _get('/api/editorial/series/$seriesHash');
      return ZeepubSeries.fromJson(res);
    } catch (e) {
      throw Exception('Error al obtener detalle de serie: $e');
    }
  }

  Future<void> updateSeries(String seriesHash, Map<String, dynamic> payload) async {
    try {
      await _put('/api/editorial/series/$seriesHash', payload);
    } catch (e) {
      await _post('/api/bot', {
        'action': 'update_series',
        'data': {'series_hash': seriesHash, ...payload}
      });
    }
  }

  Future<Map<String, dynamic>> createSeries(Map<String, dynamic> payload) async {
    try {
      return await _post('/api/editorial/series', payload);
    } catch (_) {
      return await _post('/api/bot', {
        'action': 'create_series',
        'data': payload,
      });
    }
  }

  // --- Volumes ---
  Future<({List<ZeepubVolume> items, int total, int page, int totalPages})> getVolumes({
    int page = 1,
    int pageSize = 30,
    String? query,
    String? seriesId,
    int? workgroupId,
    String? colorMode,
    bool? isUncensored,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'limit': pageSize.toString(),
    };
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (seriesId != null && seriesId.isNotEmpty) params['series_id'] = seriesId;
    if (workgroupId != null) params['workgroup_id'] = workgroupId.toString();
    if (colorMode != null && colorMode.isNotEmpty) params['color_mode'] = colorMode;
    if (isUncensored != null) params['is_uncensored'] = isUncensored.toString();

    try {
      final res = await _get('/api/editorial/volumes', params);
      final rawList = (res['items'] ?? res['volumes'] ?? res['books'] ?? res['results'] ?? []) as List;
      final items = rawList.map((e) => ZeepubVolume.fromJson(e as Map<String, dynamic>)).toList();
      final total = (res['total'] ?? res['total_items'] ?? items.length) as num;
      final totalPages = (res['total_pages'] ?? ((total.toInt() + pageSize - 1) ~/ pageSize)) as num;
      return (items: items, total: total.toInt(), page: page, totalPages: totalPages.toInt() > 0 ? totalPages.toInt() : 1);
    } catch (_) {}

    try {
      final res = await _post('/api/bot', {
        'action': 'get_volumes',
        'data': {
          'page': page,
          'page_size': pageSize,
          'query': query,
          'series_id': seriesId,
          'workgroup_id': workgroupId,
          'color_mode': colorMode,
          'is_uncensored': isUncensored,
        }
      });
      final rawList = (res['items'] ?? res['volumes'] ?? res['books'] ?? res['results'] ?? []) as List;
      final items = rawList.map((e) => ZeepubVolume.fromJson(e as Map<String, dynamic>)).toList();
      final total = (res['total'] ?? res['total_items'] ?? items.length) as num;
      final totalPages = (res['total_pages'] ?? ((total.toInt() + pageSize - 1) ~/ pageSize)) as num;
      return (items: items, total: total.toInt(), page: page, totalPages: totalPages.toInt() > 0 ? totalPages.toInt() : 1);
    } catch (_) {}

    return (items: <ZeepubVolume>[], total: 0, page: page, totalPages: 1);
  }

    Future<ZeepubVolume> getVolumeDetail(String bookHash) async {
    try {
      final res = await _post('/api/bot', {
        'action': 'book-detail',
        'data': {'bookId': bookHash, 'book_id': bookHash}
      });
      final map = (res['result'] ?? res['book'] ?? res['volume'] ?? res);
      if (map is Map<String, dynamic>) {
        return ZeepubVolume.fromJson(map);
      }
      if (map is Map) {
        return ZeepubVolume.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (_) {}

    try {
      final res = await _get('/api/editorial/volumes/$bookHash');
      final map = (res['result'] ?? res['book'] ?? res['volume'] ?? res);
      if (map is Map<String, dynamic>) {
        return ZeepubVolume.fromJson(map);
      }
      if (map is Map) {
        return ZeepubVolume.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      throw Exception('Error al obtener detalle de tomo: $e');
    }
    throw Exception('No se pudo obtener el detalle del tomo');
  }

  Future<Map<String, dynamic>> createVolume(Map<String, dynamic> payload) async {
    try {
      return await _post('/api/editorial/volumes', payload);
    } catch (e) {
      return await _post('/api/bot', {
        'action': 'create_book',
        'data': payload,
      });
    }
  }

  Future<void> updateVolume(String bookHash, Map<String, dynamic> payload) async {
    try {
      await _put('/api/editorial/volumes/$bookHash', payload);
    } catch (e) {
      await _post('/api/bot', {
        'action': 'update_book',
        'data': {'book_hash': bookHash, ...payload}
      });
    }
  }

  Future<void> syncVolumeFile(String bookHash) async {
    try {
      await _post('/api/editorial/volumes/$bookHash/sync-file', {});
    } catch (e) {
      await _post('/api/bot', {
        'action': 'sync_book_file',
        'data': {'book_hash': bookHash}
      });
    }
  }

  Future<Map<String, dynamic>> uploadVolumeCover(
    String bookHash,
    List<int> fileBytes,
    String filename,
  ) async {
    final uri = Uri.parse('$baseUrl/api/editorial/volumes/$bookHash/cover');
    final boundary = '----ZeePubBoundary${DateTime.now().millisecondsSinceEpoch}';
    final request = await _httpClient.postUrl(uri);

    request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final uid = (telegramUserId != null && telegramUserId!.trim().isNotEmpty)
        ? telegramUserId!.trim()
        : '133994080';
    request.headers.set('X-Telegram-User-Id', uid);
    request.headers.set('x-telegram-user-id', uid);
    request.headers.set('X-Telegram-Id', uid);
    request.headers.set('x-telegram-id', uid);
    request.headers.set('X-Telegram-Data', 'debug_$uid');
    request.headers.set('x-telegram-init-data', 'debug_$uid');

    final headerStr = '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$filename"\r\nContent-Type: image/jpeg\r\n\r\n';
    final footerStr = '\r\n--$boundary--\r\n';
    final header = utf8.encode(headerStr);
    final footer = utf8.encode(footerStr);

    request.contentLength = header.length + fileBytes.length + footer.length;
    request.add(header);
    request.add(fileBytes);
    request.add(footer);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw HttpException('Error HTTP ${response.statusCode}: $responseBody', uri: uri);
    }
  }

  // --- AI Suggestions ---
  Future<ZeepubAiSuggestion?> getAiSuggestion(String title) async {
    try {
      final res = await _get('/api/editorial/ai/suggest', {'title': title});
      if (res['suggestion'] != null) {
        return ZeepubAiSuggestion.fromJson(res['suggestion'] as Map<String, dynamic>);
      }
    } catch (_) {}

    try {
      final res = await _post('/api/bot', {
        'action': 'ai_suggest_metadata',
        'data': {'title': title}
      });
      if (res['suggestion'] != null) {
        return ZeepubAiSuggestion.fromJson(res['suggestion'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return null;
  }

  // --- Channels ---
  Future<List<ZeepubChannel>> getChannels() async {
    try {
      final data = await _getRaw('/api/editorial/channels');
      if (data is List) {
        return data.map((e) => ZeepubChannel.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['channels'] ?? data['items'] ?? []) as List;
        return list.map((e) => ZeepubChannel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    try {
      final res = await _post('/api/bot', {'action': 'pub_get_channels', 'data': {}});
      final list = (res['channels'] ?? res['items'] ?? []) as List;
      return list.map((e) => ZeepubChannel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}

    return [];
  }

  Future<void> saveChannel(Map<String, dynamic> payload) async {
    try {
      await _post('/api/editorial/channels', payload);
    } catch (e) {
      await _post('/api/bot', {'action': 'pub_save_channel', 'data': payload});
    }
  }

  Future<void> deleteChannel(int channelId) async {
    try {
      await _delete('/api/editorial/channels/$channelId');
    } catch (e) {
      await _post('/api/bot', {'action': 'pub_delete_channel', 'data': {'channel_id': channelId}});
    }
  }

  // --- Templates ---
  Future<List<ZeepubTemplate>> getTemplates() async {
    try {
      final data = await _getRaw('/api/editorial/templates');
      if (data is List) {
        return data.map((e) => ZeepubTemplate.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['templates'] ?? data['items'] ?? []) as List;
        return list.map((e) => ZeepubTemplate.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    try {
      final res = await _post('/api/bot', {'action': 'pub_get_templates', 'data': {}});
      final list = (res['templates'] ?? res['items'] ?? []) as List;
      return list.map((e) => ZeepubTemplate.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}

    return [];
  }

  Future<void> saveTemplate(Map<String, dynamic> payload) async {
    try {
      await _post('/api/editorial/templates', payload);
    } catch (e) {
      await _post('/api/bot', {'action': 'pub_save_template', 'data': payload});
    }
  }

  Future<void> deleteTemplate(int templateId) async {
    try {
      await _delete('/api/editorial/templates/$templateId');
    } catch (e) {
      await _post('/api/bot', {'action': 'pub_delete_template', 'data': {'template_id': templateId}});
    }
  }

  Future<void> restoreTemplates() async {
    try {
      await _post('/api/editorial/templates/restore', {});
    } catch (e) {
      await _post('/api/bot', {'action': 'pub_restore_templates', 'data': {}});
    }
  }

  // --- Queue / Calendar ---
  Future<List<ZeepubQueueItem>> getQueue([String? status, int limit = 100]) async {
    final params = <String, String>{'limit': limit.toString()};
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }

    try {
      final res = await _post('/api/bot', {
        'action': 'pub_get_queue',
        'data': {if (status != null && status != 'all') 'status': status, 'limit': limit}
      });
      final list = (res['items'] ?? res['queue'] ?? []) as List;
      return list.map((e) {
        try {
          return ZeepubQueueItem.fromJson(Map<String, dynamic>.from(e as Map));
        } catch (_) {
          return null;
        }
      }).whereType<ZeepubQueueItem>().toList();
    } catch (_) {}

    try {
      final data = await _getRaw('/api/editorial/queue', params);
      if (data is List) {
        return data.map((e) {
          try {
            return ZeepubQueueItem.fromJson(Map<String, dynamic>.from(e as Map));
          } catch (_) {
            return null;
          }
        }).whereType<ZeepubQueueItem>().toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['items'] ?? data['queue'] ?? []) as List;
        return list.map((e) {
          try {
            return ZeepubQueueItem.fromJson(Map<String, dynamic>.from(e as Map));
          } catch (_) {
            return null;
          }
        }).whereType<ZeepubQueueItem>().toList();
      }
    } catch (_) {}

    return [];
  }

  Future<void> cancelQueueItem(int id) async {
    try {
      await _post('/api/editorial/queue/cancel', {'id': id});
    } catch (e) {
      await _post('/api/bot', {'action': 'pub_cancel', 'data': {'queue_id': id, 'id': id}});
    }
  }

  Future<void> retryQueueItem(int id) async {
    try {
      await _post('/api/editorial/queue/retry', {'id': id});
    } catch (e) {
      await _post('/api/bot', {'action': 'pub_retry', 'data': {'queue_id': id, 'id': id}});
    }
  }

  Future<void> updateQueueItem({
    required int id,
    String? scheduledFor,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool? sendAsFile,
    String? status,
    bool immediate = false,
  }) async {
    final payload = <String, dynamic>{
      'id': id,
      'queue_id': id,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (channelId != null) 'channel_id': channelId,
      if (templateId != null) 'template_id': templateId,
      if (customCaption != null) 'custom_caption': customCaption,
      if (sendAsFile != null) 'send_as_file': sendAsFile,
      if (status != null) 'status': status,
      if (immediate) 'immediate': true,
    };

    try {
      await _post('/api/editorial/queue/update', payload);
    } catch (_) {
      await _post('/api/bot', {
        'action': 'pub_update_queue_item',
        'data': payload,
      });
    }
  }

  // --- Posts ---
  Future<List<ZeepubPostItem>> getPostsHistory([int limit = 100]) async {
    final params = <String, String>{'limit': limit.toString()};
    try {
      final res = await _post('/api/bot', {
        'action': 'pub_get_queue',
        'data': {'status': 'sent', 'limit': limit}
      });
      final list = (res['items'] ?? res['posts'] ?? []) as List;
      return list.map((e) {
        try {
          return ZeepubPostItem.fromJson(Map<String, dynamic>.from(e as Map));
        } catch (_) {
          return null;
        }
      }).whereType<ZeepubPostItem>().toList();
    } catch (_) {}

    try {
      final data = await _getRaw('/api/editorial/posts', params);
      if (data is List) {
        return data.map((e) {
          try {
            return ZeepubPostItem.fromJson(Map<String, dynamic>.from(e as Map));
          } catch (_) {
            return null;
          }
        }).whereType<ZeepubPostItem>().toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['items'] ?? data['posts'] ?? []) as List;
        return list.map((e) {
          try {
            return ZeepubPostItem.fromJson(Map<String, dynamic>.from(e as Map));
          } catch (_) {
            return null;
          }
        }).whereType<ZeepubPostItem>().toList();
      }
    } catch (_) {}

    return [];
  }

  Future<Map<String, dynamic>> syncFacebookPublications({int limit = 50, bool forceAll = false}) async {
    try {
      return await _post('/api/editorial/facebook/sync', {'limit': limit, 'force_all': forceAll});
    } catch (_) {
      return await _post('/api/bot', {
        'action': 'facebook_sync_publications',
        'data': {'limit': limit, 'force_all': forceAll}
      });
    }
  }

  // --- Direct User Telegram Delivery ---
  Future<Map<String, dynamic>> sendToTelegram(String bookHash) async {
    return await _post('/api/bot', {
      'action': 'download',
      'data': {
        'bookId': bookHash,
        'target': 'private',
      },
    });
  }

  // --- Publish ---
  Future<Map<String, dynamic>> publishNow({
    required String bookHash,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool sendAsFile = true,
  }) async {
    final body = <String, dynamic>{
      'book_hash': bookHash,
      'send_as_file': sendAsFile,
    };
    if (channelId != null) body['channel_id'] = channelId;
    if (templateId != null) body['template_id'] = templateId;
    if (customCaption != null) body['custom_caption'] = customCaption;

    try {
      return await _post('/api/editorial/publish/now', body);
    } catch (e) {
      return await _post('/api/bot', {
        'action': 'pub_quick_post',
        'data': {
          'book_hash': bookHash,
          'book_id': bookHash,
          'channel_id': channelId,
          'template_id': templateId,
          'custom_caption': customCaption,
          'caption': customCaption,
          'send_as_file': sendAsFile,
        }
      });
    }
  }

  Future<Map<String, dynamic>> schedulePublication({
    required String bookHash,
    required String scheduledAtIso,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool sendAsFile = true,
  }) async {
    final body = <String, dynamic>{
      'book_hash': bookHash,
      'scheduled_for': scheduledAtIso,
      'send_as_file': sendAsFile,
    };
    if (channelId != null) body['channel_id'] = channelId;
    if (templateId != null) body['template_id'] = templateId;
    if (customCaption != null) body['custom_caption'] = customCaption;

    try {
      return await _post('/api/editorial/publish/schedule', body);
    } catch (e) {
      return await _post('/api/bot', {
        'action': 'pub_schedule',
        'data': {
          'book_hash': bookHash,
          'book_id': bookHash,
          'scheduled_for': scheduledAtIso,
          'channel_id': channelId,
          'template_id': templateId,
          'custom_caption': customCaption,
          'caption': customCaption,
          'send_as_file': sendAsFile,
        }
      });
    }
  }
}
