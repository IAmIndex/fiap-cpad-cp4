import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase/firebase_sync_service.dart';
import '../models/app_user.dart';
import '../models/publication.dart';
import '../models/school_class.dart';
import '../services/authentication_service.dart';

class AcademyaRepository extends ChangeNotifier {
  AcademyaRepository({
    required this.authenticationService,
    this.firebaseSyncService,
    List<SchoolClass> initialClasses = const [],
    List<Publication> initialPublications = const [],
  }) : _classes = List.of(initialClasses),
       _publications = List.of(initialPublications);

  final AuthenticationService authenticationService;
  final FirebaseSyncService? firebaseSyncService;
  final List<SchoolClass> _classes;
  final List<Publication> _publications;
  StreamSubscription<AppUser?>? _authSubscription;
  AppUser? _currentUser;
  bool _authenticating = false;
  bool _disposed = false;
  int _sessionVersion = 0;
  bool isLoadingData = false;
  String? dataError;

  bool get isAuthenticated => _currentUser != null;
  AppUser? get currentUser => _currentUser;

  List<SchoolClass> get visibleClasses => _classes
      .where((schoolClass) => schoolClass.memberIds.contains(_currentUser?.id))
      .toList();

  SchoolClass? findClassById(String classId) {
    for (final schoolClass in visibleClasses) {
      if (schoolClass.id == classId) return schoolClass;
    }
    return null;
  }

  List<Publication> publicationsForClass(String classId) {
    if (findClassById(classId) == null) return const [];
    return _publications.where((post) => post.classId == classId).toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
  }

  Future<void> initializeSession() async {
    _applyUser(await authenticationService.userChanges.first);
    _authSubscription = authenticationService.userChanges.listen((user) {
      if (!_authenticating) _applyUser(user);
    });
  }

  void _applyUser(AppUser? user) {
    if (_disposed) return;
    final changed = _currentUser?.id != user?.id;
    _currentUser = user;
    if (changed) {
      _sessionVersion++;
      dataError = null;
      isLoadingData = false;
      if (firebaseSyncService != null) {
        _classes.clear();
        _publications.clear();
      }
    }
    notifyListeners();
    if (changed && user != null) unawaited(refreshUserData());
  }

  Future<void> refreshUserData() async {
    final user = _currentUser;
    final service = firebaseSyncService;
    if (user == null || service == null || isLoadingData) return;
    final version = _sessionVersion;
    isLoadingData = true;
    dataError = null;
    notifyListeners();
    try {
      await service.saveUserProfile(user);
      final snapshot = await service.fetchSnapshot(user.id);
      if (_disposed || version != _sessionVersion) return;
      _classes
        ..clear()
        ..addAll(snapshot.classes);
      _publications
        ..clear()
        ..addAll(snapshot.publications);
    } catch (error) {
      if (_disposed || version != _sessionVersion) return;
      dataError = describeDataError(error);
    } finally {
      if (!_disposed && version == _sessionVersion) {
        isLoadingData = false;
        notifyListeners();
      }
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _authenticating = true;
    try {
      _applyUser(
        await authenticationService.signIn(email: email, password: password),
      );
    } finally {
      _authenticating = false;
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _authenticating = true;
    try {
      _applyUser(
        await authenticationService.signUp(
          fullName: fullName,
          email: email,
          password: password,
        ),
      );
    } finally {
      _authenticating = false;
    }
  }

  Future<void> signOut() async {
    await authenticationService.signOut();
    _applyUser(null);
  }

  Future<void> sendPasswordReset(String email) =>
      authenticationService.sendPasswordReset(email);

  Future<bool> joinClassByCode(String code) async {
    final user = _requireUser();
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) return false;
    final service = firebaseSyncService;
    SchoolClass? schoolClass;
    if (service != null) {
      schoolClass = await service.joinClass(normalizedCode, user.id);
    } else {
      for (final candidate in _classes) {
        if (candidate.joinCode == normalizedCode) schoolClass = candidate;
      }
    }
    if (schoolClass == null) return false;
    final joinedClass = schoolClass.copyWith(
      memberIds: {...schoolClass.memberIds, user.id}.toList(),
    );
    final posts =
        await service?.fetchPublications(joinedClass.id) ?? <Publication>[];
    _checkSession(user.id);
    _classes.removeWhere((item) => item.id == joinedClass.id);
    _classes.add(joinedClass);
    if (service != null) {
      _publications.removeWhere((item) => item.classId == joinedClass.id);
      _publications.addAll(posts);
    }
    notifyListeners();
    return true;
  }

  Future<SchoolClass> createClass({
    required String name,
    required SchoolClassType type,
  }) async {
    final user = _requireUser();
    final schoolClass = SchoolClass(
      id: _createId('class'),
      name: name.trim(),
      creatorId: user.id,
      creatorName: user.fullName,
      joinCode: _createJoinCode(),
      type: type,
      memberIds: [user.id],
    );
    await firebaseSyncService?.saveClass(schoolClass);
    _checkSession(user.id);
    _classes.add(schoolClass);
    notifyListeners();
    return schoolClass;
  }

  Future<Publication> addPublication({
    required String classId,
    required String title,
    required String description,
    required PublicationType type,
  }) async {
    final user = _requireUser();
    if (findClassById(classId)?.isCreatedBy(user.id) != true) {
      throw StateError('Somente o criador da turma pode publicar.');
    }
    final publication = Publication(
      id: _createId('post'),
      classId: classId,
      title: title.trim(),
      description: description.trim(),
      type: type,
      authorName: user.fullName,
      createdAt: DateTime.now(),
    );
    await firebaseSyncService?.savePublication(publication);
    _checkSession(user.id);
    _publications.add(publication);
    notifyListeners();
    return publication;
  }

  AppUser _requireUser() =>
      _currentUser ??
      (throw StateError('Usuário autenticado necessário para essa acao.'));

  void _checkSession(String userId) {
    if (_disposed || _currentUser?.id != userId) {
      throw StateError('Sessão encerrada. Entre novamente.');
    }
  }

  static String describeDataError(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Sem permissão no Firestore. Confira as regras do projeto.';
    }
    if (error is TimeoutException) {
      return 'O Firebase não confirmou a operacao a tempo. Confira a conexao e atualize a lista antes de tentar novamente.';
    }
    return 'Não foi possível acessar os dados. Confira sua conexao e tente novamente.';
  }

  String _createId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(99999)}';

  String _createJoinCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => letters[random.nextInt(letters.length)],
    ).join();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
