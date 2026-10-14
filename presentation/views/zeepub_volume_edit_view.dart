import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/common/theme/app_dimensions.dart';
import '/common/utils/input_formatters.dart';
import '/common/utils/uuid_v7.dart';
import '/common/widgets/app_text_field.dart';
import '/common/widgets/editable_list.dart';
import '/common/widgets/form_section.dart';
import '/common/widgets/outlined_dropdown.dart';
import '/common/widgets/responsive_row.dart';
import '/common/widgets/selection_pill.dart';
import '/common/widgets/toggle_field.dart';
import '../../../epub_templater/data/opf_metadata.dart';
import '../../../epub_templater/domain/book_metadata.dart';
import '../../../epub_templater/domain/marc_relator.dart';
import '../../../epub_templater/domain/subjects.dart';
import '../../../epub_templater/domain/title_languages.dart';
import '../../../epub_templater/presentation/views/widgets/amazon_lookup.dart';
import '../../data/models/zeepub_series.dart';
import '../../data/models/zeepub_volume.dart';
import '../../data/models/zeepub_workgroup.dart';
import '../cubit/zeepub_editorial_cubit.dart';
import '../cubit/zeepub_editorial_state.dart';

class ZeepubVolumeEditView extends StatefulWidget {
  final ZeepubVolume volume;
  final List<ZeepubVolume> volumes;
  final List<ZeepubSeries> seriesList;
  final List<ZeepubWorkgroup> workgroups;
  final String baseUrl;
  final VoidCallback onBack;

  const ZeepubVolumeEditView({
    super.key,
    required this.volume,
    this.volumes = const [],
    this.seriesList = const [],
    required this.workgroups,
    required this.baseUrl,
    required this.onBack,
  });

  @override
  State<ZeepubVolumeEditView> createState() => _ZeepubVolumeEditViewState();
}

class _ZeepubVolumeEditViewState extends State<ZeepubVolumeEditView> {
  double _leftPanelWidth = 320.0;
  String? _customCoverUrl;

  // Identifiers
  late String _asin;
  late String _isbn13;
  late String _isbn10;
  late String _identifier;

  // Series & Title
  OriginalLanguage? _originalLanguage;
  late bool _isStandalone;
  late String _series;
  late String _seriesSpanish;
  late String _seriesEnglish;
  late String _seriesRomaji;
  late String _seriesNative;
  late String _volumeNumber;
  late String _title;
  late String _titleSpanish;
  late String _titleEnglish;
  late String _titleRomaji;
  late String _titleNative;
  late String _titleSort;

  // People & Publication
  late List<Actor> _actors;
  late String _bookLanguage;
  late String _bookType;
  late String _publishDate;
  late List<String> _publishers;
  late String _colorMode;
  late bool _isUncensored;

  // Description & Classification
  late String _description;
  Demographic? _demographic;
  late Set<String> _selectedGenres;
  int? _rating;
  ZeepubVolume? _lastLoadedDetail;

  @override
  void initState() {
    super.initState();
    _loadFromVolume(widget.volume);
  }

  void _loadFromVolume(ZeepubVolume v) {
    _customCoverUrl = v.coverUrl;
    _asin = v.asin ?? '';

    final rawIsbn = (v.isbn ?? '').trim();
    if (rawIsbn.replaceAll('-', '').length == 13 || rawIsbn.startsWith('978')) {
      _isbn13 = rawIsbn;
      _isbn10 = '';
    } else if (rawIsbn.replaceAll('-', '').length == 10) {
      _isbn10 = rawIsbn;
      _isbn13 = '';
    } else {
      _isbn13 = rawIsbn;
      _isbn10 = '';
    }

    String cleanId = (v.uuid ?? '').trim();
    if (cleanId.startsWith('urn:uuid:')) {
      cleanId = cleanId.substring('urn:uuid:'.length);
    }
    _identifier = cleanId.isNotEmpty ? cleanId : v.bookHash;

    _originalLanguage = OriginalLanguage.ja;
    _isStandalone = v.volume == null && v.seriesName.isEmpty;
    _series = v.seriesName;
    _seriesSpanish = v.seriesSpanish ?? '';
    _seriesEnglish = v.seriesName;
    _seriesRomaji = v.seriesRomaji ?? '';
    _seriesNative = v.japaneseTitle;
    _volumeNumber = v.volume != null ? (v.volume! % 1 == 0 ? v.volume!.toInt().toString() : v.volume!.toString()) : '';

    _title = v.title;
    _titleSpanish = v.spanishTitle;
    _titleEnglish = v.englishTitle.isNotEmpty ? v.englishTitle : v.title;
    _titleRomaji = v.romajiTitle;
    _titleNative = v.japaneseTitle;
    _titleSort = '';

    _actors = [];
    if (v.author != null && v.author!.trim().isNotEmpty) {
      _actors.add(Actor(name: v.author!.trim(), roles: const [MarcRelator.aut], fileAs: fileAsFor(v.author!.trim())));
    }
    if (v.illustrator != null && v.illustrator!.trim().isNotEmpty) {
      _actors.add(Actor(name: v.illustrator!.trim(), roles: const [MarcRelator.ill], fileAs: fileAsFor(v.illustrator!.trim())));
    }
    if (v.translator != null && v.translator!.trim().isNotEmpty) {
      _actors.add(Actor(name: v.translator!.trim(), roles: const [MarcRelator.trl], fileAs: fileAsFor(v.translator!.trim())));
    }
    if (v.layoutBy != null && v.layoutBy!.trim().isNotEmpty) {
      _actors.add(Actor(name: v.layoutBy!.trim(), roles: const [MarcRelator.mrk], fileAs: fileAsFor(v.layoutBy!.trim())));
    }
    if (_actors.isEmpty) {
      _actors.add(const Actor(roles: [MarcRelator.aut]));
    }

    _bookLanguage = v.language.isNotEmpty ? v.language : 'es';
    _bookType = 'Novela ligera';
    _publishDate = v.publishedDate ?? '';
    _publishers = [];
    if (v.publisher != null && v.publisher!.trim().isNotEmpty) {
      _publishers.add(v.publisher!.trim());
    } else {
      _publishers.add('');
    }

    final rawColor = (v.colorMode ?? 'mono').trim().toLowerCase();
    _colorMode = (rawColor == 'color' || rawColor == 'colour') ? 'color' : 'mono';
    _isUncensored = v.isUncensored;

    _description = v.description ?? '';
    _demographic = null;
    _selectedGenres = Set.from(v.tags);
    _rating = v.rating > 0 ? v.rating.round() : null;
  }

