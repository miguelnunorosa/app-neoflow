import 'package:cloud_firestore/cloud_firestore.dart';

class UserAccount {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isActive;
  final DocumentReference? userProfile; // referência ao perfil

  UserAccount({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.isActive,
    this.userProfile,
  });

  factory UserAccount.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserAccount(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
      userProfile: data['userProfile'],
    );
  }
}
