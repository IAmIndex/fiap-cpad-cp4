import 'dart:async';

import 'package:flutter_application_1/data/models/app_user.dart';
import 'package:flutter_application_1/data/models/school_class.dart';
import 'package:flutter_application_1/data/repositories/academya_repository.dart';
import 'package:flutter_application_1/data/services/authentication_service.dart';

class MemoryAuthenticationService implements AuthenticationService {
  MemoryAuthenticationService({this.currentUser});

  AppUser? currentUser;
  final changes = StreamController<AppUser?>.broadcast(sync: true);
  final accounts = <String, ({AppUser user, String password})>{
    'aluno@academya.com': (
      user: const AppUser(
        id: 'user-student',
        fullName: 'Gustavo Hackime',
        email: 'aluno@academya.com',
      ),
      password: 'Aluno123',
    ),
  };
  Completer<AppUser>? pendingSignIn;
  int signInCalls = 0;
  String? resetEmail;

  @override
  Stream<AppUser?> get userChanges async* {
    yield currentUser;
    yield* changes.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    final AppUser user;
    if (pendingSignIn != null) {
      user = await pendingSignIn!.future;
    } else {
      final account = accounts[email.trim().toLowerCase()];
      if (account == null || account.password != password) {
        throw const AuthenticationFailure('E-mail ou senha invalidos.');
      }
      user = account.user;
    }
    currentUser = user;
    changes.add(user);
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (accounts.containsKey(normalized)) {
      throw const AuthenticationFailure('Este e-mail já está cadastrado.');
    }
    final user = AppUser(
      id: 'new-${accounts.length}',
      fullName: fullName.trim(),
      email: normalized,
    );
    accounts[normalized] = (user: user, password: password);
    currentUser = user;
    changes.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    changes.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetEmail = email;

  Future<void> dispose() => changes.close();
}

AcademyaRepository createTestRepository({MemoryAuthenticationService? auth}) {
  return AcademyaRepository(
    authenticationService: auth ?? MemoryAuthenticationService(),
    initialClasses: const [
      SchoolClass(
        id: 'class-flutter',
        name: 'Cross-Platform Application Development',
        creatorId: 'user-teacher',
        creatorName: 'Prof. Mariana Costa',
        joinCode: 'CPAD24',
        type: SchoolClassType.classroom,
        memberIds: ['user-student', 'user-teacher'],
      ),
      SchoolClass(
        id: 'class-startup',
        name: 'Grupo de estudos: Startup One',
        creatorId: 'user-student',
        creatorName: 'Gustavo Hackime',
        joinCode: 'START1',
        type: SchoolClassType.studyGroup,
        memberIds: ['user-student'],
      ),
    ],
  );
}
