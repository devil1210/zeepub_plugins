import 'package:flutter/material.dart';

import '/features/epub_templater/domain/book_metadata.dart';

/// Tarjeta de auditoría y validación visual de metadatos de un archivo EPUB.
class EpubMetadataValidatorCard extends StatelessWidget {
  final BookMetadata? metadata;
  final String? fileName;
  final String? filePath;
  final int fileSizeBytes;
  final String? sha256Hash;
  final bool isProcessing;
  final String? error;

  const EpubMetadataValidatorCard({
    super.key,
    required this.metadata,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.sha256Hash,
    required this.isProcessing,
    this.error,
  });

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isProcessing) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analizando estructura y metadatos del EPUB...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Card(
        elevation: 0,
        color: cs.errorContainer.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: cs.error, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Error al validar el archivo: $error',
                  style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (metadata == null || filePath == null) {
      return const SizedBox.shrink();
    }

    final meta = metadata!;
    final hasTitle = meta.title.trim().isNotEmpty;
    final authorName = meta.actors.where((a) => a.isCreator || a.name.isNotEmpty).firstOrNull?.name ?? '';
    final hasAuthor = authorName.trim().isNotEmpty;
    final hasSeries = meta.series.trim().isNotEmpty;
    final hasVolume = meta.seriesIndex.trim().isNotEmpty && meta.seriesIndex.trim() != '0';
    final hasLang = meta.language.trim().isNotEmpty;
    final hasDesc = meta.description.trim().isNotEmpty;
    final hasPublisher = meta.publishers.isNotEmpty && meta.publishers.first.trim().isNotEmpty;

    int passedChecks = 0;
    if (hasTitle) passedChecks++;
    if (hasAuthor) passedChecks++;
    if (hasSeries) passedChecks++;
    if (hasVolume) passedChecks++;
    if (hasLang) passedChecks++;
    if (hasDesc) passedChecks++;
    if (hasPublisher) passedChecks++;
    if (sha256Hash != null) passedChecks++;

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
            // Header con puntuación de calidad
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: passedChecks >= 6 ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    passedChecks >= 6 ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    color: passedChecks >= 6 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Auditoría de Metadatos del EPUB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: passedChecks >= 6 ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$passedChecks / 8 verificados',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: passedChecks >= 6 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Inspección automática de campos OPF y validación de integridad',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Archivo y Hash
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 18, color: Color(0xFF818CF8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(_formatFileSize(fileSizeBytes), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    'SHA-256: ${sha256Hash ?? 'Calculando...'}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Grid de Checks de Validación
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildCheckBadge(
                  label: 'Título',
                  value: hasTitle ? meta.title : 'No definido',
                  isValid: hasTitle,
                  isWarning: !hasTitle,
                ),
                _buildCheckBadge(
                  label: 'Autor',
                  value: hasAuthor ? authorName : 'Sin autor',
                  isValid: hasAuthor,
                  isWarning: !hasAuthor,
                ),
                _buildCheckBadge(
                  label: 'Serie',
                  value: hasSeries ? meta.series : 'No declarada',
                  isValid: hasSeries,
                  isWarning: false,
                ),
                _buildCheckBadge(
                  label: 'Volumen',
                  value: hasVolume ? 'Vol. ${meta.seriesIndex}' : 'Sin número',
                  isValid: hasVolume,
                  isWarning: !hasVolume,
                ),
                _buildCheckBadge(
                  label: 'Idioma',
                  value: hasLang ? meta.language.toUpperCase() : 'Desconocido',
                  isValid: hasLang,
                  isWarning: !hasLang,
                ),
                _buildCheckBadge(
                  label: 'Editorial',
                  value: hasPublisher ? meta.publishers.first : 'Sin editorial',
                  isValid: hasPublisher,
                  isWarning: false,
                ),
                _buildCheckBadge(
                  label: 'Sinopsis',
                  value: hasDesc ? '${meta.description.length} caracteres' : 'Vacía',
                  isValid: hasDesc,
                  isWarning: !hasDesc,
                ),
                _buildCheckBadge(
                  label: 'Tipo',
                  value: meta.bookType.isNotEmpty ? meta.bookType : 'Novela ligera',
                  isValid: true,
                  isWarning: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckBadge({
    required String label,
    required String value,
    required bool isValid,
    required bool isWarning,
  }) {
    final color = isWarning
        ? Colors.amber
        : isValid
            ? Colors.green
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : isValid
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
