import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';

class TelegramPublishDialog extends StatefulWidget {
  final ZeepubVolume volume;
  final String baseUrl;

  const TelegramPublishDialog({
    super.key,
    required this.volume,
    required this.baseUrl,
  });

  @override
  State<TelegramPublishDialog> createState() => _TelegramPublishDialogState();
}

class _TelegramPublishDialogState extends State<TelegramPublishDialog> {
  bool _isScheduled = false;
  DateTime _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
  final TextEditingController _captionController = TextEditingController();
  final bool _sendAsFile = true;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledDateTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _handleSubmit() async {
    final cubit = context.read<ZeepubEditorialCubit>();
    final customCaption = _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null;

    if (_isScheduled) {
      await cubit.schedulePublication(
        bookHash: widget.volume.bookHash,
        scheduledAtIso: _scheduledDateTime.toIso8601String(),
        customCaption: customCaption,
        sendAsFile: _sendAsFile,
      );
    } else {
      await cubit.publishNow(
        bookHash: widget.volume.bookHash,
        customCaption: customCaption,
        sendAsFile: _sendAsFile,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (BuildContext context, ZeepubEditorialState state) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.send_rounded, color: cs.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Publicar en Canal de Telegram',
                          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Book Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.volume.spanishTitle.isNotEmpty
                              ? widget.volume.spanishTitle
                              : widget.volume.title,
                          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.volume.volume != null)
                          Text('Volumen ${widget.volume.volume}', style: tt.bodySmall),
                        Text(
                          'Fansub: ${widget.volume.publisher ?? "Sin fansub"} | Trad: ${widget.volume.translator ?? "N/A"}',
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mode Selector
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Publicar Ahora'),
                        icon: Icon(Icons.send_rounded),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Programar'),
                        icon: Icon(Icons.schedule_rounded),
                      ),
                    ],
                    selected: {_isScheduled},
                    onSelectionChanged: (set) {
                      setState(() {
                        _isScheduled = set.first;
                      });
                    },
                  ),

                  if (_isScheduled) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      leading: Icon(Icons.calendar_today_rounded, color: cs.primary),
                      title: const Text('Fecha y Hora programada'),
                      subtitle: Text(_scheduledDateTime.toString().substring(0, 16)),
                      trailing: TextButton(
                        onPressed: _pickDateTime,
                        child: const Text('Cambiar'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  TextField(
                    controller: _captionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje / Caption personalizado (Opcional)',
                      hintText: 'Dejar vacío para usar la plantilla automática estándar...',
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: state.saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        icon: state.saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_isScheduled ? Icons.schedule_send : Icons.send_rounded, size: 18),
                        label: Text(_isScheduled ? 'Programar Envío' : 'Publicar Inmediatamente'),
                        onPressed: state.saving ? null : _handleSubmit,
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
