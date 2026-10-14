import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_workgroup.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';
import 'zeepub_cached_image.dart';

class WorkgroupDetailView extends StatefulWidget {
  final ZeepubWorkgroupDetail detail;
  final int initialTab;

  const WorkgroupDetailView({
    super.key,
    required this.detail,
    this.initialTab = 0,
  });

  @override
  State<WorkgroupDetailView> createState() => _WorkgroupDetailViewState();
}

class _WorkgroupDetailViewState extends State<WorkgroupDetailView> {
  late int _activeTab;
  String _filterMode = 'all'; // 'all', 'bad', 'good'
  final TextEditingController _searchController = TextEditingController();
  String? _copiedPathId;
  String? _copiedFieldKey;
  bool _hasUnsavedChanges = false;

  late TextEditingController _nameController;
  late TextEditingController _siglasController;
  late TextEditingController _descController;
  late TextEditingController _webController;
  late TextEditingController _fbController;
  late TextEditingController _discordController;
  late TextEditingController _patreonController;
  late TextEditingController _twitterController;
  late TextEditingController _donationsController;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _initControllers(widget.detail.group);
  }

  void _initControllers(ZeepubWorkgroup g) {
    _nameController = TextEditingController(text: g.name);
    _siglasController = TextEditingController(text: g.siglas);
    _descController = TextEditingController(text: g.description);
    _webController = TextEditingController(text: g.links['web'] ?? g.url);
    _fbController = TextEditingController(text: g.links['fb'] ?? '');
    _discordController = TextEditingController(text: g.links['discord'] ?? '');
    _patreonController = TextEditingController(text: g.links['patreon'] ?? '');
    _twitterController = TextEditingController(text: g.links['twitter'] ?? '');
    _donationsController = TextEditingController(text: g.links['donations'] ?? '');

    void markDirty() {
      if (!_hasUnsavedChanges && mounted) {
        setState(() => _hasUnsavedChanges = true);
      }
    }

    _nameController.addListener(markDirty);
    _siglasController.addListener(markDirty);
    _descController.addListener(markDirty);
    _webController.addListener(markDirty);
    _fbController.addListener(markDirty);
    _discordController.addListener(markDirty);
    _patreonController.addListener(markDirty);
    _twitterController.addListener(markDirty);
    _donationsController.addListener(markDirty);
  }

  @override
  void didUpdateWidget(covariant WorkgroupDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.detail.group.id != oldWidget.detail.group.id) {
      _disposeControllers();
      _initControllers(widget.detail.group);
      _hasUnsavedChanges = false;
      _activeTab = widget.initialTab;
    }
  }

  void _disposeControllers() {
    _nameController.dispose();
    _siglasController.dispose();
    _descController.dispose();
    _webController.dispose();
    _fbController.dispose();
    _discordController.dispose();
    _patreonController.dispose();
    _twitterController.dispose();
    _donationsController.dispose();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _copyPath(String bookId, String path) {
    Clipboard.setData(ClipboardData(text: path));
    setState(() => _copiedPathId = bookId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ruta del archivo EPUB copiada al portapapeles.'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedPathId = null);
    });
  }

  void _copyLink(String key, String text, String label) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text.trim()));
    setState(() => _copiedFieldKey = key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enlace de $label copiado al portapapeles.'),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedFieldKey = null);
    });
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      controller.text = data.text!.trim();
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _showMergeDialog(BuildContext context, ZeepubEditorialState state, ZeepubEditorialCubit cubit) {
    final currentGroup = widget.detail.group;
    final otherGroups = state.workgroups.where((g) => g.id != currentGroup.id).toList();
    final selectedSourceIds = <int>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.merge_type_rounded, color: Colors.purpleAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Fusionar duplicados hacia "${currentGroup.name}"', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todos los libros asociados a los grupos seleccionados abajo se reasignarán a "${currentGroup.name}" (ID #${currentGroup.id}), y los grupos fuente seleccionados serán eliminados.',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text('SELECCIONA LOS GRUPOS A ABSORBER Y ELIMINAR:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    itemCount: otherGroups.length,
                    itemBuilder: (c, idx) {
                      final og = otherGroups[idx];
                      final isChecked = selectedSourceIds.contains(og.id);
                      return CheckboxListTile(
                        value: isChecked,
                        title: Text(og.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('ID #${og.id} · ${og.booksCount} libros · ${og.url}', style: const TextStyle(fontSize: 11)),
                        dense: true,
                        onChanged: (v) {
                          setDlgState(() {
                            if (v == true) {
                              selectedSourceIds.add(og.id);
                            } else {
                              selectedSourceIds.remove(og.id);
                            }
                          });
                        },
                      );
                    },
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
              icon: const Icon(Icons.merge_type_rounded),
              label: Text('Fusionar ${selectedSourceIds.length} grupos'),
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: selectedSourceIds.isEmpty
                  ? null
                  : () {
                      Navigator.of(ctx).pop();
                      cubit.mergeWorkgroups(targetId: currentGroup.id, sourceIds: selectedSourceIds.toList());
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ZeepubEditorialCubit cubit, ZeepubWorkgroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('¿Eliminar Fansub?'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente "${group.name}"?\n\nLos libros asociados no se borrarán, pero quedarán sin grupo traductor asignado.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever_rounded),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.deleteWorkgroup(group.id);
            },
            label: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );
  }

  void _saveFicha(ZeepubEditorialCubit cubit) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del Fansub es obligatorio.'), backgroundColor: Colors.red),
      );
      return;
    }

    final payload = {
      'id': widget.detail.group.id,
      'name': name,
      'siglas': _siglasController.text.trim(),
      'description': _descController.text.trim(),
      'links': {
        'web': _webController.text.trim(),
        'fb': _fbController.text.trim(),
        'discord': _discordController.text.trim(),
        'patreon': _patreonController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'donations': _donationsController.text.trim(),
      },
    };
    cubit.saveWorkgroup(payload);
    setState(() => _hasUnsavedChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<ZeepubEditorialCubit>();
        final detail = state.activeWorkgroupDetail ?? widget.detail;
        final group = detail.group;
        final books = detail.books;

        final badCount = detail.badMetadataCount;
        final goodCount = detail.goodMetadataCount;
        final totalBooks = detail.totalBooks;
        final integrityPct = totalBooks > 0 ? ((goodCount / totalBooks) * 100).round() : 100;

        final query = _searchController.text.toLowerCase().trim();
        final filteredBooks = books.where((b) {
          if (_filterMode == 'bad' && !b.hasBadMetadata) return false;
          if (_filterMode == 'good' && b.hasBadMetadata) return false;
          if (query.isNotEmpty) {
            final t = b.displayTitle.toLowerCase();
            final f = (b.filename ?? '').toLowerCase();
            final p = (b.filepath ?? '').toLowerCase();
            final s = (b.seriesSpanish ?? b.seriesId ?? '').toLowerCase();
            return t.contains(query) || f.contains(query) || p.contains(query) || s.contains(query);
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          body: Column(
            children: [
              // Top Navigation & Action Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Volver al Directorio de Fansubs'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => cubit.closeWorkgroupDetail(),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Fansub ID #${group.id}', style: const TextStyle(fontSize: 11, color: Colors.white60, fontFamily: 'monospace')),
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('$totalBooks libros', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF818CF8)),
                      label: const Text('Sincronizar Libros', style: TextStyle(color: Color(0xFF818CF8), fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () {
                        final ids = books.map((b) => b.id).toList();
                        cubit.syncWorkgroupBooks(group.id, ids);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.merge_type_rounded, size: 16, color: Colors.purpleAccent),
                      label: const Text('Fusionar Duplicados', style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        backgroundColor: Colors.purple.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () => _showMergeDialog(context, state, cubit),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: state.saving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(_hasUnsavedChanges ? 'Guardar Cambios *' : 'Guardar Información', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _hasUnsavedChanges ? const Color(0xFF4F46E5) : const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: state.saving ? null : () => _saveFicha(cubit),
                    ),
                  ],
                ),
              ),

              // Main Body Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Hero Card: Fansub Profile & Status Banner
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: badCount > 0 ? Colors.amber.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      color: cs.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Large Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  badCount > 0 ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFF6366F1).withValues(alpha: 0.3),
                                  badCount > 0 ? Colors.orange.withValues(alpha: 0.3) : const Color(0xFFA855F7).withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: badCount > 0 ? Colors.amber.withValues(alpha: 0.5) : const Color(0xFF6366F1).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                group.siglas.isNotEmpty
                                    ? (group.siglas.length > 3 ? group.siglas.substring(0, 3) : group.siglas)
                                    : (group.name.isNotEmpty ? group.name[0].toUpperCase() : 'F'),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: badCount > 0 ? Colors.amberAccent : const Color(0xFF818CF8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Name, Siglas, ID, Description preview
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.name,
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                    ),
                                    if (group.siglas.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          '[${group.siglas}]',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF818CF8), fontFamily: 'monospace'),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('ID #${group.id}', style: const TextStyle(fontSize: 11, color: Colors.white60, fontFamily: 'monospace')),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  group.description.isNotEmpty ? group.description : 'Sin notas registradas para este grupo traductor.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: group.description.isNotEmpty ? Colors.white70 : Colors.white30,
                                    fontStyle: group.description.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),

                                // Metric Badges Row
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _statPill(
                                      icon: Icons.menu_book_rounded,
                                      label: '$totalBooks libros en biblioteca',
                                      color: const Color(0xFF818CF8),
                                      bgColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                      onTap: () => setState(() {
                                        _activeTab = 0;
                                        _filterMode = 'all';
                                      }),
                                    ),
                                    _statPill(
                                      icon: Icons.check_circle_outline_rounded,
                                      label: '$goodCount ($integrityPct%) consistentes',
                                      color: Colors.greenAccent,
                                      bgColor: Colors.green.withValues(alpha: 0.15),
                                      onTap: () => setState(() {
                                        _activeTab = 0;
                                        _filterMode = 'good';
                                      }),
                                    ),
                                    if (badCount > 0)
                                      _statPill(
                                        icon: Icons.warning_amber_rounded,
                                        label: '$badCount con inconsistencia OPF',
                                        color: Colors.amberAccent,
                                        bgColor: Colors.amber.withValues(alpha: 0.2),
                                        borderColor: Colors.amber.withValues(alpha: 0.5),
                                        onTap: () => setState(() {
                                          _activeTab = 0;
                                          _filterMode = 'bad';
                                        }),
                                      ),
                                    _statPill(
                                      icon: Icons.link_rounded,
                                      label: '${group.links.length} enlaces oficiales',
                                      color: const Color(0xFF38BDF8),
                                      bgColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                                      onTap: () => setState(() => _activeTab = 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),

                    const SizedBox(height: 20),

                    // Main Tab Selector Switch
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _tabNavButton(
                              icon: Icons.menu_book_rounded,
                              title: 'Auditoría de Tomos & Metadatos',
                              subtitle: '$totalBooks libros asociados · $badCount observaciones',
                              selected: _activeTab == 0,
                              badgeCount: badCount > 0 ? badCount : null,
                              badgeColor: Colors.amber,
                              onTap: () => setState(() => _activeTab = 0),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _tabNavButton(
                              icon: Icons.badge_outlined,
                              title: 'Ficha Editorial & Canales Oficiales',
                              subtitle: 'Nombre, siglas, redes sociales y créditos de Telegram',
                              selected: _activeTab == 1,
                              badgeCount: _hasUnsavedChanges ? 1 : null,
                              badgeText: _hasUnsavedChanges ? 'Sin guardar' : null,
                              badgeColor: const Color(0xFF6366F1),
                              onTap: () => setState(() => _activeTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Active Tab Content
                    if (_activeTab == 1)
                      _buildFichaTab(context, cubit, group, books, totalBooks, badCount, goodCount, integrityPct)
                    else
                      _buildAuditoriaTab(context, cubit, group, books, filteredBooks, badCount, goodCount, totalBooks),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 1: FICHA EDITORIAL & CANALES OFICIALES (PÁGINA COMPLETA DE EDICIÓN)
  // ===========================================================================
  Widget _buildFichaTab(
    BuildContext context,
    ZeepubEditorialCubit cubit,
    ZeepubWorkgroup group,
    List<ZeepubAttachedBook> books,
    int totalBooks,
    int badCount,
    int goodCount,
    int integrityPct,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Identidad Editorial & Registro
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.corporate_fare_rounded, size: 20, color: Color(0xFF818CF8)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Identidad Editorial del Fansub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Nombre oficial y etiquetas usadas en catálogo y plantillas de Telegram', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Nombre Oficial del Fansub / Grupo Traductor *',
                        hintText: 'Ej. Akira Translations',
                        prefixIcon: Icon(Icons.edit_rounded, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _siglasController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        labelText: 'Siglas Oficiales [TAG]',
                        hintText: 'AkiraTls',
                        prefixIcon: Icon(Icons.tag_rounded, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, height: 1.4),
                decoration: const InputDecoration(
                  labelText: 'Notas editoriales o descripción del grupo',
                  hintText: 'Información interna, proyectos activos, historial o directivas de publicación...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF818CF8)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El Nombre Oficial y las Siglas se utilizan para el emparejamiento automático de metadatos en archivos EPUB y en las publicaciones de Telegram (vía etiquetas y botones de créditos).',
                        style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Canales Oficiales y Redes Sociales
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Canales de Contacto & Redes Oficiales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Estos enlaces se inyectan en los botones interactivos de los posts de Telegram', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6 Social Networks Grid (2 Columns)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _socialFieldCard(
                          keyName: 'web',
                          label: 'Sitio Web / Blog Oficial',
                          icon: Icons.language_rounded,
                          color: const Color(0xFF38BDF8),
                          controller: _webController,
                          hint: 'https://mifansub.com',
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _socialFieldCard(
                          keyName: 'fb',
                          label: 'Página de Facebook',
                          icon: Icons.facebook_rounded,
                          color: const Color(0xFF1877F2),
                          controller: _fbController,
                          hint: 'https://facebook.com/mifansub',
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _socialFieldCard(
                          keyName: 'discord',
                          label: 'Servidor de Discord',
                          icon: Icons.chat_bubble_outline_rounded,
                          color: const Color(0xFF5865F2),
                          controller: _discordController,
                          hint: 'https://discord.gg/invitacion',
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _socialFieldCard(
                          keyName: 'patreon',
                          label: 'Patreon / Suscripciones',
                          icon: Icons.favorite_outline_rounded,
                          color: const Color(0xFFFF424D),
                          controller: _patreonController,
                          hint: 'https://patreon.com/mifansub',
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _socialFieldCard(
                          keyName: 'twitter',
                          label: 'Twitter / X',
                          icon: Icons.alternate_email_rounded,
                          color: const Color(0xFF0EA5E9),
                          controller: _twitterController,
                          hint: 'https://x.com/mifansub',
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _socialFieldCard(
                          keyName: 'donations',
                          label: 'Donaciones (Ko-fi, PayPal, etc.)',
                          icon: Icons.coffee_rounded,
                          color: const Color(0xFFF59E0B),
                          controller: _donationsController,
                          hint: 'https://ko-fi.com/mifansub',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Zona de Gestión Avanzada & Eliminación
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gestión Avanzada y Acciones de Biblioteca', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text('Sincronizar $totalBooks Libros con sus EPUBs'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      final ids = books.map((b) => b.id).toList();
                      cubit.syncWorkgroupBooks(group.id, ids);
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.merge_type_rounded, size: 16, color: Colors.purpleAccent),
                    label: const Text('Fusionar Duplicados hacia este Fansub', style: TextStyle(color: Colors.purpleAccent)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                      backgroundColor: Colors.purple.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _showMergeDialog(context, cubit.state, cubit),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('Eliminar Fansub', style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                      backgroundColor: Colors.red.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _showDeleteDialog(context, cubit, group),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Bottom Save Button Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hasUnsavedChanges ? const Color(0xFF6366F1).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              if (_hasUnsavedChanges) ...[
                const Icon(Icons.edit_notifications_rounded, size: 18, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text('Tienes cambios sin guardar en esta ficha.', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ] else ...[
                const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.greenAccent),
                const SizedBox(width: 8),
                const Text('Ficha editorial sincronizada.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const Spacer(),
              if (_hasUnsavedChanges)
                TextButton(
                  onPressed: () {
                    _disposeControllers();
                    _initControllers(group);
                    setState(() => _hasUnsavedChanges = false);
                  },
                  child: const Text('Descartar Cambios', style: TextStyle(color: Colors.white60)),
                ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Guardar Todos los Cambios'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => _saveFicha(cubit),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialFieldCard({
    required String keyName,
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isCopied = _copiedFieldKey == keyName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              if (controller.text.trim().isNotEmpty) ...[
                IconButton(
                  icon: Icon(isCopied ? Icons.check : Icons.copy_rounded, size: 14, color: isCopied ? Colors.greenAccent : Colors.white60),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copiar enlace',
                  onPressed: () => _copyLink(keyName, controller.text, label),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 14, color: Colors.white60),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Pegar desde portapapeles',
                onPressed: () => _pasteInto(controller),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: Colors.white24),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 0: AUDITORÍA DE TOMOS & METADATOS EPUB
  // ===========================================================================
  Widget _buildAuditoriaTab(
    BuildContext context,
    ZeepubEditorialCubit cubit,
    ZeepubWorkgroup group,
    List<ZeepubAttachedBook> allBooks,
    List<ZeepubAttachedBook> filteredBooks,
    int badCount,
    int goodCount,
    int totalBooks,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter & Search Toolbar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _filterChip('Todos ($totalBooks)', 'all', null),
              const SizedBox(width: 6),
              _filterChip('Con Inconsistencia ($badCount)', 'bad', Colors.amber),
              const SizedBox(width: 6),
              _filterChip('Consistentes ($goodCount)', 'good', Colors.green),
              const Spacer(),
              if (filteredBooks.isNotEmpty)
                FilledButton.icon(
                  icon: const Icon(Icons.sync_rounded, size: 14),
                  label: Text('Sincronizar filtrados (${filteredBooks.length})'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final ids = filteredBooks.map((b) => b.id).toList();
                    cubit.syncWorkgroupBooks(group.id, ids);
                  },
                ),
              const SizedBox(width: 12),
              SizedBox(
                width: 260,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Filtrar por título, serie, archivo...',
                    prefixIcon: const Icon(Icons.search, size: 16),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),

        if (badCount > 0 && _filterMode == 'bad') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inconsistencias detectadas entre el archivo EPUB y el Grupo',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El metadato "dc:publisher" guardado dentro del archivo EPUB difiere del nombre actual del grupo "${group.name}". Pulsa "Sincronizar" para actualizar el registro del libro con los datos del archivo.',
                        style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        if (filteredBooks.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.menu_book_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text('No se encontraron libros asociados con el filtro seleccionado.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredBooks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final b = filteredBooks[index];
              final isCopied = _copiedPathId == b.id;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: b.hasBadMetadata
                      ? Colors.amber.withValues(alpha: 0.05)
                      : const Color(0xFF1E293B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: b.hasBadMetadata
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Cover Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 75,
                        child: ZeepubCachedImage(
                          imageUrl: b.displayCover,
                          baseUrl: cubit.state.baseUrl,
                          fit: BoxFit.cover,
                          fallbackIconSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Book Details
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.displayTitle,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (b.volume != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Vol. ${b.volume! % 1 == 0 ? b.volume!.toInt() : b.volume}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                                  ),
                                ),
                              ],
                              if (b.role != null) ...[
                                const SizedBox(width: 6),
                                Text('Rol: ${b.role}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                              ],
                            ],
                          ),
                          if (b.seriesSpanish != null || b.seriesId != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              b.seriesSpanish ?? b.seriesId!,
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    b.filename ?? b.filepath ?? b.id,
                                    style: const TextStyle(fontSize: 10, color: Colors.white60, fontFamily: 'monospace'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (b.filepath != null && b.filepath!.isNotEmpty)
                                InkWell(
                                  onTap: () => _copyPath(b.id, b.filepath!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCopied ? Colors.green : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isCopied ? Icons.check : Icons.copy_rounded, size: 11, color: isCopied ? Colors.black : Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCopied ? 'Copiado' : 'Copiar Ruta',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isCopied ? Colors.black : Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => cubit.syncWorkgroupBooks(group.id, [b.id]),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sync_rounded, size: 11, color: Colors.white70),
                                      SizedBox(width: 4),
                                      Text('Re-escanear', style: TextStyle(fontSize: 9, color: Colors.white70)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // OPF Metadata Comparison Widget
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: b.hasBadMetadata
                                ? Colors.amber.withValues(alpha: 0.3)
                                : Colors.green.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Esperado:', style: TextStyle(fontSize: 10, color: Colors.white38)),
                                Text(group.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('En EPUB:', style: TextStyle(fontSize: 10, color: Colors.white38)),
                                Expanded(
                                  child: Text(
                                    '"${b.publisher ?? "Sin publisher"}"',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: b.hasBadMetadata ? Colors.amberAccent : Colors.greenAccent,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (b.hasBadMetadata && b.metadataIssue != null) ...[
                              const Divider(height: 10, color: Colors.white10),
                              Text(
                                b.metadataIssue!,
                                style: const TextStyle(fontSize: 9, color: Colors.amberAccent),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ===========================================================================
  // UI HELPERS & PILLS
  // ===========================================================================
  Widget _statPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabNavButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    int? badgeCount,
    String? badgeText,
    Color badgeColor = const Color(0xFF6366F1),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1).withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1).withValues(alpha: 0.6) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: selected ? Colors.white : Colors.white60),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected ? const Color(0xFF818CF8) : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount != null || badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeText ?? '$badgeCount',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String mode, Color? activeColor) {
    final isSelected = _filterMode == mode;
    final color = activeColor ?? const Color(0xFF6366F1);

    return InkWell(
      onTap: () => setState(() => _filterMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? (activeColor ?? Colors.white) : Colors.white60,
          ),
        ),
      ),
    );
  }
}