  void _onSeriesSelected(String selectedName) {
    final match = widget.seriesList.where((s) =>
        s.seriesEnglish.toLowerCase() == selectedName.toLowerCase() ||
        s.name.toLowerCase() == selectedName.toLowerCase() ||
        s.seriesSpanish.toLowerCase() == selectedName.toLowerCase()).firstOrNull;

    setState(() {
      _seriesEnglish = selectedName;
      _series = selectedName;
      if (match != null) {
        if (match.seriesSpanish.isNotEmpty) _seriesSpanish = match.seriesSpanish;
        if (match.author.isNotEmpty) {
          final autIdx = _actors.indexWhere((a) => a.roles.contains(MarcRelator.aut));
          if (autIdx >= 0) {
            _actors[autIdx] = _actors[autIdx].copyWith(name: match.author, fileAs: fileAsFor(match.author));
          } else {
            _actors.insert(0, Actor(name: match.author, roles: const [MarcRelator.aut], fileAs: fileAsFor(match.author)));
          }
        }
        if (match.illustrator.isNotEmpty) {
          final illIdx = _actors.indexWhere((a) => a.roles.contains(MarcRelator.ill));
          if (illIdx >= 0) {
            _actors[illIdx] = _actors[illIdx].copyWith(name: match.illustrator, fileAs: fileAsFor(match.illustrator));
          } else {
            _actors.add(Actor(name: match.illustrator, roles: const [MarcRelator.ill], fileAs: fileAsFor(match.illustrator)));
          }
        }
        if (match.publisher.isNotEmpty) {
          _publishers = [match.publisher];
        }
        if (_description.isEmpty && match.description != null && match.description!.isNotEmpty) {
          _description = descriptionFromHtml(match.description!);
        }
      }
    });
  }

  void _onTitleEnglishSelected(String selectedTitle) {
    final volMatch = widget.volumes.where((v) =>
        v.englishTitle.toLowerCase() == selectedTitle.toLowerCase() ||
        v.title.toLowerCase() == selectedTitle.toLowerCase() ||
        v.spanishTitle.toLowerCase() == selectedTitle.toLowerCase()).firstOrNull;

    final seriesMatch = widget.seriesList.where((s) =>
        s.seriesEnglish.toLowerCase() == selectedTitle.toLowerCase() ||
        s.name.toLowerCase() == selectedTitle.toLowerCase() ||
        s.seriesSpanish.toLowerCase() == selectedTitle.toLowerCase()).firstOrNull;

    setState(() {
      _titleEnglish = selectedTitle;
      _title = selectedTitle;

      if (volMatch != null) {
        if (volMatch.spanishTitle.isNotEmpty) {
          _titleSpanish = volMatch.spanishTitle;
        }
        if (_seriesEnglish.isEmpty && volMatch.seriesName.isNotEmpty) {
          _seriesEnglish = volMatch.seriesName;
          _series = volMatch.seriesName;
        }
        if (_seriesSpanish.isEmpty && volMatch.seriesSpanish != null && volMatch.seriesSpanish!.isNotEmpty) {
          _seriesSpanish = volMatch.seriesSpanish!;
        }
        if (_volumeNumber.isEmpty && volMatch.volume != null) {
          _volumeNumber = volMatch.volume! % 1 == 0 ? volMatch.volume!.toInt().toString() : volMatch.volume!.toString();
        }
        if (volMatch.author != null && volMatch.author!.isNotEmpty) {
          final autIdx = _actors.indexWhere((a) => a.roles.contains(MarcRelator.aut));
          if (autIdx >= 0) {
            _actors[autIdx] = _actors[autIdx].copyWith(name: volMatch.author!, fileAs: fileAsFor(volMatch.author!));
          } else {
            _actors.insert(0, Actor(name: volMatch.author!, roles: const [MarcRelator.aut], fileAs: fileAsFor(volMatch.author!)));
          }
        }
        if (volMatch.illustrator != null && volMatch.illustrator!.isNotEmpty) {
          final illIdx = _actors.indexWhere((a) => a.roles.contains(MarcRelator.ill));
          if (illIdx >= 0) {
            _actors[illIdx] = _actors[illIdx].copyWith(name: volMatch.illustrator!, fileAs: fileAsFor(volMatch.illustrator!));
          } else {
            _actors.add(Actor(name: volMatch.illustrator!, roles: const [MarcRelator.ill], fileAs: fileAsFor(volMatch.illustrator!)));
          }
        }
        if (volMatch.publisher != null && volMatch.publisher!.isNotEmpty) {
          _publishers = [volMatch.publisher!];
        }
        if (_description.isEmpty && volMatch.description != null && volMatch.description!.isNotEmpty) {
          _description = descriptionFromHtml(volMatch.description!);
        }
      } else if (seriesMatch != null) {
        if (seriesMatch.seriesSpanish.isNotEmpty) {
          _titleSpanish = seriesMatch.seriesSpanish;
        }
        if (_seriesEnglish.isEmpty) {
          _seriesEnglish = seriesMatch.seriesEnglish.isNotEmpty ? seriesMatch.seriesEnglish : seriesMatch.name;
          _series = _seriesEnglish;
        }
        if (_seriesSpanish.isEmpty && seriesMatch.seriesSpanish.isNotEmpty) {
          _seriesSpanish = seriesMatch.seriesSpanish;
        }
        _onSeriesSelected(_seriesEnglish);
      }
    });
  }

