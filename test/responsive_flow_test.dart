import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/theme_controller.dart';
import 'package:flutter_application_1/core/firebase/firebase_sync_service.dart';
import 'package:flutter_application_1/data/models/school_class.dart';
import 'package:flutter_application_1/data/models/publication.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_repository.dart';

void main() {
  final layouts = <({Size size, double scale})>[
    (size: const Size(320, 568), scale: 1),
    (size: const Size(360, 800), scale: 1),
    (size: const Size(430, 932), scale: 1),
    (size: const Size(800, 360), scale: 1),
    (size: const Size(320, 640), scale: 2),
    (size: const Size(768, 1024), scale: 1),
    (size: const Size(1280, 800), scale: 1),
  ];

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final layout in layouts) {
      testWidgets(
        'mobile workflow ${layout.size} font ${layout.scale} ${mode.name}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = layout.size;
          tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final repository = createTestRepository();
          final controller = ThemeController();
          await controller.setMode(mode);
          addTearDown(repository.dispose);
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            AcademiaApp(
              repository: repository,
              firebaseStatus: FirebaseConnectionStatus.notConfigured(),
              themeController: controller,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await _tapVisible(tester, find.text('Criar conta'));
          tester.view.viewInsets = FakeViewPadding(
            bottom: layout.size.height < 500 ? 140 : 260,
          );
          await tester.pumpAndSettle();
          await _tapVisible(tester, find.text('Cadastrar'));
          expect(find.text('Informe seu nome completo.'), findsOneWidget);
          expect(find.text('Use letras e numeros na senha.'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _tapVisible(tester, find.text('Ja tenho conta'));
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          await _fillLogin(tester);
          await _tapVisible(tester, find.text('Entrar'));
          expect(repository.isAuthenticated, isTrue);
          expect(find.text('Minhas turmas'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip('Adicionar turma'));
          await tester.pumpAndSettle();
          tester.view.viewInsets = FakeViewPadding(
            bottom: layout.size.height < 500 ? 140 : 260,
          );
          await tester.pumpAndSettle();
          await _tapVisible(tester, find.text('Participar'));
          expect(find.text('Informe o codigo.'), findsOneWidget);
          await _tapVisible(tester, find.text('Criar turma'));
          await tester.enterText(
            find.byType(TextFormField),
            'Estudos de Flutter e desenvolvimento mobile',
          );
          await _tapVisible(
            tester,
            find.descendant(
              of: find.byType(SegmentedButton<SchoolClassType>),
              matching: find.text('Grupo de estudos'),
            ),
          );
          await _tapVisible(tester, find.text('Salvar'));
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          final schoolClass = repository.visibleClasses.last;
          await tester.pump(const Duration(seconds: 4));
          expect(schoolClass.type, SchoolClassType.studyGroup);
          expect(tester.takeException(), isNull);

          await _tapVisible(tester, find.text(schoolClass.name));
          expect(find.byTooltip('Nova publicacao'), findsOneWidget);
          await tester.tap(find.byTooltip('Nova publicacao'));
          await tester.pumpAndSettle();
          tester.view.viewInsets = FakeViewPadding(
            bottom: layout.size.height < 500 ? 140 : 260,
          );
          await tester.pumpAndSettle();
          await _tapVisible(tester, find.text('Publicar'));
          await _showVisible(tester, find.text('Informe o titulo.'));
          expect(find.text('Informe o titulo.'), findsOneWidget);
          await _showVisible(tester, find.text('Informe a descricao.'));
          expect(find.text('Informe a descricao.'), findsOneWidget);
          final titleFinder = find.widgetWithText(
            TextFormField,
            'Titulo da publicacao',
          );
          final descriptionFinder = find.widgetWithText(
            TextField,
            'Descricao da publicacao',
          );
          await _showVisible(tester, titleFinder);
          await tester.enterText(titleFinder, List.filled(70, 'a').join());
          expect(
            tester
                .widget<TextFormField>(titleFinder)
                .controller!
                .text
                .characters
                .length,
            50,
          );
          await tester.enterText(titleFinder, 'Plano de estudos');
          await _showVisible(tester, descriptionFinder);
          await tester.enterText(
            descriptionFinder,
            List.filled(30, 'Conteudo completo da publicacao. ').join(),
          );
          await tester.pumpAndSettle();
          final descriptionField = tester.widget<TextField>(descriptionFinder);
          expect(descriptionField.controller!.text.characters.length, 900);
          expect(find.text('900/900'), findsOneWidget);
          await _tapVisible(
            tester,
            find.byType(DropdownButtonFormField<PublicationType>),
          );
          await _tapVisible(tester, find.text('Material didatico').last);
          expect(tester.takeException(), isNull);
          await _tapVisible(tester, find.text('Publicar'));
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(repository.publicationsForClass(schoolClass.id), hasLength(1));
          expect(
            repository.publicationsForClass(schoolClass.id).single.type,
            PublicationType.material,
          );
          expect(tester.takeException(), isNull);
          await _tapVisible(tester, find.text('Expandir'));
          final fullText = repository
              .publicationsForClass(schoolClass.id)
              .single
              .description;
          expect(find.text(fullText), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Fechar'));
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets(
    'new account joins by code and cannot publish in another creators class',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final repository = createTestRepository();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        AcademiaApp(
          repository: repository,
          firebaseStatus: FirebaseConnectionStatus.notConfigured(),
        ),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Criar conta'));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Maria Oliveira',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'maria@academya.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Maria123');
      await _tapVisible(tester, find.text('Cadastrar'));
      expect(repository.currentUser?.fullName, 'Maria Oliveira');
      expect(find.text('Nenhuma turma por enquanto'), findsOneWidget);
      await tester.tap(find.byTooltip('Adicionar turma'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'INVALIDO');
      await _tapVisible(tester, find.text('Participar'));
      expect(repository.visibleClasses, isEmpty);
      await tester.enterText(find.byType(TextFormField), 'cpad24');
      await _tapVisible(tester, find.text('Participar'));
      expect(repository.visibleClasses, hasLength(1));
      await _tapVisible(
        tester,
        find.text('Cross-Platform Application Development'),
      );
      expect(find.byTooltip('Nova publicacao'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'theme menu follows system and changes without losing navigation',
    (tester) async {
      final controller = ThemeController();
      final repository = createTestRepository();
      addTearDown(controller.dispose);
      addTearDown(repository.dispose);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        AcademiaApp(
          repository: repository,
          firebaseStatus: FirebaseConnectionStatus.notConfigured(),
          themeController: controller,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Entrar'))).brightness,
        Brightness.dark,
      );
      await _fillLogin(tester);
      await _tapVisible(tester, find.text('Entrar'));
      await tester.tap(find.byTooltip('Aparencia'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, 'Modo claro'),
      );
      await tester.pumpAndSettle();
      expect(controller.mode, ThemeMode.light);
      expect(
        Theme.of(tester.element(find.text('Minhas turmas'))).brightness,
        Brightness.light,
      );
      expect(repository.isAuthenticated, isTrue);
      await tester.tap(find.byTooltip('Aparencia'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, 'Modo escuro'),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Minhas turmas'))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byTooltip('Sair'));
      await tester.pumpAndSettle();
      expect(repository.isAuthenticated, isFalse);
      expect(find.text('Entrar'), findsOneWidget);
    },
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _showVisible(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _fillLogin(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'E-mail'),
    'aluno@academya.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Senha'),
    'Aluno123',
  );
}

Future<void> _showVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 180, scrollable: scrollable);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
