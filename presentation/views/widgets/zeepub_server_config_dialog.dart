import 'package:flutter/material.dart';

import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';

/// Diálogo reutilizable para configurar la conexión al backend de ZeePub.
void showZeepubServerConfigDialog(
  BuildContext context, {
  required String currentUrl,
  required String currentTgId,
  required double currentScale,
  required ZeepubEditorialCubit cubit,
}) {
  final urlController = TextEditingController(text: currentUrl);
  final tgIdController = TextEditingController(text: currentTgId);
  double selectedScale = currentScale;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune_rounded),
          SizedBox(width: 8),
          Text('Ajustes del Servidor ZeePub'),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL del Servidor (VPS / Local)',
                hintText: 'http://176.223.137.101:8001',
                helperText: 'Dirección IP o dominio del backend de ZeePub con su puerto.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tgIdController,
              decoration: const InputDecoration(
                labelText: 'ID de Telegram (Admin / Staff)',
                hintText: '133994080',
                helperText: 'Tu ID numérico de Telegram para identificarte como Admin/Staff provisoriamente.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_rounded),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),
            StatefulBuilder(
              builder: (context, setLocalState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.photo_size_select_actual_outlined, size: 16, color: Color(0xFF818CF8)),
                            SizedBox(width: 8),
                            Text(
                              'Escala de Portadas',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(selectedScale * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF38BDF8),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                        thumbColor: const Color(0xFF38BDF8),
                        overlayColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: selectedScale,
                        min: 0.70,
                        max: 1.50,
                        divisions: 16,
                        onChanged: (val) {
                          setLocalState(() => selectedScale = val);
                          cubit.setCoverScale(val);
                        },
                      ),
                    ),
                  ],
                );
              },
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
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Guardar y Conectar'),
          onPressed: () {
            final newUrl = urlController.text.trim();
            final newTgId = tgIdController.text.trim();
            Navigator.of(ctx).pop();
            cubit.saveServerConfig(url: newUrl, tgId: newTgId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuración guardada. Conectando con el servidor...'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
      ],
    ),
  );
}
