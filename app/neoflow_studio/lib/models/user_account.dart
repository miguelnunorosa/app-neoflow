import 'package:cloud_firestore/cloud_firestore.dart';

class UserAccount {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? photoUrl;
  final bool isActive;

  String get displayName =>
      [firstName, lastName].where((s) => s.trim().isNotEmpty).join(' ').trim();

  UserAccount({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    this.photoUrl,
  });

  factory UserAccount.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return UserAccount(
      uid: doc.id,
      firstName: (d['firstName'] ?? '') as String,
      lastName: (d['lastName'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      isActive: (d['isActive'] ?? false) as bool,
      photoUrl: d['photo'] as String?,
    );
  }
}
