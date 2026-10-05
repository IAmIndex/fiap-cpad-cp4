import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/theme_mode_button.dart';
import '../widgets/publication_card.dart';

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({required this.classId, super.key});

  final String classId;

  @override
  Widget build(BuildContext context) {
    final repository = AcademyaScope.repositoryOf(context);
    final currentUser = repository.currentUser;
    final schoolClass = repository.findClassById(classId);

    if (schoolClass == null || currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Turma')),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Turma não encontrada',
          message: 'Volte para a lista e tente novamente.',
        ),
      );
    }

    final canCreatePublication = schoolClass.isCreatedBy(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Publicações',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [ThemeModeButton()],
      ),
      body: AnimatedBuilder(
        animation: repository,
        builder: (context, _) {
          final publications = repository.publicationsForClass(classId);

          return PageContainer(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: publications.length + (publications.isEmpty ? 2 : 1),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolClass.name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Criada por ${schoolClass.creatorName}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText('Código: ${schoolClass.joinCode}'),
                      const SizedBox(height: 8),
                    ],
                  );
                }
                if (publications.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Sem publicações'),
                  );
                }
                return PublicationCard(publication: publications[index - 1]);
              },
            ),
          );
        },
      ),
      floatingActionButton: canCreatePublication
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.createPublication,
                arguments: classId,
              ),
              tooltip: 'Nova publicação',
              child: const Icon(Icons.edit_note_rounded),
            )
          : null,
    );
  }
}
