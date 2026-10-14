import '/features/zeepub_editorial/data/datasources/zeepub_api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/data/models/zeepub_workgroup.dart';
import '/features/zeepub_editorial/data/repositories/zeepub_editorial_repository.dart';
import 'zeepub_editorial_state.dart';
import '/inject_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZeepubEditorialCubit extends Cubit<ZeepubEditorialState> {
  final ZeepubEditorialRepository _repo;

  ZeepubEditorialCubit({ZeepubEditorialRepository? repository})
      : _repo = repository ?? ZeepubEditorialRepository(client: ZeepubApiClient()),
        super(ZeepubEditorialState(coverScale: _loadInitialCoverScale()));

  static double _loadInitialCoverScale() {
    try {
      if (getIt.isRegistered<SharedPreferences>()) {
        final val = getIt<SharedPreferences>().getDouble('zeepub_universal_cover_scale');
        if (val != null && val >= 0.70 && val <= 1.50) {
          return val;
        }
      }
    } catch (_) {}
    return 1.0;
  }

  void setCoverScale(double scale) {
    emit(state.copyWith(coverScale: scale));
    try {
      if (getIt.isRegistered<SharedPreferences>()) {
        getIt<SharedPreferences>().setDouble('zeepub_universal_cover_scale', scale);
      }
    } catch (_) {}
  }

  Future<void> init() async {
    emit(state.copyWith(
      loading: true,
      clearError: true,
      baseUrl: _repo.baseUrl,
      telegramUserId: _repo.telegramUserId,
    ));
    try {
      final results = await Future.wait([
        _repo.getWorkgroups(),
        _repo.getChannels(),
        _repo.getTemplates(),
        _repo.getQueue(),
        _repo.getPostsHistory(),
      ]);

      final workgroups = results[0] as List<ZeepubWorkgroup>;
      final channels = results[1] as List<dynamic>;
      final templates = results[2] as List<dynamic>;
      final queue = results[3] as List<dynamic>;
      final posts = results[4] as List<dynamic>;

      emit(state.copyWith(
        workgroups: workgroups,
        channels: channels.cast(),
        templates: templates.cast(),
        queue: queue.cast(),
        posts: posts.cast(),
        baseUrl: _repo.baseUrl,
        telegramUserId: _repo.telegramUserId,
      ));

      await loadSeriesCatalog(reset: true);
      await loadVolumes(page: 1);
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        baseUrl: _repo.baseUrl,
        telegramUserId: _repo.telegramUserId,
        errorMessage: 'Error al conectar con la API de ZeePub: $e',
      ));
    }
  }

  Future<void> saveServerConfig({required String url, required String tgId}) async {
    await _repo.saveServerConfig(url: url, tgId: tgId);
    emit(state.copyWith(baseUrl: _repo.baseUrl, telegramUserId: _repo.telegramUserId));
    await init();
  }

  Future<void> setBaseUrl(String url) async {
    await saveServerConfig(url: url, tgId: state.telegramUserId);
  }

  // ==========================================
  // SERIES CATALOG (Exploración / Árbol)
  // ==========================================

  Future<void> loadSeriesCatalog({
    bool reset = false,
    String? category,
    String? sortBy,
    String? query,
    int? page,
  }) async {
    final targetPage = reset ? 1 : (page ?? state.seriesCurrentPage);
    final targetCat = category ?? state.seriesCategory;
    final targetSort = sortBy ?? state.seriesSortBy;
    final targetQuery = query ?? state.seriesSearchQuery;

    emit(state.copyWith(
      loadingSeries: reset || targetPage == 1,
      seriesCategory: targetCat,
      seriesSortBy: targetSort,
      seriesSearchQuery: targetQuery,
      clearError: true,
    ));

    try {
      final res = await _repo.getSeriesGrid(
        query: targetQuery,
        category: targetCat,
        sortBy: targetSort,
        page: targetPage,
        limit: 50,
      );

      final List<ZeepubSeries> items = res.items;
      final int total = res.total;
      final int pages = res.totalPages;

      final updatedList = (reset || targetPage == 1)
          ? items
          : [...state.seriesCatalog, ...items];

      emit(state.copyWith(
        loadingSeries: false,
        loadingMoreSeries: false,
        seriesCatalog: updatedList,
        seriesTotalCount: total,
        seriesCurrentPage: targetPage,
        seriesTotalPages: pages,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadingSeries: false,
        loadingMoreSeries: false,
        errorMessage: 'Error al cargar catálogo de series: $e',
      ));
    }
  }

  Future<void> loadMoreSeries() async {
    if (state.loadingMoreSeries || state.seriesCurrentPage >= state.seriesTotalPages) {
      return;
    }
    emit(state.copyWith(loadingMoreSeries: true));
    await loadSeriesCatalog(page: state.seriesCurrentPage + 1);
  }

  Future<void> openSeriesDetail(ZeepubSeries series) async {
    emit(state.copyWith(
      activeSeriesDetail: series,
      loadingSeriesDetail: true,
      clearError: true,
    ));

    try {
      final fullSeries = await _repo.getSeriesDetail(series.id);
      final books = fullSeries.books;

      emit(state.copyWith(
        activeSeriesDetail: fullSeries,
        activeSeriesBooks: books,
        loadingSeriesDetail: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        activeSeriesDetail: series,
        loadingSeriesDetail: false,
        errorMessage: 'Error al cargar tomos de la serie: $e',
      ));
    }
  }

  void closeSeriesDetail() {
    emit(state.copyWith(clearSeriesDetail: true));
  }

  Future<void> openVolumeDetail(ZeepubVolume volume, [ZeepubSeries? series]) async {
    emit(state.copyWith(
      activeVolumeDetail: volume,
      loadingVolumeDetail: true,
      clearError: true,
    ));

    try {
      final fullVolume = await _repo.getVolumeDetail(volume.bookHash);
      emit(state.copyWith(
        activeVolumeDetail: fullVolume,
        loadingVolumeDetail: false,
      ));
    } catch (_) {
      emit(state.copyWith(
        activeVolumeDetail: volume,
        loadingVolumeDetail: false,
      ));
    }
  }

  void closeVolumeDetail() {
    emit(state.copyWith(clearVolumeDetail: true));
  }

  // ==========================================
  // WORKGROUPS & AUDITORIA (Nivel 2 Subview)
  // ==========================================

  Future<void> openWorkgroupDetail(ZeepubWorkgroup group, {int initialTab = 0}) async {
    emit(state.copyWith(
      loadingWorkgroupDetail: true,
      clearWorkgroupDetail: false,
      workgroupDetailInitialTab: initialTab,
      clearError: true,
    ));

    try {
      final detail = await _repo.getWorkgroupDetail(group.id);
      emit(state.copyWith(
        activeWorkgroupDetail: detail,
        loadingWorkgroupDetail: false,
        workgroupDetailInitialTab: initialTab,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadingWorkgroupDetail: false,
        errorMessage: 'Error al abrir información del fansub: $e',
      ));
    }
  }

  void closeWorkgroupDetail() {
    emit(state.copyWith(clearWorkgroupDetail: true));
  }

  Future<void> loadWorkgroups() async {
    try {
      final list = await _repo.getWorkgroups();
      emit(state.copyWith(workgroups: list));
    } catch (_) {}
  }

  Future<void> saveWorkgroup(Map<String, dynamic> payload) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.saveWorkgroup(payload);
      emit(state.copyWith(saving: false, successMessage: 'Fansub guardado con éxito'));
      await loadWorkgroups();
      if (state.activeWorkgroupDetail != null && payload['id'] != null) {
        final id = int.tryParse(payload['id'].toString());
        if (id != null) {
          final detail = await _repo.getWorkgroupDetail(id);
          emit(state.copyWith(activeWorkgroupDetail: detail));
        }
      }
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al guardar fansub: $e'));
    }
  }

  Future<void> deleteWorkgroup(int id) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.deleteWorkgroup(id);
      emit(state.copyWith(
        saving: false,
        clearWorkgroupDetail: true,
        successMessage: 'Fansub eliminado con éxito',
      ));
      await loadWorkgroups();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al eliminar fansub: $e'));
    }
  }

  Future<void> purgeEmptyWorkgroups() async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final res = await _repo.purgeEmptyWorkgroups();
      final msg = res['message']?.toString() ?? 'Grupos vacíos purgados con éxito';
      emit(state.copyWith(saving: false, successMessage: msg));
      await loadWorkgroups();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al purgar grupos: $e'));
    }
  }

  Future<void> mergeWorkgroups({required int targetId, required List<int> sourceIds}) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final res = await _repo.mergeWorkgroups(targetId: targetId, sourceIds: sourceIds);
      final msg = res['message']?.toString() ?? 'Grupos fusionados con éxito';
      emit(state.copyWith(saving: false, successMessage: msg));
      await loadWorkgroups();
      if (state.activeWorkgroupDetail != null) {
        final detail = await _repo.getWorkgroupDetail(targetId);
        emit(state.copyWith(activeWorkgroupDetail: detail));
      }
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al fusionar grupos: $e'));
    }
  }

  Future<void> syncWorkgroupBooks(int workgroupId, List<String> bookIds) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final res = await _repo.syncWorkgroupBooks(workgroupId, bookIds);
      final msg = res['message']?.toString() ?? 'Libros sincronizados desde sus archivos EPUB';
      emit(state.copyWith(saving: false, successMessage: msg));
      final detail = await _repo.getWorkgroupDetail(workgroupId);
      emit(state.copyWith(activeWorkgroupDetail: detail));
      await loadWorkgroups();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al sincronizar libros: $e'));
    }
  }

  // ==========================================
  // MODALS & OVERLAYS (Publisher & Editor)
  // ==========================================

  void openPublisher(ZeepubVolume volume) {
    emit(state.copyWith(publishingVolume: volume));
  }

  void closePublisher() {
    emit(state.copyWith(clearPublishingVolume: true));
  }

  void openVolumeEdit(ZeepubVolume volume) {
    emit(state.copyWith(activeVolume: volume, clearAiSuggestion: true));
  }

  void closeVolumeEdit() {
    emit(state.copyWith(clearActiveVolume: true, clearAiSuggestion: true));
  }

  Future<void> fetchAiSuggestion(String title) async {
    emit(state.copyWith(aiLoading: true));
    try {
      final suggestion = await _repo.getAiSuggestion(title);
      emit(state.copyWith(
        latestAiSuggestion: suggestion,
        aiLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        aiLoading: false,
        errorMessage: 'Error al obtener sugerencias IA: $e',
      ));
    }
  }

  Future<void> requestAiSuggestion(String title) => fetchAiSuggestion(title);

  Future<Map<String, dynamic>?> uploadCover(String bookHash, List<int> bytes, String filename) async {
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    try {
      final res = await _repo.uploadVolumeCover(bookHash, bytes, filename);
      emit(state.copyWith(
        saving: false,
        successMessage: 'Portada subida exitosamente.',
      ));
      if (res['cover_url'] != null) {
        if (state.activeVolume != null) {
          emit(state.copyWith(
            activeVolume: state.activeVolume!.copyWith(coverUrl: res['cover_url']),
          ));
        }
        if (state.activeVolumeDetail != null) {
          emit(state.copyWith(
            activeVolumeDetail: state.activeVolumeDetail!.copyWith(coverUrl: res['cover_url']),
          ));
        }
      }
      return res;
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al subir la portada: $e',
      ));
      return null;
    }
  }

  // Flat Volumes List
  Future<void> loadVolumes({
    int page = 1,
    String? query,
    String? seriesId,
    int? workgroupId,
    String? colorMode,
    bool? filterUncensored,
  }) async {
    emit(state.copyWith(
      loading: true,
      currentPage: page,
      searchQuery: query ?? state.searchQuery,
      selectedSeriesId: seriesId ?? state.selectedSeriesId,
      selectedWorkgroupId: workgroupId ?? state.selectedWorkgroupId,
      selectedColorMode: colorMode ?? state.selectedColorMode,
      filterUncensored: filterUncensored ?? state.filterUncensored,
    ));

    try {
      final res = await _repo.getVolumes(
        page: page,
        query: state.searchQuery,
        seriesId: state.selectedSeriesId,
        workgroupId: state.selectedWorkgroupId,
        colorMode: state.selectedColorMode,
        isUncensored: state.filterUncensored,
      );

      final items = res.items;
      final total = res.total;
      final pages = res.totalPages;

      emit(state.copyWith(
        loading: false,
        volumes: items,
        totalVolumes: total,
        totalPages: pages,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Error al cargar tomos: $e',
      ));
    }
  }

  Future<void> saveVolume(String bookHash, Map<String, dynamic> payload) async {
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    try {
      await _repo.updateVolume(bookHash, payload);
      emit(state.copyWith(
        saving: false,
        clearActiveVolume: true,
        successMessage: 'Tomo actualizado correctamente.',
      ));
      if (state.activeVolumeDetail != null && state.activeVolumeDetail!.bookHash == bookHash) {
        await openVolumeDetail(state.activeVolumeDetail!);
      }
      if (state.activeSeriesDetail != null) {
        await openSeriesDetail(state.activeSeriesDetail!);
      }
      await loadVolumes(page: state.currentPage);
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al guardar tomo: $e',
      ));
    }
  }

  Future<void> syncVolumeFile(String bookHash) async {
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    try {
      await _repo.syncVolumeFile(bookHash);
      emit(state.copyWith(
        saving: false,
        successMessage: 'EPUB re-escaneado desde archivo OPF físico con éxito.',
      ));
      if (state.activeVolumeDetail != null && state.activeVolumeDetail!.bookHash == bookHash) {
        await openVolumeDetail(state.activeVolumeDetail!);
      }
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al sincronizar archivo: $e',
      ));
    }
  }

  Future<void> saveSeries(String seriesHash, Map<String, dynamic> payload) async {
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    try {
      await _repo.updateSeries(seriesHash, payload);
      emit(state.copyWith(
        saving: false,
        successMessage: 'Serie actualizada correctamente.',
      ));
      await loadSeriesCatalog(reset: true);
      if (state.activeSeriesDetail != null && state.activeSeriesDetail!.seriesHash == seriesHash) {
        await openSeriesDetail(state.activeSeriesDetail!);
      }
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al guardar serie: $e',
      ));
    }
  }

  Future<String?> createVolume(Map<String, dynamic> payload) async {
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    try {
      final res = await _repo.createVolume(payload);
      emit(state.copyWith(
        saving: false,
        successMessage: 'Tomo registrado correctamente en el catálogo.',
      ));
      await loadVolumes(page: 1);
      return res['book_id'] as String? ?? res['id'] as String?;
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al registrar tomo: $e',
      ));
      return null;
    }
  }

  Future<String?> createSeries({
    required String name,
    String? seriesSpanish,
    String? seriesEnglish,
    String? author,
    String? publisher,
    String? bookType,
    String? description,
  }) async {
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    try {
      final res = await _repo.createSeries({
        'name': name,
        if (seriesSpanish != null && seriesSpanish.isNotEmpty) 'series_spanish': seriesSpanish,
        if (seriesEnglish != null && seriesEnglish.isNotEmpty) 'series_english': seriesEnglish,
        if (author != null && author.isNotEmpty) 'author': author,
        if (publisher != null && publisher.isNotEmpty) 'publisher': publisher,
        if (bookType != null && bookType.isNotEmpty) 'book_type': bookType,
        if (description != null && description.isNotEmpty) 'description': description,
      });
      emit(state.copyWith(
        saving: false,
        successMessage: 'Serie "$name" registrada en el catálogo.',
      ));
      await loadSeriesCatalog(reset: true);
      await init();
      return res['series_id'] as String? ?? res['id'] as String?;
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al registrar serie: $e',
      ));
      return null;
    }
  }

  // Workgroups, Channels & Templates loaders
  Future<void> loadChannels() async {
    try {
      final channels = await _repo.getChannels();
      emit(state.copyWith(channels: channels));
    } catch (_) {}
  }

  Future<void> saveChannel(Map<String, dynamic> payload) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.saveChannel(payload);
      emit(state.copyWith(saving: false, successMessage: 'Canal guardado con éxito'));
      await loadChannels();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al guardar canal: $e'));
    }
  }

  Future<void> deleteChannel(int channelId) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.deleteChannel(channelId);
      emit(state.copyWith(saving: false, successMessage: 'Canal eliminado con éxito'));
      await loadChannels();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al eliminar canal: $e'));
    }
  }

  Future<void> loadTemplates() async {
    try {
      final templates = await _repo.getTemplates();
      emit(state.copyWith(templates: templates));
    } catch (_) {}
  }

  Future<void> saveTemplate(Map<String, dynamic> payload) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.saveTemplate(payload);
      emit(state.copyWith(saving: false, successMessage: 'Plantilla guardada con éxito'));
      await loadTemplates();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al guardar plantilla: $e'));
    }
  }

  Future<void> deleteTemplate(int templateId) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.deleteTemplate(templateId);
      emit(state.copyWith(saving: false, successMessage: 'Plantilla eliminada'));
      await loadTemplates();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al eliminar plantilla: $e'));
    }
  }

  Future<void> restoreTemplates() async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.restoreTemplates();
      emit(state.copyWith(saving: false, successMessage: 'Plantillas restauradas'));
      await loadTemplates();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al restaurar: $e'));
    }
  }

  Future<void> loadQueue([String? status]) async {
    try {
      final queue = await _repo.getQueue(status);
      emit(state.copyWith(queue: queue));
    } catch (_) {}
  }

  Future<void> cancelQueueItem(int id) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.cancelQueueItem(id);
      emit(state.copyWith(saving: false, successMessage: 'Publicación cancelada'));
      await loadQueue();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al cancelar: $e'));
    }
  }

  Future<void> retryQueueItem(int id) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.retryQueueItem(id);
      emit(state.copyWith(saving: false, successMessage: 'Reintento programado'));
      await loadQueue();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al reintentar: $e'));
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
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.updateQueueItem(
        id: id,
        scheduledFor: scheduledFor,
        channelId: channelId,
        templateId: templateId,
        customCaption: customCaption,
        sendAsFile: sendAsFile,
        status: status,
        immediate: immediate,
      );
      emit(state.copyWith(
        saving: false,
        successMessage: immediate ? 'Publicación enviada ahora mismo' : 'Horario de publicación actualizado con éxito',
      ));
      await loadQueue();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al actualizar publicación: $e'));
    }
  }

  Future<void> loadPosts() async {
    try {
      final posts = await _repo.getPostsHistory();
      emit(state.copyWith(posts: posts));
    } catch (_) {}
  }

  Future<void> syncFacebook() async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final res = await _repo.syncFacebookPublications();
      final count = res['new_publications_synced'] ?? res['synced_count'] ?? 0;
      emit(state.copyWith(
        saving: false,
        successMessage: 'Sincronización completada: $count posts vinculados',
      ));
      await loadPosts();
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: 'Error al sincronizar Facebook: $e'));
    }
  }

  Future<void> sendToTelegram(String bookHash) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final res = await _repo.sendToTelegram(bookHash);
      if (res['error'] != null) {
        emit(state.copyWith(
          saving: false,
          errorMessage: res['error'].toString(),
        ));
      } else {
        emit(state.copyWith(
          saving: false,
          successMessage: '¡Tomo enviado a tu Telegram exitosamente!',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al enviar a Telegram: $e',
      ));
    }
  }

  // Publishing methods
  Future<void> publishNow({
    required String bookHash,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool sendAsFile = true,
  }) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.publishNow(
        bookHash: bookHash,
        channelId: channelId,
        templateId: templateId,
        customCaption: customCaption,
        sendAsFile: sendAsFile,
      );
      emit(state.copyWith(
        saving: false,
        clearPublishingVolume: true,
        successMessage: '¡Publicación enviada exitosamente a Telegram!',
      ));
      await loadPosts();
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al publicar: $e',
      ));
    }
  }

  Future<void> schedulePublication({
    required String bookHash,
    required String scheduledAtIso,
    int? channelId,
    int? templateId,
    String? customCaption,
    bool sendAsFile = true,
  }) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.schedulePublication(
        bookHash: bookHash,
        scheduledAtIso: scheduledAtIso,
        channelId: channelId,
        templateId: templateId,
        customCaption: customCaption,
        sendAsFile: sendAsFile,
      );
      emit(state.copyWith(
        saving: false,
        clearPublishingVolume: true,
        successMessage: '¡Publicación agendada con éxito!',
      ));
      await loadQueue();
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        errorMessage: 'Error al agendar publicación: $e',
      ));
    }
  }

  // Compatibility Aliases
  Future<void> loadSeries({String? query, String? category, String? sortBy, int? page, bool reset = false}) =>
      loadSeriesCatalog(query: query, category: category, sortBy: sortBy, page: page, reset: reset);

  Future<void> syncVolumeFromDisk(String bookHash) => syncVolumeFile(bookHash);

  void clearNotifications() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
