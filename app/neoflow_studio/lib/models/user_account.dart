import 'package:cloud_firestore/cloud_firestore.dart';

class UserAccount {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isActive;
  final DocumentReference? userProfile;

  /// Campos novos
  final String? firstName;
  final String? lastName;

  UserAccount({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isActive = true,
    this.userProfile,
    this.firstName,
    this.lastName,
  });

  factory UserAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserAccount(
      id: doc.id,
      displayName: (data['displayName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      photoUrl: data['photoUrl'] as String?,
      isActive: (data['isActive'] ?? true) as bool,
      userProfile: data['userProfile'] as DocumentReference?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'userProfile': userProfile,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };
  }
}
