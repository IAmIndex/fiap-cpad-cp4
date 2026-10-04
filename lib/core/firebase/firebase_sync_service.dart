import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../data/models/app_user.dart';
import '../../data/models/publication.dart';
import '../../data/models/school_class.dart';
import 'firebase_options.dart';

class FirebaseSnapshot {
  const FirebaseSnapshot({required this.classes, required this.publications});

  final List<SchoolClass> classes;
  final List<Publication> publications;
}

class FirebaseConnectionStatus {
  const FirebaseConnectionStatus._({
    required this.isConnected,
    required this.message,
  });

  final bool isConnected;
  final String message;

  factory FirebaseConnectionStatus.connected() {
    return const FirebaseConnectionStatus._(
      isConnected: true,
      message: 'Firebase inicializado',
    );
  }

  factory FirebaseConnectionStatus.notConfigured() {
    return const FirebaseConnectionStatus._(
      isConnected: false,
      message: 'Firebase aguardando configuracao',
    );
  }

  factory FirebaseConnectionStatus.failed(Object error) {
    return FirebaseConnectionStatus._(
      isConnected: false,
      message: 'Firebase indisponivel: $error',
    );
  }
}

class FirebaseSyncService {
  FirebaseFirestore? _firestore;
  static const _timeout = Duration(seconds: 15);

  FirebaseFirestore get _database =>
      _firestore ?? (throw StateError('Firebase nao inicializado.'));

  Future<FirebaseConnectionStatus> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return FirebaseConnectionStatus.notConfigured();
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;
      return FirebaseConnectionStatus.connected();
    } catch (error) {
      return FirebaseConnectionStatus.failed(error);
    }
  }

  Future<void> saveUserProfile(AppUser user) {
    return _database
        .collection('users')
        .doc(user.id)
        .set({
          'fullName': user.fullName,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(_timeout);
  }

  Future<FirebaseSnapshot> fetchSnapshot(String userId) async {
    final snapshot = await _database
        .collection('classes')
        .where('memberIds', arrayContains: userId)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final classes = snapshot.docs
        .map(
          (document) =>
              SchoolClass.fromJson({...document.data(), 'id': document.id}),
        )
        .toList();
    final publications = <Publication>[];
    for (final schoolClass in classes) {
      publications.addAll(await fetchPublications(schoolClass.id));
    }
    return FirebaseSnapshot(classes: classes, publications: publications);
  }

  Future<List<Publication>> fetchPublications(String classId) async {
    final snapshot = await _database
        .collection('classes')
        .doc(classId)
        .collection('publications')
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    return snapshot.docs
        .map(
          (document) => Publication.fromJson({
            ...document.data(),
            'id': document.id,
            'classId': classId,
          }),
        )
        .toList();
  }

  Future<SchoolClass?> joinClass(String code, String userId) async {
    final snapshot = await _database
        .collection('classes')
        .where('joinCode', isEqualTo: code)
        .limit(1)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    if (snapshot.docs.isEmpty) return null;
    final document = snapshot.docs.single;
    final schoolClass = SchoolClass.fromJson({
      ...document.data(),
      'id': document.id,
    });
    await document.reference
        .update({
          'memberIds': FieldValue.arrayUnion([userId]),
        })
        .timeout(_timeout);
    return schoolClass.copyWith(
      memberIds: {...schoolClass.memberIds, userId}.toList(),
    );
  }

  Future<void> saveClass(SchoolClass schoolClass) {
    return _database
        .collection('classes')
        .doc(schoolClass.id)
        .set(schoolClass.toJson())
        .timeout(_timeout);
  }

  Future<void> savePublication(Publication publication) {
    return _database
        .collection('classes')
        .doc(publication.classId)
        .collection('publications')
        .doc(publication.id)
        .set(publication.toJson())
        .timeout(_timeout);
  }
}
