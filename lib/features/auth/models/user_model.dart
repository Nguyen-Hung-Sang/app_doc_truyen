import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String gender;
  final String email;
  final String role; // 'admin', 'user', 'Vip'
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.gender,
    required this.email,
    this.role = 'user',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'gender': gender,
      'email': email,
      'role': role,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      gender: map['gender'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
