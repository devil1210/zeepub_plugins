import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/common/utils/either.dart';
import '/features/epub_templater/domain/book_metadata.dart';
import '/features/epub_templater/domain/marc_relator.dart';

import '/features/metadata_editor/data/epub_metadata_repo.dart';
import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';
import '/inject_dependencies.dart';
import '../widgets/zeepub_server_config_dialog.dart';
import 'widgets/epub_metadata_validator_card.dart';
import 'widgets/series_destination_selector.dart';

/// Vista modular del Subidor / Vinculador de EPUBs de ZeePub.
///
/// Permite seleccionar un archivo EPUB local, auditar y validar sus metadatos
/// internos con calidad editorial, calcular su hash SHA-256 y asociarlo
/// a una serie existente o dar de alta una nueva serie en el backend.
class ZeepubUploaderView extends StatefulWidget {
  const ZeepubUploaderView({super.key});

  @override
  State<ZeepubUploaderView> createState() => _ZeepubUploaderViewState();
}

class _ZeepubUploaderViewState extends State<ZeepubUploaderView> {
  String? _selectedFilePath;
  String? _fileName;
  int _fileSizeBytes = 0;
  String? _sha256Hash;
  bool _isProcessing = false;
  String? _parseError;

  BookMetadata? _parsedMetadata;

  // Modo de Destino
  bool _isCreatingNewSeries = false;

  // Modo Existente
  ZeepubSeries? _selectedSeries;
  ZeepubVolume? _selectedVolume;
  final _existingVolumeNumberController = TextEditingController(text: '1');
  final _existingVolumeTitleController = TextEditingController();
  ZeepubVolume? _detectedExistingVolume;
  bool _replaceExisting = true;

  // Modo Nueva Serie Controllers
  final _newSeriesNameController = TextEditingController();
  final _newSeriesSpanishController = TextEditingController();
  final _newSeriesAuthorController = TextEditingController();
  final _newSeriesPublisherController = TextEditingController();
  final _newSeriesVolumeNumberController = TextEditingController(text: '1');
  final _newSeriesVolumeTitleController = TextEditingController();
  final _newSeriesDescController = TextEditingController();
  String _selectedBookType = 'Novela Ligera';