  void _onTitleSpanishSelected(String selectedSpanishTitle) {
    final volMatch = widget.volumes.where((v) =>
        v.spanishTitle.toLowerCase() == selectedSpanishTitle.toLowerCase()).firstOrNull;

    final seriesMatch = widget.seriesList.where((s) =>
        s.seriesSpanish.toLowerCase() == selectedSpanishTitle.toLowerCase()).firstOrNull;

    setState(() {
      _titleSpanish = selectedSpanishTitle;

      if (volMatch != null) {
        if (_titleEnglish.isEmpty && volMatch.englishTitle.isNotEmpty) {
          _titleEnglish = volMatch.englishTitle;
          _title = volMatch.englishTitle;
        }
        if (_seriesEnglish.isEmpty && volMatch.seriesName.isNotEmpty) {
          _seriesEnglish = volMatch.seriesName;
          _series = volMatch.seriesName;
        }
        if (_seriesSpanish.isEmpty && volMatch.seriesSpanish != null && volMatch.seriesSpanish!.isNotEmpty) {
          _seriesSpanish = volMatch.seriesSpanish!;
        }
      } else if (seriesMatch != null) {
        if (_titleEnglish.isEmpty) {
          _titleEnglish = seriesMatch.seriesEnglish.isNotEmpty ? seriesMatch.seriesEnglish : seriesMatch.name;
          _title = _titleEnglish;
        }
        if (_seriesSpanish.isEmpty) {
          _seriesSpanish = seriesMatch.seriesSpanish;
        }
        if (_seriesEnglish.isEmpty) {
          _seriesEnglish = seriesMatch.seriesEnglish.isNotEmpty ? seriesMatch.seriesEnglish : seriesMatch.name;
          _series = _seriesEnglish;
        }
      }
    });
  }

  BookMetadata _toBookMetadata() {
    return BookMetadata(
      identifier: _identifier,
      language: _bookLanguage,
      title: _titleEnglish.isNotEmpty ? _titleEnglish : _title,
      asin: _asin,
      isbn13: _isbn13,
      isbn10: _isbn10,
      series: _seriesEnglish.isNotEmpty ? _seriesEnglish : _series,
      seriesIndex: _volumeNumber,
      actors: _actors,
      publishers: _publishers,
      description: _description,
      originalLanguage: _originalLanguage,
      demographic: _demographic,
      genres: _selectedGenres.toList(),
      bookType: _bookType,
    );
  }

