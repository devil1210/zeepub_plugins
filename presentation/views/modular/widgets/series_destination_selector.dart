import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';

/// Selector de destino en ZeePub: vincular a serie existente o registrar nueva serie.
class SeriesDestinationSelector extends StatelessWidget {
  final bool isCreatingNew;
  final ValueChanged<bool> onModeChanged;

  // Modo Existente
  final List<ZeepubSeries> seriesList;
  final ZeepubSeries? selectedSeries;
  final ValueChanged<ZeepubSeries?> onSeriesChanged;
  final List<ZeepubVolume> availableVolumes;
  final ZeepubVolume? selectedVolume;
  final ValueChanged<ZeepubVolume?> onVolumeChanged;
  final TextEditingController existingVolumeNumberController;
  final TextEditingController existingVolumeTitleController;
  final ZeepubVolume? detectedExistingVolume;
  final bool replaceExisting;
  final ValueChanged<bool> onReplaceExistingChanged;

  // Modo Nueva Serie Controllers
  final TextEditingController newSeriesNameController;
  final TextEditingController newSeriesSpanishController;
  final TextEditingController newSeriesAuthorController;
  final TextEditingController newSeriesPublisherController;
  final TextEditingController newSeriesVolumeNumberController;
  final TextEditingController newSeriesVolumeTitleController;
  final TextEditingController newSeriesDescController;
  final String selectedBookType;
  final ValueChanged<String> onBookTypeChanged;

  static const List<String> bookTypes = [
    'Novela Ligera',
    'Novela Web',
    'Manga',
    'Manhwa',
    'Manhua',
    'Novela Visual',
    'Libro Tradicional',
  ];

  static String normalizeBookType(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Novela Ligera';
    for (final bt in bookTypes) {
      if (bt.toLowerCase() == trimmed.toLowerCase()) return bt;
    }
    return trimmed;
  }