  @override
  void initState() {
    super.initState();
    _existingVolumeNumberController.addListener(_onFieldChanged);
    _newSeriesNameController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ZeepubEditorialCubit>();
      if (cubit.state.seriesList.isEmpty) {
        cubit.init();
      }
    });
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _existingVolumeNumberController.removeListener(_onFieldChanged);
    _newSeriesNameController.removeListener(_onFieldChanged);
    _existingVolumeNumberController.dispose();
    _existingVolumeTitleController.dispose();
    _newSeriesNameController.dispose();
    _newSeriesSpanishController.dispose();
    _newSeriesAuthorController.dispose();
    _newSeriesPublisherController.dispose();
    _newSeriesVolumeNumberController.dispose();
    _newSeriesVolumeTitleController.dispose();
    _newSeriesDescController.dispose();
    super.dispose();
  }

  Future<void> _pickEpubFile() async {
    try {
      final path = (await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['epub'],
        dialogTitle: 'Selecciona un archivo EPUB',
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      )).map((f) => f.path).whereType<String>().firstOrNull;

      if (path == null) return;

      setState(() {
        _isProcessing = true;
        _parseError = null;
        _selectedFilePath = path;
        _fileName = path.split(Platform.pathSeparator).last;
      });

      // 1. Cálculo de hash y tamaño
      final file = File(path);
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      // 2. Extracción y Validación de Metadatos con EpubMetadataRepository
      final repo = getIt<EpubMetadataRepository>();
      final loadRes = await repo.load(path);

      BookMetadata? extractedMeta;
      String? loadErr;

      if (loadRes case Right(value: final meta)) {
        extractedMeta = meta;
        repo.unload(path);
      } else if (loadRes case Left(value: final err)) {
        loadErr = err;
        repo.unload(path);
      }

      setState(() {
        _fileSizeBytes = bytes.length;
        _sha256Hash = hash;
        _parsedMetadata = extractedMeta;
        _parseError = loadErr;
        _isProcessing = false;
      });

      // 3. Auto-rellenado inteligente de campos y detección de EPUB existente
      if (extractedMeta != null && mounted) {
        _applyIntelligentMatching(extractedMeta);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _parseError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leyendo el archivo EPUB: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _applyIntelligentMatching(BookMetadata meta) {
    final cubit = context.read<ZeepubEditorialCubit>();
    final seriesList = cubit.state.seriesList;
    final allVolumes = cubit.state.volumes;

    final epubSeries = meta.series.trim();
    final epubAuthor = meta.actors.where((a) => a.isCreator || a.name.isNotEmpty).firstOrNull?.name ?? '';
    final epubPublisher = meta.publishers.isNotEmpty ? meta.publishers.first : '';
    final epubVolume = meta.seriesIndex.trim().isNotEmpty ? meta.seriesIndex.trim() : '1';
    final epubTitle = meta.title.trim();
    final epubDesc = meta.description.trim();

    // 1. Detección de coincidencia por serie
    ZeepubSeries? matchedSeries;
    if (epubSeries.isNotEmpty) {
      matchedSeries = seriesList.where((s) {
        final normS = s.name.toLowerCase().trim();
        final normE = epubSeries.toLowerCase().trim();
        return normS == normE ||
            s.seriesSpanish.toLowerCase().trim() == normE ||
            s.seriesEnglish.toLowerCase().trim() == normE;
      }).firstOrNull;
    }

    // 2. Detección de tomo existente (por hash o por serie + número de volumen)
    ZeepubVolume? matchedVol;
    if (_sha256Hash != null) {
      matchedVol = allVolumes.where((v) => v.bookHash == _sha256Hash || v.id == _sha256Hash).firstOrNull;
    }

    if (matchedVol == null && matchedSeries != null) {
      final volNum = double.tryParse(epubVolume);
      if (volNum != null) {
        matchedVol = allVolumes.where((v) {
          final isSameSeries = v.seriesId == matchedSeries!.id ||
              v.seriesName.toLowerCase().trim() == matchedSeries.name.toLowerCase().trim();
          if (!isSameSeries) return false;
          return v.volume != null && (v.volume! - volNum).abs() < 0.001;
        }).firstOrNull;
      }
    }

    if (matchedVol != null && matchedSeries == null) {
      matchedSeries = seriesList.where((s) => s.id == matchedVol!.seriesId || s.name == matchedVol.seriesName).firstOrNull;
    }

    if (matchedSeries != null) {
      // Coincidencia encontrada: asociar a la serie existente
      setState(() {
        _isCreatingNewSeries = false;
        _selectedSeries = matchedSeries;
        _selectedVolume = matchedVol;
        _detectedExistingVolume = matchedVol;
        _replaceExisting = matchedVol != null;
        _existingVolumeNumberController.text = epubVolume;
        _existingVolumeTitleController.text = epubTitle;
      });
    } else {
      // No existe en catálogo: proponer crear nueva serie y pre-rellenar
      setState(() {
        _isCreatingNewSeries = true;
        _selectedSeries = null;
        _selectedVolume = null;
        _detectedExistingVolume = null;
        _replaceExisting = false;
        _newSeriesNameController.text = epubSeries.isNotEmpty ? epubSeries : epubTitle;
        _newSeriesSpanishController.text = epubSeries.isNotEmpty ? epubSeries : epubTitle;
        _newSeriesAuthorController.text = epubAuthor;
        _newSeriesPublisherController.text = epubPublisher;
        _newSeriesVolumeNumberController.text = epubVolume;
        _newSeriesVolumeTitleController.text = epubTitle;
        _newSeriesDescController.text = epubDesc;
        _selectedBookType = SeriesDestinationSelector.normalizeBookType(meta.bookType);
      });
    }
  }

  Map<String, dynamic> _buildVolumePayload({
    required String seriesId,
    required double? volumeNum,
    required String title,
    String? bookHash,
  }) {
    final meta = _parsedMetadata;
    final author = meta?.actors.where((a) => a.isCreator || a.name.isNotEmpty).firstOrNull?.name ?? '';
    final illustrator = meta?.actors
            .where((a) => a.roles.any((r) => r == MarcRelator.ill || r == MarcRelator.art))
            .firstOrNull
            ?.name ??
        '';
    final translator = meta?.actors
            .where((a) => a.isTranslator || a.roles.contains(MarcRelator.trl))
            .firstOrNull
            ?.name ??
        '';
    final publisher = meta?.publishers.isNotEmpty == true ? meta!.publishers.first : '';
    final desc = meta?.description ?? '';
    final isbn = (meta?.isbn13.isNotEmpty == true)
        ? meta!.isbn13
        : (meta?.isbn10.isNotEmpty == true ? meta!.isbn10 : (meta?.asin ?? ''));
    final uuid = meta?.identifier ?? '';
    final pubDate = meta?.date;

    return {
      'series_id': seriesId,
      'volume': volumeNum,
      'title': title.isNotEmpty ? title : (meta?.title ?? 'Sin título'),
      if (bookHash != null && bookHash.isNotEmpty) 'book_hash': bookHash,
      if (_sha256Hash != null) 'id': _sha256Hash,
      'file_size': _fileSizeBytes,
      if (_fileName != null) 'filename': _fileName,
      if (_selectedFilePath != null) 'filepath': _selectedFilePath,
      if (author.isNotEmpty) 'author': author,
      if (illustrator.isNotEmpty) 'illustrator': illustrator,
      if (translator.isNotEmpty) 'translator': translator,
      if (publisher.isNotEmpty) 'publisher': publisher,
      if (desc.isNotEmpty) 'description': desc,
      if (isbn.isNotEmpty) 'isbn': isbn,
      if (uuid.isNotEmpty) 'uuid': uuid,
      if (pubDate != null && pubDate.isNotEmpty) 'published_date': pubDate,
      'color_mode': 'color',
    };
  }

  Future<void> _handleUploadAndSync(ZeepubEditorialCubit cubit) async {
    if (_isCreatingNewSeries) {
      // Modo: Crear nueva serie y registrar
      final name = _newSeriesNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, ingresa el nombre de la nueva serie.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final seriesId = await cubit.createSeries(
        name: name,
        seriesSpanish: _newSeriesSpanishController.text.trim(),
        author: _newSeriesAuthorController.text.trim(),
        publisher: _newSeriesPublisherController.text.trim(),
        bookType: SeriesDestinationSelector.normalizeBookType(_selectedBookType),
        description: _newSeriesDescController.text.trim(),
      );

      if (seriesId != null) {
        final volNum = double.tryParse(_newSeriesVolumeNumberController.text.trim());
        final volTitle = _newSeriesVolumeTitleController.text.trim();
        final payload = _buildVolumePayload(
          seriesId: seriesId,
          volumeNum: volNum,
          title: volTitle.isNotEmpty ? volTitle : name,
          bookHash: _sha256Hash,
        );

        final volId = await cubit.createVolume(payload);
        if (volId != null) {
          await cubit.syncVolumeFile(volId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Serie "$name" y Tomo Vol. ${volNum ?? 1} dados de alta correctamente.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } else {
      // Modo: Serie Existente
      if (_selectedSeries == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecciona o busca una serie del catálogo.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final volNumStr = _existingVolumeNumberController.text.trim();
      if (volNumStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, ingresa el número de volumen (entero o decimal con .).'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final volNum = double.tryParse(volNumStr);
      final volTitle = _existingVolumeTitleController.text.trim();

      if (_replaceExisting && _detectedExistingVolume != null) {
        // Actualizar/Reemplazar tomo existente (escaneo individual)
        final targetHash = _detectedExistingVolume!.bookHash;
        final payload = _buildVolumePayload(
          seriesId: _selectedSeries!.id,
          volumeNum: volNum ?? _detectedExistingVolume!.volume,
          title: volTitle.isNotEmpty ? volTitle : _detectedExistingVolume!.title,
          bookHash: targetHash,
        );

        await cubit.saveVolume(targetHash, payload);
        await cubit.syncVolumeFile(targetHash);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tomo Vol. ${volNum ?? _detectedExistingVolume!.volume} actualizado y sincronizado en ${_selectedSeries!.name}.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        // Registrar como nuevo volumen en esta serie
        final payload = _buildVolumePayload(
          seriesId: _selectedSeries!.id,
          volumeNum: volNum,
          title: volTitle.isNotEmpty ? volTitle : _selectedSeries!.name,
          bookHash: _sha256Hash,
        );

        final volId = await cubit.createVolume(payload);
        if (volId != null) {
          await cubit.syncVolumeFile(volId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nuevo tomo Vol. $volNum registrado y sincronizado en ${_selectedSeries!.name}.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<ZeepubEditorialCubit, ZeepubEditorialState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: cs.error,
              action: SnackBarAction(
                label: 'OK',
                textColor: cs.onError,
                onPressed: () => context.read<ZeepubEditorialCubit>().clearNotifications(),
              ),
            ),
          );
          context.read<ZeepubEditorialCubit>().clearNotifications();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green.shade700,
            ),
          );
          context.read<ZeepubEditorialCubit>().clearNotifications();
        }
      },
      builder: (context, state) {
        final cubit = context.read<ZeepubEditorialCubit>();

        final availableVolumes = _selectedSeries != null
            ? state.volumes
                .where((v) => v.seriesId == _selectedSeries!.id || v.seriesName == _selectedSeries!.name)
                .toList()
            : state.volumes;

        final canSubmit = _selectedFilePath != null &&
            !state.saving &&
            (!_isCreatingNewSeries
                ? (_selectedSeries != null && _existingVolumeNumberController.text.trim().isNotEmpty)
                : _newSeriesNameController.text.trim().isNotEmpty);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.cloud_upload_rounded, color: Color(0xFF818CF8)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subidor de EPUBs', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(
                      'Validación de metadatos, cálculo de hash y vinculación con ZeePub',
                      style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Ajustes del Servidor',
                onPressed: () => showZeepubServerConfigDialog(
                  context,
                  currentUrl: state.baseUrl,
                  currentTgId: state.telegramUserId,
                  currentScale: state.coverScale,
                  cubit: cubit,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Paso 1: Selección del archivo EPUB
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.file_present_rounded, color: Color(0xFF818CF8)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('1. Archivo EPUB Local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    _selectedFilePath == null
                                        ? 'Selecciona el libro para analizar sus metadatos e integridad'
                                        : 'Archivo cargado para validación',
                                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              icon: const Icon(Icons.folder_open_rounded, size: 18),
                              label: Text(_selectedFilePath == null ? 'Elegir EPUB' : 'Cambiar EPUB'),
                              onPressed: _isProcessing ? null : _pickEpubFile,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Auditoría y Validación de Metadatos
                    EpubMetadataValidatorCard(
                      metadata: _parsedMetadata,
                      fileName: _fileName,
                      filePath: _selectedFilePath,
                      fileSizeBytes: _fileSizeBytes,
                      sha256Hash: _sha256Hash,
                      isProcessing: _isProcessing,
                      error: _parseError,
                    ),

                    const SizedBox(height: 18),

                    // Paso 2: Destino (Serie Existente o Nueva Serie)
                    SeriesDestinationSelector(
                      isCreatingNew: _isCreatingNewSeries,
                      onModeChanged: (val) => setState(() => _isCreatingNewSeries = val),
                      seriesList: state.seriesList,
                      selectedSeries: _selectedSeries,
                      onSeriesChanged: (val) => setState(() {
                        _selectedSeries = val;
                        _selectedVolume = null;
                        _detectedExistingVolume = null;
                      }),
                      availableVolumes: availableVolumes,
                      selectedVolume: _selectedVolume,
                      onVolumeChanged: (val) => setState(() => _selectedVolume = val),
                      existingVolumeNumberController: _existingVolumeNumberController,
                      existingVolumeTitleController: _existingVolumeTitleController,
                      detectedExistingVolume: _detectedExistingVolume,
                      replaceExisting: _replaceExisting,
                      onReplaceExistingChanged: (val) => setState(() => _replaceExisting = val),
                      newSeriesNameController: _newSeriesNameController,
                      newSeriesSpanishController: _newSeriesSpanishController,
                      newSeriesAuthorController: _newSeriesAuthorController,
                      newSeriesPublisherController: _newSeriesPublisherController,
                      newSeriesVolumeNumberController: _newSeriesVolumeNumberController,
                      newSeriesVolumeTitleController: _newSeriesVolumeTitleController,
                      newSeriesDescController: _newSeriesDescController,
                      selectedBookType: _selectedBookType,
                      onBookTypeChanged: (val) => setState(() => _selectedBookType = val),
                    ),

                    const SizedBox(height: 24),

                    // Botón de acción principal
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xFF6366F1),
                      ),
                      icon: state.saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(_isCreatingNewSeries ? Icons.add_task_rounded : Icons.sync_rounded),
                      label: Text(
                        state.saving
                            ? 'Procesando con ZeePub...'
                            : _isCreatingNewSeries
                                ? 'Dar de Alta Serie y Vincular EPUB'
                                : (_replaceExisting && _detectedExistingVolume != null)
                                    ? 'Actualizar Metadatos y Vincular EPUB'
                                    : 'Registrar Tomo y Vincular EPUB',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: canSubmit ? () => _handleUploadAndSync(cubit) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
