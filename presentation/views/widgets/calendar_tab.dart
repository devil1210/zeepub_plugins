import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_channel.dart';
import '/features/zeepub_editorial/data/models/zeepub_queue_item.dart';
import '/features/zeepub_editorial/data/models/zeepub_template.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';
import 'zeepub_cached_image.dart';

class ZeepubCalendarTab extends StatefulWidget {
  const ZeepubCalendarTab({super.key});

  @override
  State<ZeepubCalendarTab> createState() => _ZeepubCalendarTabState();
}

class _ZeepubCalendarTabState extends State<ZeepubCalendarTab> {
  String _statusFilter = 'all'; // 'all', 'scheduled', 'sent', 'failed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZeepubEditorialCubit>().loadQueue();
    });
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'Fecha no definida';
    try {
      final normalized = dateStr.endsWith('Z') || dateStr.contains('+') ? dateStr : '${dateStr}Z';
      final d = DateTime.parse(normalized).toLocal();
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year.toString();
      final hour24 = d.hour;
      final minute = d.minute.toString().padLeft(2, '0');
      final second = d.second.toString().padLeft(2, '0');
      final period = hour24 >= 12 ? 'p. m.' : 'a. m.';
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final hour12Str = hour12.toString().padLeft(2, '0');
      return '$day/$month/$year, $hour12Str:$minute:$second $period';
    } catch (_) {
      return dateStr;
    }
  }

  String _getTimezoneLabel() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    final sign = hours >= 0 ? '+' : '-';
    final absHours = hours.abs().toString().padLeft(2, '0');
    return 'Hora Local (${now.timeZoneName.isNotEmpty ? now.timeZoneName : "UTC$sign$absHours"})';
  }

  void _showEditQueueDialog(
    BuildContext context,
    ZeepubEditorialState state,
    ZeepubEditorialCubit cubit,
    ZeepubQueueItem item,
  ) {
    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay scheduledTime = TimeOfDay.fromDateTime(scheduledDate);

    if (item.scheduledFor != null && item.scheduledFor!.isNotEmpty) {
      try {
        final normalized = item.scheduledFor!.endsWith('Z') || item.scheduledFor!.contains('+')
            ? item.scheduledFor!
            : '${item.scheduledFor!}Z';
        final parsedLocal = DateTime.parse(normalized).toLocal();
        scheduledDate = parsedLocal;
        scheduledTime = TimeOfDay.fromDateTime(parsedLocal);
      } catch (_) {}
    }

    ZeepubChannel? selectedChannel;
    final targetChanId = item.channelId ?? (item.payload?['channel_id'] is num ? (item.payload!['channel_id'] as num).toInt() : null);
    if (targetChanId != null && state.channels.isNotEmpty) {
      selectedChannel = state.channels.where((c) => c.id == targetChanId).firstOrNull;
    }
    selectedChannel ??= state.channels.where((c) => c.isFavorite).firstOrNull ?? (state.channels.isNotEmpty ? state.channels.first : null);

    ZeepubTemplate? selectedTemplate;
    final targetTempId = item.templateId ?? (item.payload?['template_id'] is num ? (item.payload!['template_id'] as num).toInt() : null);
    if (targetTempId != null && state.templates.isNotEmpty) {
      selectedTemplate = state.templates.where((t) => t.id == targetTempId).firstOrNull;
    }
    if (selectedTemplate == null && selectedChannel != null) {
      selectedTemplate = state.templates.where((t) => t.platform.toLowerCase() == selectedChannel!.platform.toLowerCase() && t.isDefault).firstOrNull
          ?? state.templates.where((t) => t.platform.toLowerCase() == selectedChannel!.platform.toLowerCase()).firstOrNull;
    }
    selectedTemplate ??= state.templates.where((t) => t.isDefault).firstOrNull ?? (state.templates.isNotEmpty ? state.templates.first : null);

    final captionCtrl = TextEditingController(text: item.caption ?? '');
    bool sendAsFile = item.sendAsFile ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF818CF8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Publicación Programada',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.bookTitle} · ${item.volume != null ? "Vol. " + (item.volume! % 1 == 0 ? item.volume!.toInt().toString() : item.volume.toString()) : "ID #" + item.id.toString()}',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Canal & Plantilla Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ZeepubChannel>(
                            value: selectedChannel,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Canal de Destino',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.send_rounded, size: 16),
                            ),
                            items: state.channels.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) => setDlgState(() => selectedChannel = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<ZeepubTemplate>(
                            value: selectedTemplate,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Plantilla Editorial',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.table_chart_rounded, size: 16),
                            ),
                            items: state.templates.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) => setDlgState(() => selectedTemplate = val),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Fecha y Hora Programada
                    const Text('FECHA Y HORA DE PUBLICACIÓN (HORA LOCAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Date Picker Button
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(
                              '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: scheduledDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setDlgState(() => scheduledDate = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Time Picker Button
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_rounded, size: 16),
                            label: Text(
                              '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: scheduledTime,
                              );
                              if (picked != null) setDlgState(() => scheduledTime = picked);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Custom Caption Editor
                    const Text('MENSAJE / CAPTION PERSONALIZADO (OPCIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: captionCtrl,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                      decoration: const InputDecoration(
                        hintText: 'Deja en blanco para autogenerar con la plantilla seleccionada...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Send as file checkbox
                    CheckboxListTile(
                      value: sendAsFile,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Adjuntar archivo EPUB al mensaje', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Envía el archivo EPUB real junto con la ficha estructurada.', style: TextStyle(fontSize: 10, color: Colors.white60)),
                      onChanged: (v) => setDlgState(() => sendAsFile = v ?? true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: const Text('Cancelar Programación', style: TextStyle(color: Colors.redAccent)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  cubit.cancelQueueItem(item.id);
                },
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.amberAccent),
                label: const Text('Publicar Ahora', style: TextStyle(color: Colors.amberAccent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
                  backgroundColor: Colors.amber.withValues(alpha: 0.08),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final dt = DateTime(
                    scheduledDate.year,
                    scheduledDate.month,
                    scheduledDate.day,
                    scheduledTime.hour,
                    scheduledTime.minute,
                  );
                  cubit.updateQueueItem(
                    id: item.id,
                    scheduledFor: dt.toUtc().toIso8601String(),
                    channelId: selectedChannel?.id,
                    templateId: selectedTemplate?.id,
                    customCaption: captionCtrl.text.trim().isNotEmpty ? captionCtrl.text.trim() : null,
                    sendAsFile: sendAsFile,
                    immediate: true,
                  );
                },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Guardar Horario'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final dt = DateTime(
                    scheduledDate.year,
                    scheduledDate.month,
                    scheduledDate.day,
                    scheduledTime.hour,
                    scheduledTime.minute,
                  );
                  cubit.updateQueueItem(
                    id: item.id,
                    scheduledFor: dt.toUtc().toIso8601String(),
                    channelId: selectedChannel?.id,
                    templateId: selectedTemplate?.id,
                    customCaption: captionCtrl.text.trim().isNotEmpty ? captionCtrl.text.trim() : null,
                    sendAsFile: sendAsFile,
                  );
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
        final allItems = state.queue;

        final filtered = allItems.where((item) {
          if (_statusFilter == 'all') return true;
          final st = item.status.toLowerCase();
          if (_statusFilter == 'scheduled') {
            return st == 'pending' || st == 'scheduled' || st == 'programado';
          }
          if (_statusFilter == 'sent') {
            return st == 'sent' || st == 'published' || st == 'completado';
          }
          if (_statusFilter == 'failed') {
            return st == 'failed' || st == 'fallido' || st == 'error';
          }
          return true;
        }).toList();

        final scheduledCount = allItems.where((i) => ['pending', 'scheduled', 'programado'].contains(i.status.toLowerCase())).length;
        final sentCount = allItems.where((i) => ['sent', 'published', 'completado'].contains(i.status.toLowerCase())).length;
        final failedCount = allItems.where((i) => ['failed', 'fallido', 'error'].contains(i.status.toLowerCase())).length;

        return Column(
          children: [
            // Top Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF818CF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agenda y Cola de Publicación',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Programación automática de lanzamientos en canales de Telegram y páginas oficiales.',
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Timezone Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF818CF8)),
                        const SizedBox(width: 6),
                        Text(_getTimezoneLabel(), style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                      ],
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
                        _filterTab('Todos', 'all', allItems.length, const Color(0xFF6366F1)),
                        _filterTab('Programados', 'scheduled', scheduledCount, Colors.amber),
                        _filterTab('Completados', 'sent', sentCount, Colors.green),
                        if (failedCount > 0)
                          _filterTab('Fallidos', 'failed', failedCount, Colors.red, isAlert: true),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Actualizar agenda',
                    onPressed: () => cubit.loadQueue(),
                  ),
                ],
              ),
            ),

            // Queue List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded, size: 54, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay publicaciones en la agenda para el filtro seleccionado.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Puedes agendar publicaciones desde la vista de cada tomo.',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isFailed = ['failed', 'fallido', 'error'].contains(item.status.toLowerCase());
                        final isCompleted = ['sent', 'published', 'completado'].contains(item.status.toLowerCase());
                        final isScheduled = item.isScheduled;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isFailed
                                ? Colors.red.withValues(alpha: 0.08)
                                : (isCompleted
                                    ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                                    : const Color(0xFF1E293B).withValues(alpha: 0.7)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFailed
                                  ? Colors.red.withValues(alpha: 0.4)
                                  : (isCompleted
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFF6366F1).withValues(alpha: 0.3)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Cover thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 62,
                                  child: ZeepubCachedImage(
                                    imageUrl: item.coverUrl ?? '',
                                    baseUrl: state.baseUrl,
                                    fit: BoxFit.cover,
                                    placeholder: Container(
                                      color: Colors.black26,
                                      child: const Center(child: Icon(Icons.menu_book, size: 20, color: Colors.white24)),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Main Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.bookTitle,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (item.volume != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Vol. ${item.volume! % 1 == 0 ? item.volume!.toInt() : item.volume}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        _statusPill(item.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        // Platform Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.platform == 'facebook'
                                                ? Colors.blue.withValues(alpha: 0.2)
                                                : Colors.cyan.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                item.platform == 'facebook' ? Icons.facebook_rounded : Icons.send_rounded,
                                                size: 10,
                                                color: item.platform == 'facebook' ? Colors.blueAccent : Colors.cyanAccent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.platform.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.platform == 'facebook' ? Colors.blueAccent : Colors.cyanAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Destino: ${item.channelName}',
                                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF818CF8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateTime(item.scheduledFor ?? item.publishedAt),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF818CF8), fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    if (item.errorMessage != null && item.errorMessage!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Error: ${item.errorMessage}',
                                        style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Action buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isScheduled) ...[
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: Color(0xFF818CF8)),
                                      label: const Text('Editar Horario', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () => _showEditQueueDialog(context, state, cubit, item),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                                        foregroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () => cubit.cancelQueueItem(item.id),
                                      child: const Text('Cancelar', style: TextStyle(fontSize: 11)),
                                    ),
                                  ] else if (isFailed) ...[
                                    FilledButton.icon(
                                      icon: const Icon(Icons.replay_rounded, size: 14),
                                      label: const Text('Reintentar', style: TextStyle(fontSize: 11)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.amber.shade700,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () => cubit.retryQueueItem(item.id),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                                      label: const Text('Editar', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () => _showEditQueueDialog(context, state, cubit, item),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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

  Widget _filterTab(String label, String mode, int count, Color activeColor, {bool isAlert = false}) {
    final isSelected = _statusFilter == mode;

    return InkWell(
      onTap: () => setState(() => _statusFilter = mode),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : (isAlert ? Colors.redAccent : Colors.white60),
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
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color bg;
    Color border;
    Color fg;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
      case 'scheduled':
      case 'programado':
        bg = Colors.amber.withValues(alpha: 0.15);
        border = Colors.amber.withValues(alpha: 0.4);
        fg = Colors.amberAccent;
        text = 'PROGRAMADO';
        break;
      case 'sent':
      case 'published':
      case 'completado':
        bg = Colors.green.withValues(alpha: 0.15);
        border = Colors.green.withValues(alpha: 0.4);
        fg = Colors.greenAccent;
        text = 'PUBLICADO';
        break;
      case 'failed':
      case 'fallido':
      case 'error':
        bg = Colors.red.withValues(alpha: 0.15);
        border = Colors.red.withValues(alpha: 0.4);
        fg = Colors.redAccent;
        text = 'FALLIDO';
        break;
      default:
        bg = Colors.white.withValues(alpha: 0.1);
        border = Colors.white.withValues(alpha: 0.2);
        fg = Colors.white70;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
