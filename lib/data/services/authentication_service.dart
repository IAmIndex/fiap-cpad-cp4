import '../models/app_user.dart';

abstract class AuthenticationService {
  Stream<AppUser?> get userChanges;

  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
}

class AuthenticationFailure implements Exception {
  const AuthenticationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
