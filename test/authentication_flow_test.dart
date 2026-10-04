import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/firebase/firebase_sync_service.dart';
import 'package:flutter_application_1/data/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_repository.dart';

void main() {
  testWidgets(
    'login reports invalid credentials and prevents duplicate submissions',
    (tester) async {
      final auth = MemoryAuthenticationService();
      final repository = createTestRepository(auth: auth);
      addTearDown(repository.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        AcademiaApp(
          repository: repository,
          firebaseStatus: FirebaseConnectionStatus.notConfigured(),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'aluno@academya.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('E-mail ou senha invalidos.'), findsOneWidget);
      expect(repository.isAuthenticated, isFalse);
      auth.pendingSignIn = Completer<AppUser>();
      await tester.enterText(find.byType(TextFormField).at(1), 'Aluno123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(auth.signInCalls, 2);
      auth.pendingSignIn!.complete(auth.accounts['aluno@academya.com']!.user);
      await tester.pumpAndSettle();
      expect(find.text('Minhas turmas'), findsOneWidget);
    },
  );

  testWidgets(
    'password reset uses the entered email without requiring password',
    (tester) async {
      final auth = MemoryAuthenticationService();
      final repository = createTestRepository(auth: auth);
      addTearDown(repository.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        AcademiaApp(
          repository: repository,
          firebaseStatus: FirebaseConnectionStatus.notConfigured(),
        ),
      );
      await tester.ensureVisible(find.text('Esqueci minha senha'));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();
      expect(
        find.text('Preencha seu e-mail para recuperar a senha.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'maria@example.com',
      );
      await tester.ensureVisible(find.text('Esqueci minha senha'));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();
      expect(auth.resetEmail, 'maria@example.com');
      expect(repository.isAuthenticated, isFalse);
    },
  );

  testWidgets(
    'restored session starts at classes and auth signout returns to login',
    (tester) async {
      final auth = MemoryAuthenticationService(
        currentUser: const AppUser(
          id: 'real-uid',
          fullName: 'Maria Silva',
          email: 'maria@example.com',
        ),
      );
      final repository = createTestRepository(auth: auth);
      addTearDown(repository.dispose);
      addTearDown(auth.dispose);
      await repository.initializeSession();
      await tester.pumpWidget(
        AcademiaApp(
          repository: repository,
          firebaseStatus: FirebaseConnectionStatus.notConfigured(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Minhas turmas'), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Minhas turmas'), findsNothing);
    },
  );
}
