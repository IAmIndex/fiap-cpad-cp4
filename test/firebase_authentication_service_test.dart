import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/firebase/firebase_authentication_service.dart';
import 'package:flutter_application_1/data/services/authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUser extends Fake implements User {
  @override
  String get uid => 'firebase-uid';
  @override
  String? get email => 'maria@example.com';
  @override
  String? displayName = 'Maria Oliveira';
  @override
  bool isAnonymous = false;
  bool failNameUpdate = false;

  @override
  Future<void> updateDisplayName(String? name) async {
    if (failNameUpdate) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
    displayName = name;
  }
}

class TestCredential extends Fake implements UserCredential {
  TestCredential(this.user);
  @override
  final User user;
}

class TestAuth extends Fake implements FirebaseAuth {
  final user = TestUser();
  String? sentEmail;
  String? sentPassword;
  String? failureCode;
  bool signedOut = false;

  void checkFailure() {
    if (failureCode != null) throw FirebaseAuthException(code: failureCode!);
  }

  @override
  Stream<User?> userChanges() => Stream.value(user);

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    sentEmail = email;
    sentPassword = password;
    checkFailure();
    return TestCredential(user);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) => signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    sentEmail = email;
    checkFailure();
  }
}

void main() {
  test(
    'login uses Firebase UID, normalizes email and preserves password',
    () async {
      final auth = TestAuth();
      final service = FirebaseAuthenticationService(auth: auth);
      final user = await service.signIn(
        email: ' MARIA@EXAMPLE.COM ',
        password: ' Senha123 ',
      );
      expect(auth.sentEmail, 'maria@example.com');
      expect(auth.sentPassword, ' Senha123 ');
      expect(user.id, 'firebase-uid');
      expect(user.fullName, 'Maria Oliveira');
    },
  );

  test(
    'signup creates account and saves display name in Firebase Auth',
    () async {
      final auth = TestAuth();
      final user = await FirebaseAuthenticationService(auth: auth).signUp(
        fullName: ' Maria Silva ',
        email: 'maria@example.com',
        password: 'Senha123',
      );
      expect(auth.user.displayName, 'Maria Silva');
      expect(user.fullName, 'Maria Silva');
      expect(user.id, 'firebase-uid');
    },
  );

  test('legacy anonymous session is not an app login', () async {
    final auth = TestAuth()..user.isAnonymous = true;
    expect(
      await FirebaseAuthenticationService(auth: auth).userChanges.first,
      isNull,
    );
  });

  test('real session is restored from userChanges', () async {
    final auth = TestAuth();
    final user = await FirebaseAuthenticationService(auth: auth)
        .userChanges
        .first;
    expect(user?.id, 'firebase-uid');
    expect(user?.email, 'maria@example.com');
  });

  final failures = {
    'invalid-credential': 'E-mail ou senha invalidos.',
    'wrong-password': 'E-mail ou senha invalidos.',
    'user-not-found': 'E-mail ou senha invalidos.',
    'email-already-in-use': 'Este e-mail ja esta cadastrado.',
    'operation-not-allowed':
        'Habilite E-mail/senha em Authentication no Console Firebase.',
    'network-request-failed':
        'Sem conexao. Confira sua internet e tente novamente.',
    'too-many-requests': 'Muitas tentativas. Aguarde e tente novamente.',
    'weak-password': 'A senha nao atende aos requisitos do Firebase.',
  };
  for (final failure in failures.entries) {
    test('Firebase error ${failure.key} becomes a readable message', () async {
      final auth = TestAuth()..failureCode = failure.key;
      await expectLater(
        FirebaseAuthenticationService(auth: auth)
            .signIn(email: 'a@example.com', password: 'Senha123'),
        throwsA(
          isA<AuthenticationFailure>().having(
            (error) => error.message,
            'message',
            failure.value,
          ),
        ),
      );
    });
  }

  test('missing Firebase does not fall back to mock authentication', () async {
    final service = FirebaseAuthenticationService(auth: null);
    expect(await service.userChanges.first, isNull);
    await expectLater(
      service.signIn(email: 'aluno@academya.com', password: 'Aluno123'),
      throwsA(isA<AuthenticationFailure>()),
    );
  });

  test(
    'password reset delegates to Firebase without exposing account existence',
    () async {
      final auth = TestAuth()..failureCode = 'user-not-found';
      await FirebaseAuthenticationService(auth: auth)
          .sendPasswordReset(' MARIA@EXAMPLE.COM ');
      expect(auth.sentEmail, 'maria@example.com');
    },
  );

  test('sign out calls Firebase', () async {
    final auth = TestAuth();
    await FirebaseAuthenticationService(auth: auth).signOut();
    expect(auth.signedOut, isTrue);
  });

  test(
    'partial signup explicitly reports account creation and signs out',
    () async {
      final auth = TestAuth()..user.failNameUpdate = true;
      await expectLater(
        FirebaseAuthenticationService(auth: auth).signUp(
          fullName: 'Maria Silva',
          email: 'maria@example.com',
          password: 'Senha123',
        ),
        throwsA(
          isA<AuthenticationFailure>().having(
            (error) => error.message,
            'message',
            contains('Sua conta foi criada'),
          ),
        ),
      );
      expect(auth.signedOut, isTrue);
    },
  );
}
