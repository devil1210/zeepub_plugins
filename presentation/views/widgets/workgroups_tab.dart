import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';

class ZeepubWorkgroupsTab extends StatefulWidget {
  const ZeepubWorkgroupsTab({super.key});

  @override
  State<ZeepubWorkgroupsTab> createState() => _ZeepubWorkgroupsTabState();
}

class _ZeepubWorkgroupsTabState extends State<ZeepubWorkgroupsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _bookFilter = 'with_books'; // 'with_books', 'with_issues', 'without_books', 'all'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context, ZeepubEditorialCubit cubit) {
    final nameCtrl = TextEditingController();
    final siglasCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final webCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, color: Color(0xFF818CF8)),
            SizedBox(width: 8),
            Text('Nuevo Grupo Traductor'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Fansub / Grupo *',
                        hintText: 'Ej. Akira Translations',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: siglasCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Siglas [TAG]',
                        hintText: 'AkiraTls',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas o descripción (opcional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: webCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sitio Web / Blog (opcional)',
                  prefixIcon: Icon(Icons.language_rounded, size: 16),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Crear Fansub'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              final payload = {
                'name': name,
                'siglas': siglasCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'links': {
                  if (webCtrl.text.trim().isNotEmpty) 'web': webCtrl.text.trim(),
                },
              };
              cubit.saveWorkgroup(payload);
            },
          ),
        ],
      ),
    );
  }

  void _showPurgeModal(BuildContext context, ZeepubEditorialCubit cubit, int emptyCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('¿Purgar Grupos Vacíos?'),
          ],
        ),
        content: Text(
          'Se eliminarán permanentemente de la base de datos $emptyCount grupos traductores que tienen 0 libros asociados.\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: Text('Purgar $emptyCount Grupos'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.purgeEmptyWorkgroups();
            },
          ),
        ],
      ),
    );
  }

  void _showGlobalMergeDialog(BuildContext context, ZeepubEditorialState state, ZeepubEditorialCubit cubit, [int? preselectedTargetId]) {
    final groups = state.workgroups;
    int? targetId = preselectedTargetId ?? (groups.isNotEmpty ? groups.first.id : null);
    final selectedSources = <int>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final candidates = groups.where((g) => g.id != targetId).toList();

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.merge_type_rounded, color: Colors.purpleAccent),
                SizedBox(width: 8),
                Text('Fusionar Grupos Traductores'),
              ],
            ),
            content: SizedBox(
              width: 540,
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. SELECCIONA EL GRUPO DESTINO PRINCIPAL (El que se conservará):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: targetId,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: [
                      for (final g in groups)
                        DropdownMenuItem(value: g.id, child: Text(g.displayName, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          targetId = val;
                          selectedSources.remove(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('2. SELECCIONA LOS GRUPOS FUENTE A FUSIONAR Y ELIMINAR:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (c, idx) {
                          final cg = candidates[idx];
                          final isChecked = selectedSources.contains(cg.id);
                          return CheckboxListTile(
                            value: isChecked,
                            title: Text(cg.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text('ID #${cg.id} · ${cg.booksCount} libros', style: const TextStyle(fontSize: 10)),
                            isThreeLine: false,
                            dense: true,
                            onChanged: (v) {
                              setDlgState(() {
                                if (v == true) {
                                  selectedSources.add(cg.id);
                                } else {
                                  selectedSources.remove(cg.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              FilledButton.icon(
                icon: const Icon(Icons.merge_type_rounded),
                label: Text('Fusionar ${selectedSources.length} grupos'),
                style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: selectedSources.isEmpty
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        cubit.mergeWorkgroups(targetId: targetId!, sourceIds: selectedSources.toList());
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<ZeepubEditorialCubit>();
        final workgroups = state.workgroups;

        final countWithBooks = workgroups.where((g) => g.booksCount > 0).length;
        final countWithIssues = workgroups.where((g) => g.badMetadataCount > 0).length;
        final countWithoutBooks = workgroups.where((g) => g.booksCount == 0).length;

        final query = _searchController.text.toLowerCase().trim();
        final filtered = workgroups.where((g) {
          if (_bookFilter == 'with_books' && g.booksCount == 0) return false;
          if (_bookFilter == 'with_issues' && g.badMetadataCount == 0) return false;
          if (_bookFilter == 'without_books' && g.booksCount > 0) return false;

          if (query.isNotEmpty) {
            final nameMatch = g.name.toLowerCase().contains(query);
            final siglasMatch = g.siglas.toLowerCase().contains(query);
            final descMatch = g.description.toLowerCase().contains(query);
            final linksMatch = g.links.values.any((l) => l.toLowerCase().contains(query));
            return nameMatch || siglasMatch || descMatch || linksMatch;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Top Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.corporate_fare_rounded, color: Color(0xFF818CF8), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Directorio de Fansubs & Grupos Traductores',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gestión de créditos editoriales, siglas oficiales y enlaces a redes que se inyectan en publicaciones (${filtered.length} visibles de ${workgroups.length} registrados).',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Top Action Buttons
                      if (countWithoutBooks > 0)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.redAccent),
                          label: Text('Purgar Vacíos ($countWithoutBooks)', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showPurgeModal(context, cubit, countWithoutBooks),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.merge_type_rounded, size: 15, color: Colors.purpleAccent),
                        label: const Text('Fusionar Grupos', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                          backgroundColor: Colors.purple.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _showGlobalMergeDialog(context, state, cubit),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Nuevo Grupo Traductor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _showCreateDialog(context, cubit),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search bar & Filter Tabs Row
                  Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, siglas [TAG], enlaces de contacto...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Filter Tabs
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            _filterTab('Con Libros', 'with_books', countWithBooks, const Color(0xFF6366F1)),
                            _filterTab('Con Obs. OPF', 'with_issues', countWithIssues, Colors.amber, hasWarning: true),
                            _filterTab('Sin Libros', 'without_books', countWithoutBooks, const Color(0xFF6366F1)),
                            _filterTab('Todos', 'all', workgroups.length, const Color(0xFF6366F1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Grid of Fansubs Cards
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_outlined, size: 54, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          const Text('No se encontraron grupos traductores con el filtro seleccionado.', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 180,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final wg = filtered[idx];
                        final hasIssues = wg.badMetadataCount > 0;

                        return Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: hasIssues
                                  ? Colors.amber.withValues(alpha: 0.5)
                                  : cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          color: hasIssues
                              ? cs.errorContainer.withValues(alpha: 0.1)
                              : cs.surfaceContainerLow,
                          child: InkWell(
                            onTap: () => cubit.openWorkgroupDetail(wg, initialTab: 0),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card Top: Avatar, Name, Siglas, ID, Action buttons
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: hasIssues
                                            ? Colors.amber.withValues(alpha: 0.15)
                                            : const Color(0xFF6366F1).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hasIssues
                                              ? Colors.amber.withValues(alpha: 0.4)
                                              : const Color(0xFF6366F1).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          wg.siglas.isNotEmpty
                                              ? (wg.siglas.length > 3 ? wg.siglas.substring(0, 3) : wg.siglas)
                                              : (wg.name.isNotEmpty ? wg.name[0].toUpperCase() : 'F'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: hasIssues ? Colors.amberAccent : const Color(0xFF818CF8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  wg.name,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (wg.siglas.isNotEmpty) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    wg.siglas,
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70, fontFamily: 'monospace'),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text('ID #${wg.id}', style: const TextStyle(fontSize: 10, color: Colors.white38, fontFamily: 'monospace')),
                                              if (hasIssues) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.warning_amber_rounded, size: 9, color: Colors.amberAccent),
                                                      const SizedBox(width: 2),
                                                      Text('${wg.badMetadataCount} con obs.', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quick action buttons
                                    IconButton(
                                      icon: const Icon(Icons.merge_type_rounded, size: 15, color: Colors.white38),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Fusionar duplicados en este grupo',
                                      onPressed: () => _showGlobalMergeDialog(context, state, cubit, wg.id),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF818CF8)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Editar Ficha y Redes (Pantalla Completa)',
                                      onPressed: () => cubit.openWorkgroupDetail(wg, initialTab: 1),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Description / Notes
                                Expanded(
                                  child: Text(
                                    wg.description.isNotEmpty
                                        ? wg.description
                                        : 'Sin notas registradas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: wg.description.isNotEmpty ? Colors.white60 : Colors.white24,
                                      fontStyle: wg.description.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const Divider(height: 12, color: Colors.white10),

                                // Card Bottom: Stats & Auditoría link
                                Row(
                                  children: [
                                    Icon(Icons.menu_book_rounded, size: 12, color: hasIssues ? Colors.amberAccent : const Color(0xFF818CF8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${wg.booksCount} libros',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasIssues ? Colors.amberAccent : Colors.white70),
                                    ),
                                    if (hasIssues) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${wg.badMetadataCount} obs.',
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Auditoría',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: hasIssues ? Colors.amberAccent : const Color(0xFF818CF8),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_outward_rounded,
                                          size: 13,
                                          color: hasIssues ? Colors.amberAccent : const Color(0xFF818CF8),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _filterTab(String label, String mode, int count, Color activeColor, {bool hasWarning = false}) {
    final isSelected = _bookFilter == mode;

    return InkWell(
      onTap: () => setState(() => _bookFilter = mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasWarning && count > 0 && !isSelected) ...[
              const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amberAccent),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (hasWarning ? Colors.black : Colors.white)
                    : (hasWarning && count > 0 ? Colors.amberAccent : Colors.white60),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isSelected ? (hasWarning ? Colors.black : Colors.white) : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
