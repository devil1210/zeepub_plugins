import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';

class VolumeEditDialog extends StatefulWidget {
  final ZeepubVolume volume;
  final String baseUrl;

  const VolumeEditDialog({
    super.key,
    required this.volume,
    required this.baseUrl,
  });

  @override
  State<VolumeEditDialog> createState() => _VolumeEditDialogState();
}

class _VolumeEditDialogState extends State<VolumeEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _spanishTitleController;
  late TextEditingController _englishTitleController;
  late TextEditingController _volumeController;
  late TextEditingController _editionController;
  late TextEditingController _authorController;
  late TextEditingController _illustratorController;
  late TextEditingController _translatorController;
  late TextEditingController _layoutByController;
  late TextEditingController _publisherController;
  late TextEditingController _descriptionController;

  String _colorMode = 'mono';
  bool _isUncensored = false;

  @override
  void initState() {
    super.initState();
    final v = widget.volume;
    _titleController = TextEditingController(text: v.title);
    _spanishTitleController = TextEditingController(text: v.spanishTitle);
    _englishTitleController = TextEditingController(text: v.englishTitle);
    _volumeController = TextEditingController(
      text: v.volume != null ? (v.volume! % 1 == 0 ? v.volume!.toInt().toString() : v.volume!.toString()) : '',
    );
    _editionController = TextEditingController(text: v.edition ?? '');
    _authorController = TextEditingController(text: v.author ?? '');
    _illustratorController = TextEditingController(text: v.illustrator ?? '');
    _translatorController = TextEditingController(text: v.translator ?? '');
    _layoutByController = TextEditingController(text: v.layoutBy ?? '');
    _publisherController = TextEditingController(text: v.publisher ?? '');
    _descriptionController = TextEditingController(text: v.description ?? '');

    final rawColor = (v.colorMode ?? 'mono').trim().toLowerCase();
    _colorMode = (rawColor == 'color' || rawColor == 'colour') ? 'color' : 'mono';
    _isUncensored = v.isUncensored;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _spanishTitleController.dispose();
    _englishTitleController.dispose();
    _volumeController.dispose();
    _editionController.dispose();
    _authorController.dispose();
    _illustratorController.dispose();
    _translatorController.dispose();
    _layoutByController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyAiSuggestion(ZeepubEditorialState state) {
    final s = state.latestAiSuggestion;
    if (s == null) return;
    setState(() {
      if (s.seriesSpanish.isNotEmpty) _spanishTitleController.text = s.seriesSpanish;
      if (s.volume != null) {
        _volumeController.text = s.volume! % 1 == 0 ? s.volume!.toInt().toString() : s.volume!.toString();
      }
      if (s.author.isNotEmpty) _authorController.text = s.author;
      if (s.illustrator.isNotEmpty) _illustratorController.text = s.illustrator;
      if (s.publisher.isNotEmpty) _publisherController.text = s.publisher;
    });
  }

  String _buildCoverUrl() {
    if (widget.volume.coverUrl == null || widget.volume.coverUrl!.isEmpty) return '';
    if (widget.volume.coverUrl!.startsWith('http')) return widget.volume.coverUrl!;
    final cleanBase = widget.baseUrl.replaceAll(RegExp(r"/+$"), "");
    final cleanPath = widget.volume.coverUrl!.startsWith('/') ? widget.volume.coverUrl! : '/${widget.volume.coverUrl!}';
    return '$cleanBase$cleanPath';
  }

  Future<void> _handleSave() async {
    if (_spanishTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('El campo "Título en Español" es obligatorio'),
        ),
      );
      return;
    }

    final cubit = context.read<ZeepubEditorialCubit>();
    final volNum = double.tryParse(_volumeController.text.trim());

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'spanish_title': _spanishTitleController.text.trim(),
      'english_title': _englishTitleController.text.trim(),
      'volume': volNum,
      'edition': _editionController.text.trim(),
      'color_mode': _colorMode,
      'is_uncensored': _isUncensored,
      'author': _authorController.text.trim(),
      'illustrator': _illustratorController.text.trim(),
      'translator': _translatorController.text.trim(),
      'layout_by': _layoutByController.text.trim(),
      'publisher': _publisherController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    await cubit.saveVolume(widget.volume.bookHash, payload);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final coverUrl = _buildCoverUrl();

    return BlocConsumer<ZeepubEditorialCubit, ZeepubEditorialState>(
      listener: (context, state) {
        if (state.latestAiSuggestion != null) {
          _applyAiSuggestion(state);
        }
      },
      builder: (context, state) {
        final cubit = context.read<ZeepubEditorialCubit>();

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 28, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Editar Metadatos del Tomo',
                              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.volume.filename ?? widget.volume.bookHash,
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Body Content
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Cover & AI Suggestion
                        SizedBox(
                          width: 180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: 0.7,
                                  child: coverUrl.isNotEmpty
                                      ? Image.network(
                                          coverUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => Container(
                                            color: cs.surfaceContainerHighest,
                                            child: const Icon(Icons.broken_image_rounded, size: 36),
                                          ),
                                        )
                                      : Container(
                                          color: cs.surfaceContainerHighest,
                                          child: const Icon(Icons.book, size: 36),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.tonalIcon(
                                icon: state.aiLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('Completar con IA'),
                                onPressed: state.aiLoading
                                    ? null
                                    : () => cubit.requestAiSuggestion(_titleController.text.isNotEmpty ? _titleController.text : widget.volume.title),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.sync_rounded, size: 16),
                                label: const Text('Re-escanear EPUB'),
                                onPressed: state.saving
                                    ? null
                                    : () => cubit.syncVolumeFromDisk(widget.volume.bookHash),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Column: Form Fields
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title Fields
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Título Original / Romaji (EPUB)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _spanishTitleController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Título en Español (Oficial / Fansub)',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    errorText: _spanishTitleController.text.trim().isEmpty ? 'Obligatorio' : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _englishTitleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Título en Inglés (Referencia)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Volume & Edition Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _volumeController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Número de Tomo (ej. 1, 1.5, 2)',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _editionController,
                                        decoration: const InputDecoration(
                                          labelText: 'Edición / Especial (ej. Especial, SS)',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Badges: Color Mode & Uncensored
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: (_colorMode == 'color' ? 'color' : 'mono'),
                                        decoration: const InputDecoration(
                                          labelText: 'Modo de Color',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'mono', child: Text('Monocromo (B/N)')),
                                          DropdownMenuItem(value: 'color', child: Text('Ilustraciones a Color')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setState(() => _colorMode = val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CheckboxListTile(
                                        value: _isUncensored,
                                        title: const Text('Sin Censura / +18'),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        onChanged: (val) {
                                          setState(() => _isUncensored = val ?? false);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Creators Row 1
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _authorController,
                                        decoration: const InputDecoration(
                                          labelText: 'Autor',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _illustratorController,
                                        decoration: const InputDecoration(
                                          labelText: 'Ilustrador',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Creators Row 2
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _translatorController,
                                        decoration: const InputDecoration(
                                          labelText: 'Traductor',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _layoutByController,
                                        decoration: const InputDecoration(
                                          labelText: 'Maquetador / Diseño',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Publisher / Fansub
                                TextFormField(
                                  controller: _publisherController,
                                  decoration: const InputDecoration(
                                    labelText: 'Fansub / Grupo / Editorial',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Description / Synopsis
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Sinopsis / Descripción',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        icon: state.saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Guardar Metadatos'),
                        onPressed: state.saving ? null : _handleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