  const SeriesDestinationSelector({
    super.key,
    required this.isCreatingNew,
    required this.onModeChanged,
    required this.seriesList,
    required this.selectedSeries,
    required this.onSeriesChanged,
    required this.availableVolumes,
    required this.selectedVolume,
    required this.onVolumeChanged,
    required this.existingVolumeNumberController,
    required this.existingVolumeTitleController,
    this.detectedExistingVolume,
    this.replaceExisting = true,
    required this.onReplaceExistingChanged,
    required this.newSeriesNameController,
    required this.newSeriesSpanishController,
    required this.newSeriesAuthorController,
    required this.newSeriesPublisherController,
    required this.newSeriesVolumeNumberController,
    required this.newSeriesVolumeTitleController,
    required this.newSeriesDescController,
    required this.selectedBookType,
    required this.onBookTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final normBookType = normalizeBookType(selectedBookType);
    final availableBookTypes = {
      ...bookTypes,
      if (!bookTypes.any((bt) => bt.toLowerCase() == normBookType.toLowerCase())) normBookType,
    }.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_rounded, color: Color(0xFF818CF8)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Destino en el Catálogo ZeePub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'Elige si vinculas a una serie existente o das de alta una nueva serie',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selector de Modo (Existente vs Nueva)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.library_books_rounded, size: 18),
                  label: Text('Serie Existente'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text('Crear Nueva Serie'),
                ),
              ],
              selected: {isCreatingNew},
              onSelectionChanged: (val) => onModeChanged(val.first),
            ),

            const SizedBox(height: 22),

            // Contenido según modo
            if (!isCreatingNew) ...[
              // Banner de Tomo Existente Detectado (si aplica)
              if (detectedExistingVolume != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Se detectó un tomo coincidente en el catálogo: Vol. ${detectedExistingVolume!.volume ?? "?"} - ${detectedExistingVolume!.title.isNotEmpty ? detectedExistingVolume!.title : "Sin título"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => onReplaceExistingChanged(true),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: replaceExisting,
                                    onChanged: (val) {
                                      if (val != null) onReplaceExistingChanged(val);
                                    },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Actualizar / Reemplazar tomo existente (escaneo individual)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => onReplaceExistingChanged(false),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: false,
                                    groupValue: replaceExisting,
                                    onChanged: (val) {
                                      if (val != null) onReplaceExistingChanged(val);
                                    },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Registrar como nuevo volumen en esta serie',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Modo 1: Serie Existente (Autocompletar / Escribir o escoger)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<ZeepubSeries>(
                    initialValue: TextEditingValue(text: selectedSeries?.name ?? ''),
                    displayStringForOption: (ZeepubSeries s) => s.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return seriesList;
                      }
                      final query = textEditingValue.text.toLowerCase().trim();
                      return seriesList.where((ZeepubSeries s) {
                        return s.name.toLowerCase().contains(query) ||
                            s.seriesSpanish.toLowerCase().contains(query) ||
                            s.seriesEnglish.toLowerCase().contains(query);
                      });
                    },
                    onSelected: (ZeepubSeries selection) {
                      onSeriesChanged(selection);
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      if (selectedSeries != null && textController.text.isEmpty) {
                        textController.text = selectedSeries!.name;
                      }
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Serie / Novela en Catálogo (escribe o escoge) *',
                          hintText: 'Escribe para buscar entre las series...',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.bookmark_outline),
                          suffixIcon: textController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    textController.clear();
                                    onSeriesChanged(null);
                                  },
                                )
                              : const Icon(Icons.arrow_drop_down),
                        ),
                        onChanged: (val) {
                          if (val.trim().isEmpty) {
                            onSeriesChanged(null);
                          } else {
                            final match = seriesList.where((s) => s.name.toLowerCase() == val.trim().toLowerCase()).firstOrNull;
                            if (match != null) {
                              onSeriesChanged(match);
                            }
                          }
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                              maxHeight: 250,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final s = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: s.seriesSpanish.isNotEmpty && s.seriesSpanish != s.name
                                      ? Text(s.seriesSpanish, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))
                                      : null,
                                  trailing: Text('${s.bookCount} tomos', style: TextStyle(fontSize: 11, color: cs.primary)),
                                  onTap: () => onSelected(s),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Volumen ingresado a mano (entero o decimal con .)
              Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: existingVolumeNumberController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Volumen # *',
                        hintText: 'Ej. 1, 2.5, 0.5',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val.trim());
                        if (parsed != null && availableVolumes.isNotEmpty) {
                          final match = availableVolumes.where((v) => v.volume == parsed).firstOrNull;
                          onVolumeChanged(match);
                        } else {
                          onVolumeChanged(null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: existingVolumeTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Título o Subtítulo del Tomo (opcional)',
                        hintText: 'Nombre del tomo o subtítulo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                  ),
                ],
              ),

              if (availableVolumes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Tomos existentes en serie:',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                    for (final v in availableVolumes)
                      ActionChip(
                        avatar: Icon(Icons.book, size: 14, color: selectedVolume?.id == v.id ? cs.onPrimary : cs.primary),
                        label: Text(
                          'Vol. ${v.volume != null ? (v.volume! % 1 == 0 ? v.volume!.toInt() : v.volume) : "?"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selectedVolume?.id == v.id ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: selectedVolume?.id == v.id ? cs.primary : null,
                        labelStyle: TextStyle(color: selectedVolume?.id == v.id ? cs.onPrimary : null),
                        onPressed: () {
                          onVolumeChanged(v);
                          if (v.volume != null) {
                            existingVolumeNumberController.text = (v.volume! % 1 == 0 ? v.volume!.toInt().toString() : v.volume!.toString());
                          }
                          if (v.title.isNotEmpty) {
                            existingVolumeTitleController.text = v.title;
                          }
                        },
                      ),
                  ],
                ),
              ],
            ] else ...[
              // Modo 2: Formulario de Nueva Serie
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_stories_outlined, size: 18, color: Color(0xFF818CF8)),
                        SizedBox(width: 8),
                        Text('Datos de la Nueva Serie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newSeriesNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Canónico de la Serie *',
                        hintText: 'Ej. Mushoku Tensei, Sword Art Online...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.title_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newSeriesSpanishController,
                            decoration: const InputDecoration(
                              labelText: 'Título en Español',
                              hintText: 'Opcional o traducido',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.translate_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            value: availableBookTypes.contains(normBookType) ? normBookType : availableBookTypes.first,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Obra',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              for (final bt in availableBookTypes)
                                DropdownMenuItem(value: bt, child: Text(bt, overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) onBookTypeChanged(val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newSeriesAuthorController,
                            decoration: const InputDecoration(
                              labelText: 'Autor',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: newSeriesPublisherController,
                            decoration: const InputDecoration(
                              labelText: 'Editorial / Sello',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.business_outlined, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.book_outlined, size: 18, color: Color(0xFF818CF8)),
                        SizedBox(width: 8),
                        Text('Datos del Volumen a Vincular', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: newSeriesVolumeNumberController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Volumen # *',
                              hintText: '1, 2.5...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.tag_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: newSeriesVolumeTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Título del Volumen',
                              hintText: 'Subtítulo o nombre del arco',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newSeriesDescController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Sinopsis / Descripción',
                        hintText: 'Resumen extraído del EPUB o escrito manualmente...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
