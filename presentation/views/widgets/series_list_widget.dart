import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';

class SeriesListWidget extends StatefulWidget {
  final String baseUrl;

  const SeriesListWidget({super.key, required this.baseUrl});

  @override
  State<SeriesListWidget> createState() => _SeriesListWidgetState();
}

class _SeriesListWidgetState extends State<SeriesListWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditSeriesModal(BuildContext context, ZeepubSeries series) {
    final nameCtrl = TextEditingController(text: series.name);
    final spanishCtrl = TextEditingController(text: series.seriesSpanish);
    final englishCtrl = TextEditingController(text: series.seriesEnglish);
    final authorCtrl = TextEditingController(text: series.author);
    final illusCtrl = TextEditingController(text: series.illustrator);
    final pubCtrl = TextEditingController(text: series.publisher);
    final descCtrl = TextEditingController(text: series.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Serie: ${series.name}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: spanishCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre en Español (Canónico)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: englishCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre en Inglés / Internacional'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre Original'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: authorCtrl,
                        decoration: const InputDecoration(labelText: 'Autor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: illusCtrl,
                        decoration: const InputDecoration(labelText: 'Ilustrador'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pubCtrl,
                  decoration: const InputDecoration(labelText: 'Editorial / Fansub Principal'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Sinopsis de la Serie'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final payload = {
                'name': nameCtrl.text.trim(),
                'series_spanish': spanishCtrl.text.trim(),
                'series_english': englishCtrl.text.trim(),
                'author': authorCtrl.text.trim(),
                'illustrator': illusCtrl.text.trim(),
                'publisher': pubCtrl.text.trim(),
                'description': descCtrl.text.trim(),
              };
              await context.read<ZeepubEditorialCubit>().saveSeries(series.seriesHash, payload);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Guardar Serie'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (BuildContext context, ZeepubEditorialState state) {
        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar serie por nombre, autor, publisher...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<ZeepubEditorialCubit>().loadSeries(query: '');
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (val) {
                        context.read<ZeepubEditorialCubit>().loadSeries(query: val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                    onPressed: () {
                      context.read<ZeepubEditorialCubit>().loadSeries(query: _searchController.text);
                    },
                  ),
                ],
              ),
            ),

            // Series List
            Expanded(
              child: state.seriesList.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron series registradas',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.seriesList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final s = state.seriesList[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                '${s.bookCount}',
                                style: tt.labelMedium?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              s.seriesSpanish.isNotEmpty ? s.seriesSpanish : s.name,
                              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              [
                                if (s.seriesSpanish.isNotEmpty && s.name != s.seriesSpanish) s.name,
                                if (s.author.isNotEmpty) 'Autor: ${s.author}',
                                if (s.publisher.isNotEmpty) 'Fansub: ${s.publisher}',
                              ].join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar Serie',
                              onPressed: () => _openEditSeriesModal(context, s),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
