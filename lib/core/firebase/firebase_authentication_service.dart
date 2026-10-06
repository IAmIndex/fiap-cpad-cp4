import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/app_user.dart';
import '../../data/services/authentication_service.dart';

class FirebaseAuthenticationService implements AuthenticationService {
  FirebaseAuthenticationService({required this.auth, this.unavailableReason});

  final FirebaseAuth? auth;
  final String? unavailableReason;

  FirebaseAuth get _availableAuth =>
      auth ??
      (throw AuthenticationFailure(
        unavailableReason ??
            'Firebase indisponível. Confira a configuração e reinicie o app.',
      ));

  @override
  Stream<AppUser?> get userChanges =>
      auth?.userChanges().map(_toAppUser) ?? Stream.value(null);

  static AppUser? _toAppUser(User? user) {
    if (user == null || user.isAnonymous) return null;
    return AppUser(
      id: user.uid,
      fullName: user.displayName ?? user.email?.split('@').first ?? 'Usuário',
      email: user.email ?? '',
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _availableAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return _toAppUser(credential.user)!;
    } on FirebaseAuthException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    UserCredential credential;
    try {
      credential = await _availableAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw _failure(error);
    }
    final user = credential.user!;
    try {
      await user.updateDisplayName(fullName.trim());
    } on FirebaseAuthException {
      await _availableAuth.signOut();
      throw const AuthenticationFailure(
        'Sua conta foi criada, mas o nome não foi salvo. Entre com o e-mail e a senha cadastrados.',
      );
    }
    return AppUser(
      id: user.uid,
      fullName: fullName.trim(),
      email: user.email ?? email.trim().toLowerCase(),
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _availableAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _availableAuth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
    } on FirebaseAuthException catch (error) {
      // Keep the response neutral even when email enumeration protection is off.
      if (error.code != 'user-not-found') throw _failure(error);
    }
  }

  static AuthenticationFailure _failure(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'E-mail ou senha invalidos.',
      'email-already-in-use' => 'Este e-mail já está cadastrado.',
      'invalid-email' => 'Informe um e-mail valido.',
      'weak-password' => 'A senha não atende aos requisitos do Firebase.',
      'operation-not-allowed' =>
        'Habilite E-mail/senha em Authentication no Console Firebase.',
      'network-request-failed' =>
        'Sem conexao. Confira sua internet e tente novamente.',
      'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
      'user-disabled' => 'Esta conta foi desativada.',
      _ => 'Não foi possível autenticar. Tente novamente.',
    };
    return AuthenticationFailure(message);
  }
}
