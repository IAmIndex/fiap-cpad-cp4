import 'package:flutter/material.dart';

import '../core/firebase/firebase_sync_service.dart';
import '../data/repositories/academya_repository.dart';
import 'routes.dart';
import 'theme.dart';
import 'theme_controller.dart';

class AcademiaApp extends StatefulWidget {
  const AcademiaApp({
    required this.repository,
    required this.firebaseStatus,
    this.themeController,
    super.key,
  });

  final AcademyaRepository repository;
  final FirebaseConnectionStatus firebaseStatus;
  final ThemeController? themeController;

  @override
  State<AcademiaApp> createState() => _AcademiaAppState();
}

class _AcademiaAppState extends State<AcademiaApp> {
  late final _themeController = widget.themeController ?? ThemeController();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late bool _wasAuthenticated;

  @override
  void initState() {
    super.initState();
    _wasAuthenticated = widget.repository.isAuthenticated;
    widget.repository.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    final authenticated = widget.repository.isAuthenticated;
    if (_wasAuthenticated && !authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.repository.isAuthenticated) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (_) => false,
          );
        }
      });
    }
    _wasAuthenticated = authenticated;
  }

  @override
  void dispose() {
    widget.repository.removeListener(_sessionChanged);
    if (widget.themeController == null) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AcademyaScope(
      repository: widget.repository,
      firebaseStatus: widget.firebaseStatus,
      child: ThemeScope(
        controller: _themeController,
        child: AnimatedBuilder(
          animation: _themeController,
          builder: (context, _) => MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Academya',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeController.mode,
            initialRoute: widget.repository.isAuthenticated
                ? AppRoutes.classes
                : AppRoutes.login,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            onGenerateInitialRoutes: (route) => [
              AppRoutes.onGenerateRoute(RouteSettings(name: route)),
            ],
          ),
        ),
      ),
    );
  }
}

class AcademyaScope extends InheritedNotifier<AcademyaRepository> {
  const AcademyaScope({
    required AcademyaRepository repository,
    required this.firebaseStatus,
    required super.child,
    super.key,
  }) : super(notifier: repository);

  final FirebaseConnectionStatus firebaseStatus;

  static AcademyaRepository repositoryOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AcademyaScope>();
    assert(scope != null, 'AcademyaScope não encontrado na árvore.');
    return scope!.notifier!;
  }

  static FirebaseConnectionStatus firebaseStatusOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AcademyaScope>();
    assert(scope != null, 'AcademyaScope não encontrado na árvore.');
    return scope!.firebaseStatus;
  }
}
