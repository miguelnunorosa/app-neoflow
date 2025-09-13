import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_account.dart';

class UserRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream do utilizador logado (usersAccounts/{uid}).
  Stream<UserAccount?> currentUserStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Sem sessão -> stream vazia
      return const Stream<UserAccount?>.empty();
    }
    return _db.collection('usersAccounts').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserAccount.fromFirestore(doc);
    });
  }

  /// Lê um utilizador concreto (one-shot).
  Future<UserAccount?> getUser(String uid) async {
    final doc = await _db.collection('usersAccounts').doc(uid).get();
    if (!doc.exists) return null;
    return UserAccount.fromFirestore(doc);
  }

  /// Verifica se o utilizador é admin.
  ///
  /// Modelo esperado em usersAccounts/{uid}:
  ///   userProfile: <DocumentReference to /userProfiles/profileAdmin or profileUser>
  ///
  /// Em userProfiles/{profileId}:
  ///   role: "admin" | "utilizador"   (recomendado)
  ///   (ou, alternativamente, usar o próprio ID "profileAdmin")
  Future<bool> isAdmin(String uid) async {
    final userDoc = await _db.collection('usersAccounts').doc(uid).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>?;
    final dynamic ref = data?['userProfile'];

    if (ref is! DocumentReference) {
      return false;
    }

    // Opção A (recomendada): campo "role" no doc do perfil
    final profileSnap = await ref.get();
    if (!profileSnap.exists) return false;
    final profileData = profileSnap.data() as Map<String, dynamic>?;

    final role = (profileData?['role'] ?? '').toString().toLowerCase();
    if (role == 'admin') return true;

    // Opção B (fallback): pelo ID do documento (ex.: "profileAdmin")
    final profileId = (profileSnap.id).toString().toLowerCase();
    if (profileId == 'profileadmin') return true;

    // Opção C (fallback): pelo path completo (caso o ref seja resolvido de outra forma)
    final path = ref.path.toLowerCase(); // ex.: "userprofiles/profileadmin"
    if (path.endsWith('userprofiles/profileadmin')) return true;

    return false;
  }
}
