import 'package:flutter/material.dart';

import '../../../data/models/publication.dart';
import '../../../shared/widgets/responsive_sheet.dart';

class PublicationCard extends StatelessWidget {
  const PublicationCard({required this.publication, super.key});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = publication.description.characters;
    final visibleDescription = description.length > 300
        ? '${description.take(300)}...'
        : publication.description;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: publication.type.color, width: 6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeChip(type: publication.type),
            const SizedBox(height: 12),
            Text(
              publication.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              visibleDescription,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            Text(
              'Por ${publication.authorName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _showFullPublication(context),
              icon: const Icon(Icons.open_in_full_rounded, size: 18),
              label: const Text('Expandir'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullPublication(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ResponsiveSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _TypeChip(type: publication.type),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              publication.title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SelectableText(
              publication.description,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 18),
            Text(
              'Publicado por ${publication.authorName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final PublicationType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
