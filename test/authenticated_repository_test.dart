import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/core/firebase/firebase_sync_service.dart';
import 'package:flutter_application_1/data/models/app_user.dart';
import 'package:flutter_application_1/data/models/publication.dart';
import 'package:flutter_application_1/data/models/school_class.dart';
import 'package:flutter_application_1/data/repositories/academya_repository.dart';
import 'package:flutter_application_1/data/services/authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_repository.dart';

class TestDatabase extends FirebaseSyncService {
  AppUser? savedUser;
  final classes = <SchoolClass>[];
  final posts = <Publication>[];
  Completer<FirebaseSnapshot>? pendingSnapshot;
  Object? readFailure;
  Object? writeFailure;

  @override
  Future<void> saveUserProfile(AppUser user) async => savedUser = user;

  @override
  Future<FirebaseSnapshot> fetchSnapshot(String userId) async {
    if (readFailure != null) throw readFailure!;
    if (pendingSnapshot != null) return pendingSnapshot!.future;
    return FirebaseSnapshot(
      classes: classes
          .where((item) => item.memberIds.contains(userId))
          .toList(),
      publications: List.of(posts),
    );
  }

  @override
  Future<void> saveClass(SchoolClass schoolClass) async {
    if (writeFailure != null) throw writeFailure!;
    classes.add(schoolClass);
  }

  @override
  Future<void> savePublication(Publication publication) async {
    if (writeFailure != null) throw writeFailure!;
    posts.add(publication);
  }
}

const restoredUser = AppUser(
  id: 'real-uid',
  fullName: 'Maria Silva',
  email: 'maria@example.com',
);

Future<void> finishBackgroundWork() => Future<void>.delayed(Duration.zero);

void main() {
  test('restores real session and persists profile by UID', () async {
    final auth = MemoryAuthenticationService(currentUser: restoredUser);
    final database = TestDatabase();
    final repository = AcademyaRepository(
      authenticationService: auth,
      firebaseSyncService: database,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);
    await repository.initializeSession();
    await finishBackgroundWork();
    expect(repository.currentUser?.id, 'real-uid');
    expect(database.savedUser?.email, 'maria@example.com');
    expect(repository.visibleClasses, isEmpty);
    expect(repository.dataError, isNull);
  });

  test('failed login never creates a local authenticated session', () async {
    final auth = MemoryAuthenticationService();
    final repository = AcademyaRepository(authenticationService: auth);
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);
    await expectLater(
      repository.signIn(email: 'aluno@academya.com', password: 'wrong'),
      throwsA(isA<AuthenticationFailure>()),
    );
    expect(repository.isAuthenticated, isFalse);
  });

  test('database error keeps account signed in and supports retry', () async {
    final auth = MemoryAuthenticationService(currentUser: restoredUser);
    final database = TestDatabase()
      ..readFailure = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final repository = AcademyaRepository(
      authenticationService: auth,
      firebaseSyncService: database,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);
    await repository.initializeSession();
    await finishBackgroundWork();
    expect(repository.isAuthenticated, isTrue);
    expect(repository.dataError, contains('regras'));
    database.readFailure = null;
    await repository.refreshUserData();
    expect(repository.dataError, isNull);
  });

  test('late data load cannot restore records after logout', () async {
    final auth = MemoryAuthenticationService(currentUser: restoredUser);
    final database = TestDatabase()
      ..pendingSnapshot = Completer<FirebaseSnapshot>();
    final repository = AcademyaRepository(
      authenticationService: auth,
      firebaseSyncService: database,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);
    await repository.initializeSession();
    await repository.signOut();
    database.pendingSnapshot!.complete(
      const FirebaseSnapshot(classes: [], publications: []),
    );
    await finishBackgroundWork();
    expect(repository.isAuthenticated, isFalse);
    expect(repository.isLoadingData, isFalse);
    expect(repository.visibleClasses, isEmpty);
  });

  test('account switch clears previous user classes', () async {
    final auth = MemoryAuthenticationService(currentUser: restoredUser);
    final database = TestDatabase();
    final repository = AcademyaRepository(
      authenticationService: auth,
      firebaseSyncService: database,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);
    await repository.initializeSession();
    await finishBackgroundWork();
    final schoolClass = await repository.createClass(
      name: 'Turma Maria',
      type: SchoolClassType.classroom,
    );
    expect(schoolClass.creatorId, 'real-uid');
    await repository.signOut();
    await repository.signIn(email: 'aluno@academya.com', password: 'Aluno123');
    await finishBackgroundWork();
    expect(repository.currentUser?.id, 'user-student');
    expect(repository.visibleClasses, isEmpty);
    expect(repository.findClassById(schoolClass.id), isNull);
  });

  test('failed write does not show a locally created class', () async {
    final auth = MemoryAuthenticationService(currentUser: restoredUser);
    final database = TestDatabase()..writeFailure = StateError('offline');
    final repository = AcademyaRepository(
      authenticationService: auth,
      firebaseSyncService: database,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);
    await repository.initializeSession();
    await finishBackgroundWork();
    await expectLater(
      repository.createClass(
        name: 'Turma teste',
        type: SchoolClassType.classroom,
      ),
      throwsStateError,
    );
    expect(repository.visibleClasses, isEmpty);
  });

  test('creation saves only the new class or publication', () async {
    final auth = MemoryAuthenticationService(currentUser: restoredUser);
    final database = TestDatabase();
    final repository = AcademyaRepository(
      authenticationService: auth,
      firebaseSyncService: database,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);
    await repository.initializeSession();
    await finishBackgroundWork();
    final schoolClass = await repository.createClass(
      name: 'Turma teste',
      type: SchoolClassType.studyGroup,
    );
    await repository.addPublication(
      classId: schoolClass.id,
      title: 'Aviso',
      description: 'Conteudo',
      type: PublicationType.notice,
    );
    expect(database.classes, hasLength(1));
    expect(database.posts, hasLength(1));
    expect(database.posts.single.classId, schoolClass.id);
  });

  test('repository rejects publishing as non creator', () async {
    final repository = createTestRepository();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'aluno@academya.com', password: 'Aluno123');
    await expectLater(
      repository.addPublication(
        classId: 'class-flutter',
        title: 'Aviso',
        description: 'Conteudo',
        type: PublicationType.notice,
      ),
      throwsStateError,
    );
  });
}
