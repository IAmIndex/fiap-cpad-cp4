import 'package:flutter/material.dart';

import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/classes/presentation/class_detail_screen.dart';
import '../features/classes/presentation/classes_screen.dart';
import '../features/publications/presentation/create_publication_screen.dart';

class AppRoutes {
  static const login = '/';
  static const register = '/register';
  static const classes = '/classes';
  static const classDetail = '/classes/detail';
  static const createPublication = '/classes/detail/create-publication';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) {
        switch (settings.name) {
          case login:
            return const LoginScreen();
          case register:
            return const RegisterScreen();
          case classes:
            return const ClassesScreen();
          case classDetail:
            return ClassDetailScreen(classId: settings.arguments! as String);
          case createPublication:
            return CreatePublicationScreen(
              classId: settings.arguments! as String,
            );
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