  void _applyAiSuggestion(ZeepubEditorialState state) {
    final s = state.latestAiSuggestion;
    if (s == null) return;
    setState(() {
      if (s.spanishTitle.isNotEmpty) {
        _titleSpanish = s.spanishTitle;
        _seriesSpanish = s.spanishTitle;
      }
      if (s.englishTitle.isNotEmpty) {
        _titleEnglish = s.englishTitle;
        _seriesEnglish = s.englishTitle;
      }
      if (s.author.isNotEmpty) {
        final existingAutIdx = _actors.indexWhere((a) => a.roles.contains(MarcRelator.aut));
        if (existingAutIdx >= 0) {
          _actors[existingAutIdx] = _actors[existingAutIdx].copyWith(name: s.author, fileAs: fileAsFor(s.author));
        } else {
          _actors.insert(0, Actor(name: s.author, roles: const [MarcRelator.aut], fileAs: fileAsFor(s.author)));
        }
      }
      if (s.volume != null) {
        _volumeNumber = s.volume! % 1 == 0 ? s.volume!.toInt().toString() : s.volume!.toString();
      }
      if (s.demography.isNotEmpty) {
        _demographic = Demographic.values.where((d) => d.name.toLowerCase() == s.demography.toLowerCase() || d.label.toLowerCase().contains(s.demography.toLowerCase())).firstOrNull ?? _demographic;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('✨ Sugerencia de IA aplicada a los campos'),
      ),
    );
  }

  String _buildCoverUrl() {
    final rawCover = _customCoverUrl ?? widget.volume.coverUrl;
    if (rawCover == null || rawCover.isEmpty) return '';
    if (rawCover.startsWith('http')) return rawCover;
    final cleanBase = widget.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = rawCover.startsWith('/') ? rawCover : '/$rawCover';
    return '$cleanBase$cleanPath';
  }

  Future<void> _pickAndUploadCover() async {
    final cubit = context.read<ZeepubEditorialCubit>();
    final paths = (await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      dialogTitle: 'Seleccionar nueva portada para el tomo',
      windowsOptions: const WindowsOptions(lockParentWindow: true),
      linuxOptions: const LinuxOptions(lockParentWindow: true),
    )).map((f) => f.path).whereType<String>().toList();

    if (paths.isNotEmpty) {
      final filePath = paths.first;
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final filename = filePath.split(Platform.pathSeparator).last;
        final res = await cubit.uploadCover(widget.volume.bookHash, bytes, filename);
        final newUrl = res?['cover_url']?.toString();
        if (newUrl != null && mounted) {
          setState(() {
            _customCoverUrl = newUrl;
          });
        }
      }
    }
  }

  void _showCustomUrlDialog() {
    final ctrl = TextEditingController(text: _customCoverUrl ?? widget.volume.coverUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link_rounded),
            SizedBox(width: 8),
            Text('Cambiar URL de Portada'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'URL de la imagen de portada',
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _customCoverUrl = val;
                });
                context.read<ZeepubEditorialCubit>().saveVolume(widget.volume.bookHash, {'cover_url': val});
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Aplicar URL'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_isStandalone && _seriesSpanish.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('⚠️ El campo "Serie en español" es obligatorio'),
        ),
      );
      return;
    }
    if (_titleSpanish.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('⚠️ El campo "Título en español" es obligatorio'),
        ),
      );
      return;
    }

    final cubit = context.read<ZeepubEditorialCubit>();

    final author = _actors.where((a) => a.roles.contains(MarcRelator.aut)).firstOrNull?.name.trim();
    final illustrator = _actors.where((a) => a.roles.contains(MarcRelator.ill)).firstOrNull?.name.trim();
    final translator = _actors.where((a) => a.roles.contains(MarcRelator.trl)).firstOrNull?.name.trim();
    final layoutBy = _actors.where((a) => a.roles.contains(MarcRelator.mrk)).firstOrNull?.name.trim();
    final publisher = _publishers.where((p) => p.trim().isNotEmpty).firstOrNull?.trim();

    final payload = <String, dynamic>{
      'title': _titleEnglish.isNotEmpty ? _titleEnglish : _title,
      'spanish_title': _titleSpanish.trim(),
      'english_title': _titleEnglish.trim(),
      'romaji_title': _titleRomaji.trim(),
      'series_name': _isStandalone ? null : (_seriesEnglish.isNotEmpty ? _seriesEnglish.trim() : _series.trim()),
      'series_spanish': _isStandalone ? null : _seriesSpanish.trim(),
      'series_romaji': _seriesRomaji.trim(),
      'volume': _volumeNumber.isNotEmpty ? double.tryParse(_volumeNumber) : null,
      'author': author,
      'illustrator': illustrator,
      'translator': translator,
      'layout_by': layoutBy,
      'publisher': publisher,
      'description': _description.trim(),
      'color_mode': _colorMode,
      'is_uncensored': _isUncensored,
      'isbn': _isbn13.isNotEmpty ? _isbn13.trim() : (_isbn10.isNotEmpty ? _isbn10.trim() : null),
      'asin': _asin.isNotEmpty ? _asin.trim() : null,
      'uuid': _identifier.isNotEmpty ? _identifier.trim() : null,
      'published_date': _publishDate.isNotEmpty ? _publishDate.trim() : null,
    };

    await cubit.saveVolume(widget.volume.bookHash, payload);

    if (!_isStandalone && (_seriesSpanish.isNotEmpty || _seriesEnglish.isNotEmpty)) {
      final seriesName = _seriesEnglish.isNotEmpty ? _seriesEnglish : _series;
      final match = widget.seriesList.where((s) =>
          s.seriesEnglish.toLowerCase() == seriesName.toLowerCase() ||
          s.name.toLowerCase() == seriesName.toLowerCase() ||
          s.seriesSpanish.toLowerCase() == _seriesSpanish.toLowerCase()).firstOrNull;

      if (match != null) {
        final seriesPayload = <String, dynamic>{
          'name': match.name,
          'series_spanish': _seriesSpanish.isNotEmpty ? _seriesSpanish : match.seriesSpanish,
          'series_english': _seriesEnglish.isNotEmpty ? _seriesEnglish : match.seriesEnglish,
          if (author != null && author.isNotEmpty) 'author': author,
          if (illustrator != null && illustrator.isNotEmpty) 'illustrator': illustrator,
          if (publisher != null && publisher.isNotEmpty) 'publisher': publisher,
        };
        await cubit.saveSeries(match.seriesHash, seriesPayload);
      }
    }
  }

  void _openPublishDialog() {
    context.read<ZeepubEditorialCubit>().openPublisher(widget.volume);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final coverUrl = _buildCoverUrl();


    return BlocConsumer<ZeepubEditorialCubit, ZeepubEditorialState>(
      listener: (BuildContext context, ZeepubEditorialState state) {
        if (state.latestAiSuggestion != null) {
          _applyAiSuggestion(state);
        }
        if (state.activeVolumeDetail != null &&
            state.activeVolumeDetail!.bookHash == widget.volume.bookHash &&
            state.activeVolumeDetail != _lastLoadedDetail) {
          _lastLoadedDetail = state.activeVolumeDetail;
          setState(() {
            _loadFromVolume(state.activeVolumeDetail!);
          });
        }
      },
      builder: (BuildContext context, ZeepubEditorialState state) {
        final cubit = context.read<ZeepubEditorialCubit>();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver a Tomos',
              onPressed: widget.onBack,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.volume.englishTitle.isNotEmpty
                      ? widget.volume.englishTitle
                      : (widget.volume.seriesName.isNotEmpty ? widget.volume.seriesName : widget.volume.title),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.volume.volume != null
                      ? 'Volumen ${widget.volume.volume! % 1 == 0 ? widget.volume.volume!.toInt() : widget.volume.volume}'
                      : (widget.volume.edition ?? 'Volumen'),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              IconButton.filledTonal(
                icon: state.aiLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                tooltip: 'Sugerir con IA (Gemini)',
                onPressed: state.aiLoading
                    ? null
                    : () => cubit.requestAiSuggestion(
                          _titleEnglish.isNotEmpty ? _titleEnglish : (_title.isNotEmpty ? _title : widget.volume.title),
                        ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Publicar'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _openPublishDialog,
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: state.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: const Text('Guardar'),
                onPressed: state.saving ? null : _handleSave,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT PANEL: Resizable Cover, File Info, Quick Actions
              SizedBox(
                width: _leftPanelWidth,
                child: Container(
                  padding: const EdgeInsets.all(AppPadding.large),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
                  ),
                  child: ListView(
                    children: [
                      // Cover Image Container (Responsive to width)
                      Center(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            child: AspectRatio(
                              aspectRatio: 0.7,
                              child: coverUrl.isNotEmpty
                                  ? Image.network(
                                      coverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) => Container(
                                        color: cs.surfaceContainerHighest,
                                        child: const Icon(Icons.broken_image, size: 48),
                                      ),
                                    )
                                  : Container(
                                      color: cs.surfaceContainerHighest,
                                      child: const Icon(Icons.book, size: 48),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.photo_library_rounded, size: 16),
                              label: const Text('Cambiar portada', style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              onPressed: state.saving ? null : _pickAndUploadCover,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'Pegar URL de portada',
                            icon: const Icon(Icons.link_rounded, size: 18),
                            onPressed: _showCustomUrlDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // File Info Card
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Hash: ${widget.volume.bookHash.length > 12 ? widget.volume.bookHash.substring(0, 12) : widget.volume.bookHash}...',
                                  style: tt.labelSmall?.copyWith(fontFamily: 'monospace', color: cs.onSurfaceVariant),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar Hash',
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: widget.volume.bookHash));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Hash copiado al portapapeles')),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (widget.volume.fileSize != null)
                            Text(
                              'Tamaño: ${(widget.volume.fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                              style: tt.bodySmall,
                            ),
                          if (widget.volume.filepath != null)
                            Text(
                              'Ruta en Servidor: ${widget.volume.filepath ?? ""}',
                              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Re-escanear EPUB en disco'),
                            onPressed: state.saving
                                ? null
                                : () => cubit.syncVolumeFromDisk(widget.volume.bookHash),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // DRAGGABLE VERTICAL SPLITTER
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _leftPanelWidth = (_leftPanelWidth + details.delta.dx).clamp(220.0, 750.0);
                    });
                  },
                  child: Container(
                    width: 14,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 64,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // RIGHT PANEL: Comprehensive Metadata Editor Form (matching ZeeTools MetadataForm)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppPadding.large, AppPadding.large, AppPadding.large, 96),
                  children: [
                    // SECTION 1: IDENTIFICADORES
                    FormSection(
                      title: 'Identificadores',
                      children: [
                        AmazonLookup(
                          metadata: _toBookMetadata(),
                          onApply: (updater) {
                            setState(() {
                              final updated = updater(_toBookMetadata());
                              _asin = updated.asin;
                              _isbn13 = updated.isbn13;
                              _isbn10 = updated.isbn10;
                              if (updated.altTitles.isNotEmpty) {
                                final jaTitle = updated.altTitles.where((t) => t.lang.toLowerCase() == 'ja').firstOrNull?.text;
                                if (jaTitle != null && jaTitle.isNotEmpty) _titleNative = jaTitle;
                              }
                              if (updated.altSeries.isNotEmpty) {
                                final jaSeries = updated.altSeries.where((t) => t.lang.toLowerCase() == 'ja').firstOrNull?.text;
                                if (jaSeries != null && jaSeries.isNotEmpty) _seriesNative = jaSeries;
                              }
                              if (updated.actors.isNotEmpty) {
                                _actors = [...updated.actors];
                              }
                            });
                          },
                          fields: (lookup) => AppTextField(
                            label: 'ASIN de Amazon',
                            value: _asin,
                            hint: 'B0XXXXXXXX',
                            suffix: lookup,
                            onChanged: (v) => setState(() => _asin = v.trim().toUpperCase()),
                          ),
                        ),
                        ResponsiveRow(
                          children: [
                            AppTextField(
                              label: 'ISBN-13',
                              value: _isbn13,
                              hint: '978-XX-XXXX-XXX-X',
                              inputFormatters: [isbnFormatter(isbn13Groups)],
                              onChanged: (v) => setState(() => _isbn13 = v.trim()),
                            ),
                            AppTextField(
                              label: 'ISBN-10',
                              value: _isbn10,
                              hint: 'XX-XXXX-XXX-X',
                              inputFormatters: [isbnFormatter(isbn10Groups)],
                              onChanged: (v) => setState(() => _isbn10 = v.trim().toUpperCase()),
                            ),
                          ],
                        ),
                        ResponsiveRow(
                          children: [
                            AppTextField(
                              label: 'Identificador único (UUID)',
                              value: 'urn:uuid:$_identifier',
                              enabled: false,
                              onChanged: (_) {},
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Generar UUID v7'),
                                onPressed: () => setState(() => _identifier = uuidV7()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // SECTION 2: SERIE Y TÍTULO
                    FormSection(
                      title: 'Serie y título',
                      children: [
                        OutlinedDropdown<OriginalLanguage?>(
                          label: 'Idioma en que se escribió la obra',
                          value: _originalLanguage,
                          helper: switch (_originalLanguage) {
                            OriginalLanguage.es => 'El título y la serie principales van en español; en inglés son opcionales.',
                            OriginalLanguage(scripted: true) => 'Añade el título y la serie romanizados y en su escritura nativa.',
                            _ => null,
                          },
                          onChanged: (v) {
                            if (v != null) setState(() => _originalLanguage = v);
                          },
                          items: [
                            for (final o in OriginalLanguage.values)
                              DropdownMenuItem(value: o, child: Text(o.label)),
                          ],
                        ),
                        ToggleField(
                          value: _isStandalone,
                          label: 'Volumen único',
                          helper: 'No pertenece a ninguna serie: no lleva serie ni número de volumen.',
                          onChanged: (v) => setState(() => _isStandalone = v),
                        ),
                        if (!_isStandalone) ...[
                          ResponsiveRow(
                            children: [
                              Autocomplete<String>(
                                initialValue: TextEditingValue(text: _seriesEnglish.isNotEmpty ? _seriesEnglish : _series),
                                optionsBuilder: (textEditingValue) {
                                  final allSeries = <String>{};
                                  for (final s in widget.seriesList) {
                                    if (s.seriesEnglish.isNotEmpty) allSeries.add(s.seriesEnglish);
                                    if (s.name.isNotEmpty) allSeries.add(s.name);
                                  }
                                  for (final v in widget.volumes) {
                                    if (v.seriesName.isNotEmpty) {
                                      allSeries.add(v.seriesName);
                                    }
                                  }
                                  if (textEditingValue.text.isEmpty) {
                                    return allSeries;
                                  }
                                  final query = textEditingValue.text.toLowerCase();
                                  return allSeries.where((s) => s.toLowerCase().contains(query));
                                },
                                onSelected: _onSeriesSelected,
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Serie en inglés / principal',
                                      hintText: 'Series Name (English)',
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        _seriesEnglish = v;
                                        _series = v;
                                      });
                                      final match = widget.seriesList.where((s) =>
                                          s.seriesEnglish.toLowerCase() == v.trim().toLowerCase() ||
                                          s.name.toLowerCase() == v.trim().toLowerCase()).firstOrNull;
                                      if (match != null) {
                                        _onSeriesSelected(v.trim());
                                      }
                                    },
                                  );
                                },
                              ),
                              AppTextField(
                                label: 'Volumen',
                                value: _volumeNumber,
                                hint: '1',
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                onChanged: (v) => setState(() => _volumeNumber = v),
                              ),
                            ],
                          ),
                          ResponsiveRow(
                            children: [
                              Autocomplete<String>(
                                initialValue: TextEditingValue(text: _seriesSpanish),
                                optionsBuilder: (textEditingValue) {
                                  final allSpaSeries = <String>{};
                                  for (final s in widget.seriesList) {
                                    if (s.seriesSpanish.isNotEmpty) allSpaSeries.add(s.seriesSpanish);
                                  }
                                  for (final v in widget.volumes) {
                                    if (v.spanishTitle.isNotEmpty) allSpaSeries.add(v.spanishTitle);
                                  }
                                  if (textEditingValue.text.isEmpty) {
                                    return allSpaSeries;
                                  }
                                  final query = textEditingValue.text.toLowerCase();
                                  return allSpaSeries.where((s) => s.toLowerCase().contains(query));
                                },
                                onSelected: (val) {
                                  setState(() {
                                    _seriesSpanish = val;
                                  });
                                  _onSeriesSelected(val);
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Serie en español',
                                      hintText: 'Nombre de la serie en español',
                                      errorText: (!_isStandalone && _seriesSpanish.trim().isEmpty) ? 'Obligatorio' : null,
                                    ),
                                    onChanged: (v) => setState(() => _seriesSpanish = v),
                                  );
                                },
                              ),
                              if (_originalLanguage != null && _originalLanguage!.scripted) ...[
                                AppTextField(
                                  label: 'Serie en ${_originalLanguage!.romanization}',
                                  value: _seriesRomaji,
                                  hint: 'Romaji / Romanizado',
                                  onChanged: (v) => setState(() => _seriesRomaji = v),
                                ),
                                AppTextField(
                                  label: 'Serie en ${_originalLanguage!.label.toLowerCase()}',
                                  value: _seriesNative,
                                  hint: 'Caracteres nativos (Kanji/Hangul/Hanzi)',
                                  onChanged: (v) => setState(() => _seriesNative = v),
                                ),
                              ],
                            ],
                          ),
                        ],
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _titleEnglish.isNotEmpty ? _titleEnglish : _title),
                          optionsBuilder: (textEditingValue) {
                            final allTitles = <String>{};
                            for (final v in widget.volumes) {
                              if (v.englishTitle.isNotEmpty) allTitles.add(v.englishTitle);
                              if (v.title.isNotEmpty) allTitles.add(v.title);
                            }
                            for (final s in widget.seriesList) {
                              if (s.seriesEnglish.isNotEmpty) allTitles.add(s.seriesEnglish);
                              if (s.name.isNotEmpty) allTitles.add(s.name);
                            }
                            if (textEditingValue.text.isEmpty) {
                              return allTitles;
                            }
                            final query = textEditingValue.text.toLowerCase();
                            return allTitles.where((t) => t.toLowerCase().contains(query));
                          },
                          onSelected: _onTitleEnglishSelected,
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Título en inglés / principal',
                                hintText: 'English Title',
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _titleEnglish = v;
                                  _title = v;
                                });
                                final match = widget.volumes.where((vol) =>
                                    vol.englishTitle.toLowerCase() == v.trim().toLowerCase() ||
                                    vol.title.toLowerCase() == v.trim().toLowerCase()).firstOrNull;
                                if (match != null) {
                                  _onTitleEnglishSelected(v.trim());
                                }
                              },
                            );
                          },
                        ),
                        ResponsiveRow(
                          children: [
                            Autocomplete<String>(
                              initialValue: TextEditingValue(text: _titleSpanish),
                              optionsBuilder: (textEditingValue) {
                                final allSpaTitles = <String>{};
                                for (final v in widget.volumes) {
                                  if (v.spanishTitle.isNotEmpty) allSpaTitles.add(v.spanishTitle);
                                }
                                for (final s in widget.seriesList) {
                                  if (s.seriesSpanish.isNotEmpty) allSpaTitles.add(s.seriesSpanish);
                                }
                                if (textEditingValue.text.isEmpty) {
                                  return allSpaTitles;
                                }
                                final query = textEditingValue.text.toLowerCase();
                                return allSpaTitles.where((t) => t.toLowerCase().contains(query));
                              },
                              onSelected: _onTitleSpanishSelected,
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Título en español',
                                    hintText: 'Título en español',
                                    errorText: _titleSpanish.trim().isEmpty ? 'Obligatorio' : null,
                                  ),
                                  onChanged: (v) => setState(() => _titleSpanish = v),
                                );
                              },
                            ),
                            if (_originalLanguage != null && _originalLanguage!.scripted) ...[
                              AppTextField(
                                label: 'Título en ${_originalLanguage!.romanization}',
                                value: _titleRomaji,
                                hint: 'Romaji / Romanizado',
                                onChanged: (v) => setState(() => _titleRomaji = v),
                              ),
                              AppTextField(
                                label: 'Título en ${_originalLanguage!.label.toLowerCase()}',
                                value: _titleNative,
                                hint: 'Caracteres nativos',
                                onChanged: (v) => setState(() => _titleNative = v),
                              ),
                            ],
                          ],
                        ),
                        AppTextField(
                          label: 'Título para ordenar (Opcional)',
                          value: _titleSort,
                          hint: 'Sort Title',
                          onChanged: (v) => setState(() => _titleSort = v),
                        ),
                      ],
                    ),

                    // SECTION 3: PERSONAS
                    FormSection(
                      title: 'Personas',
                      children: [
                        EditableList<Actor>(
                          items: _actors,
                          addLabel: 'Añadir persona',
                          createItem: () => const Actor(roles: [MarcRelator.aut]),
                          onChanged: (v) => setState(() => _actors = v),
                          itemBuilder: (context, index, actor, onChanged, controls) => _ActorEditor(
                            actor: actor,
                            onChanged: onChanged,
                            controls: controls,
                            defaultScript: _originalLanguage ?? OriginalLanguage.ja,
                          ),
                        ),
                      ],
                    ),

                    // SECTION 4: PUBLICACIÓN Y FORMATO
                    FormSection(
                      title: 'Publicación y formato',
                      children: [
                        ResponsiveRow(
                          children: [
                            OutlinedDropdown<String>(
                              label: 'Idioma del libro',
                              value: bookLanguages.containsKey(_bookLanguage) ? _bookLanguage : 'es',
                              onChanged: (v) {
                                if (v != null) setState(() => _bookLanguage = v);
                              },
                              items: [
                                for (final MapEntry(key: code, value: name) in bookLanguages.entries)
                                  DropdownMenuItem(value: code, child: Text(name)),
                              ],
                            ),
                            _BookTypeField(
                              value: _bookType,
                              onChanged: (v) => setState(() => _bookType = v),
                            ),
                          ],
                        ),
                        ResponsiveRow(
                          children: [
                            AppTextField(
                              label: 'Fecha de publicación',
                              value: _publishDate,
                              hint: 'AAAA-MM-DD',
                              onChanged: (v) => setState(() => _publishDate = v),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedDropdown<String>(
                                    label: 'Modo de Color',
                                    value: (_colorMode == 'color' ? 'color' : 'mono'),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _colorMode = v);
                                    },
                                    items: const [
                                      DropdownMenuItem(value: 'mono', child: Text('Monocromo (B/N)')),
                                      DropdownMenuItem(value: 'color', child: Text('Ilustraciones a Color')),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CheckboxListTile(
                                    value: _isUncensored,
                                    title: const Text('Sin Censura (+18)', style: TextStyle(fontSize: 12)),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (v) => setState(() => _isUncensored = v ?? false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        EditableList<String>(
                          items: _publishers,
                          addLabel: 'Añadir editorial o fansub',
                          createItem: () => '',
                          onChanged: (v) => setState(() => _publishers = v),
                          itemBuilder: (context, index, publisher, onChanged, controls) => EditableRow(
                            controls: controls,
                            child: AppTextField(
                              label: 'Editorial / Fansub',
                              value: publisher,
                              hint: 'Nombre de la editorial o grupo traductor',
                              onChanged: onChanged,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // SECTION 5: SINOPSIS
                    FormSection(
                      title: 'Sinopsis',
                      children: [
                        AppTextField(
                          label: 'Sinopsis',
                          value: _description,
                          hint: 'Descripción o sinopsis del tomo...',
                          maxLines: 8,
                          onChanged: (v) => setState(() => _description = v),
                        ),
                      ],
                    ),

                    // SECTION 6: CLASIFICACIÓN
                    FormSection(
                      title: 'Clasificación',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Demografía:', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final d in Demographic.values)
                                    SelectionPill(
                                      tooltip: 'Añade también «${d.ageGroup}»',
                                      selected: _demographic == d,
                                      onTap: () => setState(() => _demographic = _demographic == d ? null : d),
                                      child: Text(d.label),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Géneros:', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final genre in literaryGenres)
                                    SelectionPill(
                                      selected: _selectedGenres.contains(genre),
                                      onTap: () => setState(() {
                                        if (_selectedGenres.contains(genre)) {
                                          _selectedGenres.remove(genre);
                                        } else {
                                          _selectedGenres.add(genre);
                                        }
                                      }),
                                      child: Text(genre),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Calificación:', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            const SizedBox(width: 12),
                            for (int i = 1; i <= 5; i++)
                              IconButton(
                                icon: Icon(
                                  _rating != null && _rating! >= i ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: Colors.amber,
                                  size: 22,
                                ),
                                onPressed: () => setState(() => _rating = _rating == i ? null : i),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActorEditor extends StatelessWidget {
  final Actor actor;
  final ValueChanged<Actor> onChanged;
  final Widget controls;
  final OriginalLanguage defaultScript;

  const _ActorEditor({
    required this.actor,
    required this.onChanged,
    required this.controls,
    required this.defaultScript,
  });

  @override
  Widget build(BuildContext context) {
    return EditableRow(
      controls: controls,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveRow(
            widths: const [null, 160],
            children: [
              AppTextField(
                label: 'Nombre',
                value: actor.name,
                hint: 'Nombre de la persona',
                onChanged: (v) => onChanged(actor.copyWith(name: v, fileAs: fileAsFor(v))),
              ),
              OutlinedDropdown<MarcRelator>(
                label: 'Rol',
                value: actor.roles.isNotEmpty ? actor.roles.first : MarcRelator.aut,
                onChanged: (r) {
                  if (r != null) onChanged(actor.copyWith(roles: [r]));
                },
                items: [
                  for (final r in MarcRelator.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookTypeField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _BookTypeField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return OutlinedDropdown<String>(
      label: 'Tipo de libro',
      value: bookTypes.contains(value) ? value : bookTypes[1],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: [
        for (final t in bookTypes)
          DropdownMenuItem(value: t, child: Text(t)),
      ],
    );
  }
}
