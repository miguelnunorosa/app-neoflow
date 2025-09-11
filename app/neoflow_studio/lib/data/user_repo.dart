import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';

class UserRepo {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<UserAccount?> currentUserStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      final ref = _db.collection('usersAccounts').doc(user.uid)
          .withConverter<UserAccount>(
        fromFirestore: (snap, _) => UserAccount.fromDoc(snap),
        toFirestore: (ua, _) => {}, // não usamos write aqui
      );
      return ref.snapshots().map((snap) => snap.data());
    });
  }
}
