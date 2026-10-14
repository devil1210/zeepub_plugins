import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_template.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';
import 'telegram_simulator.dart';

class ZeepubTemplatesTab extends StatefulWidget {
  const ZeepubTemplatesTab({super.key});

  @override
  State<ZeepubTemplatesTab> createState() => _ZeepubTemplatesTabState();
}

class _ZeepubTemplatesTabState extends State<ZeepubTemplatesTab> {
  ZeepubTemplate? _selectedTemplate;
  late final TextEditingController _nameController;
  late final TextEditingController _contentController;
  String _platform = 'telegram';
  bool _isDefault = false;

  final List<String> _variables = [
    '{serie}',
    '{volumen}',
    '{titulo}',
    '{autor}',
    '{illustrator}',
    '{traductor}',
    '{editorial}',
    '{sinopsis}',
    '{demography}',
    '{genres}',
    '{tomoid}',
    '{fecha}',
    '{published_at}',
    '{slug}',
    '{download_link}',
    '{layout_by}',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _selectTemplate(ZeepubTemplate tpl) {
    setState(() {
      _selectedTemplate = tpl;
      _nameController.text = tpl.name;
      _contentController.text = tpl.content;
      _platform = tpl.platform;
      _isDefault = tpl.isDefault;
    });
  }

  void _createNewTemplate() {
    setState(() {
      _selectedTemplate = const ZeepubTemplate(
        name: 'Nueva Plantilla Telegram',
        content: '<b>{series_english}</b>\n[?volumen]<b>Volumen {volumen}</b>\n[/?]#{slug}',
        platform: 'telegram',
      );
      _nameController.text = _selectedTemplate!.name;
      _contentController.text = _selectedTemplate!.content;
      _platform = 'telegram';
      _isDefault = false;
    });
  }

  void _insertTag(String tag) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, tag);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + tag.length),
    );
    setState(() {});
  }

  void _wrapTag(String open, String close) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start >= 0 && selection.end > selection.start) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$open$selectedText$close');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.end + open.length + close.length),
      );
    } else {
      _insertTag('$open$close');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (context, state) {
        final cubit = context.read<ZeepubEditorialCubit>();
        final templates = state.templates;

        if (templates.isNotEmpty && _selectedTemplate == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _selectTemplate(templates.first);
          });
        }

        return Row(
          children: [
            // LEFT SIDEBAR: Saved Templates List
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_copy_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text('PLANTILLAS GUARDADAS', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: 'Restaurar Predeterminadas Oficiales',
                          onPressed: () => cubit.restoreTemplates(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: 'Nueva Plantilla',
                          onPressed: _createNewTemplate,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, idx) {
                        final tpl = templates[idx];
                        final isSelected = _selectedTemplate?.id == tpl.id || (_selectedTemplate?.id == null && _selectedTemplate?.name == tpl.name);
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
                          leading: Icon(
                            tpl.isDefault ? Icons.star_rounded : (tpl.platform == 'facebook' ? Icons.facebook : Icons.send_rounded),
                            color: tpl.isDefault ? Colors.amber : (tpl.platform == 'facebook' ? Colors.blue : Colors.lightBlueAccent),
                            size: 20,
                          ),
                          title: Text(
                            tpl.name,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            tpl.platform.toUpperCase(),
                            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          onTap: () => _selectTemplate(tpl),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // CENTER: Template Form & Copy Editor
            Expanded(
              flex: 5,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isDefault ? Colors.amber.withValues(alpha: 0.2) : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isDefault ? Colors.amber : cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(_isDefault ? Icons.star_rounded : Icons.code_rounded, size: 14, color: _isDefault ? Colors.amber : cs.onSurface),
                            const SizedBox(width: 6),
                            Text(
                              _isDefault ? 'Plantilla Oficial Predeterminada' : 'Plantilla Personalizada',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isDefault ? Colors.amber : cs.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      FilterChip(
                        label: const Text('Fijar Oficial'),
                        selected: _isDefault,
                        onSelected: (val) => setState(() => _isDefault = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nombre de la plantilla'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _platform,
                          decoration: const InputDecoration(labelText: 'Plataforma objetivo'),
                          items: const [
                            DropdownMenuItem(value: 'telegram', child: Text('Telegram')),
                            DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _platform = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // COPY EDITOR TOOLBAR
                  Text('EDITOR DE COPY', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _formatButton('B', () => _wrapTag('<b>', '</b>')),
                      _formatButton('I', () => _wrapTag('<i>', '</i>')),
                      _formatButton('U', () => _wrapTag('<u>', '</u>')),
                      _formatButton('S', () => _wrapTag('<s>', '</s>')),
                      _formatButton('Cita', () => _wrapTag('<blockquote>', '</blockquote>')),
                      _formatButton('Expandible', () => _wrapTag('<details><summary>Titulo</summary>', '</details>')),
                      _formatButton('H', () => _wrapTag('<h3>', '</h3>')),
                      _formatButton('Tabla', () => _wrapTag('<table><tr><td>', '</td></tr></table>')),
                      _formatButton('Enlace', () => _wrapTag('<a href="URL">', '</a>')),
                      _formatButton('Condicional [?]', () => _wrapTag('[?volumen]', '[/?]')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // VARIABLES DISPONIBLES
                  Text('VARIABLES DISPONIBLES (Haz clic para insertar):', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in _variables)
                        ActionChip(
                          label: Text(v, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                          padding: EdgeInsets.zero,
                          onPressed: () => _insertTag(v),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _contentController,
                    maxLines: 16,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      hintText: 'Escribe el código HTML enriquecido o plantilla...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      if (_selectedTemplate?.id != null)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Eliminar Plantilla', style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            cubit.deleteTemplate(_selectedTemplate!.id!);
                            setState(() => _selectedTemplate = null);
                          },
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Guardar y Aplicar Plantilla'),
                        onPressed: () {
                          final payload = {
                            if (_selectedTemplate?.id != null) 'id': _selectedTemplate!.id,
                            'name': _nameController.text.trim(),
                            'content': _contentController.text,
                            'platform': _platform,
                            'is_default': _isDefault,
                          };
                          cubit.saveTemplate(payload);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // RIGHT: Live Interactive Telegram Simulator
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TelegramSimulator(
                  templateContent: _contentController.text,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _formatButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
