import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/routes.dart';
import '../../../data/models/school_class.dart';
import '../../../data/repositories/academya_repository.dart';
import '../../../data/services/authentication_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/theme_mode_button.dart';
import '../widgets/class_tile.dart';
import '../widgets/join_class_sheet.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final repository = AcademyaScope.repositoryOf(context);
    final firebaseStatus = AcademyaScope.firebaseStatusOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas turmas',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const ThemeModeButton(),
          IconButton(
            tooltip: 'Atualizar turmas',
            onPressed: repository.isLoadingData
                ? null
                : () {
                    if (firebaseStatus.isConnected) {
                      repository.refreshUserData();
                    } else {
                      _showFirebaseStatus(context, firebaseStatus.message);
                    }
                  },
            icon: Icon(
              firebaseStatus.isConnected
                  ? Icons.refresh_rounded
                  : Icons.cloud_off_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _signingOut ? null : () => _signOut(repository),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: repository,
        builder: (context, _) {
          final classes = repository.visibleClasses;
          final content = classes.isEmpty
              ? const EmptyState(
                  icon: Icons.groups_2_rounded,
                  title: 'Nenhuma turma por enquanto',
                  message: 'Use o botao de adicionar para entrar ou criar uma turma.',
                )
              : PageContainer(
                  child: RefreshIndicator(
                    onRefresh: repository.refreshUserData,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: classes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final schoolClass = classes[index];

                        return ClassTile(
                          schoolClass: schoolClass,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.classDetail,
                            arguments: schoolClass.id,
                          ),
                        );
                      },
                    ),
                  ),
                );
          return SafeArea(
            child: Column(
              children: [
                if (repository.isLoadingData) const LinearProgressIndicator(),
                if (repository.dataError != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            repository.dataError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tentar novamente',
                          onPressed: repository.isLoadingData
                              ? null
                              : repository.refreshUserData,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: content),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar turma',
        onPressed: repository.isLoadingData || _signingOut
            ? null
            : () => _openJoinSheet(context, repository),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openJoinSheet(BuildContext context, AcademyaRepository repository) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => JoinClassSheet(
        onJoin: (code) async {
          final joined = await repository.joinClassByCode(code);
          final message = joined
              ? 'Turma adicionada.'
              : 'Código de turma não encontrado.';

          if (!context.mounted) return joined;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));

          return joined;
        },
        onCreate:
            ({required String name, required SchoolClassType type}) async {
              final createdClass = await repository.createClass(
                name: name,
                type: type,
              );

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Turma criada: ${createdClass.joinCode}'),
                ),
              );
            },
      ),
    );
  }

  Future<void> _signOut(AcademyaRepository repository) async {
    setState(() => _signingOut = true);
    try {
      await repository.signOut();
    } on AuthenticationFailure catch (error) {
      if (mounted) _showFirebaseStatus(context, error.message);
    } catch (_) {
      if (mounted) {
        _showFirebaseStatus(context, 'Não foi possível sair. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showFirebaseStatus(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
