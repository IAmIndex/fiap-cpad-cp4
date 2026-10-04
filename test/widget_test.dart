import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/firebase/firebase_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_repository.dart';

void main() {
  testWidgets(
    'renders empty login and navigates after injected authentication',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        AcademiaApp(
          repository: createTestRepository(),
          firebaseStatus: FirebaseConnectionStatus.notConfigured(),
        ),
      );

      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'aluno@academya.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Aluno123');

      await tester.tap(find.byIcon(Icons.login_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Minhas turmas'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    },
  );
}
