import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/models/theme_enum.dart';



class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final bool suspended;
  final Timestamp createdAt;
  final UserTheme theme; // NEW

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.suspended,
    required this.createdAt,
    this.theme = UserTheme.light, // default light
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    final roleString = (data['role'] ?? 'user').toString().toLowerCase();
    final role = UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == roleString,
      orElse: () => UserRole.user,
    );

    // NEW: parse theme
    final themeString = (data['theme'] ?? 'light').toString().toLowerCase();
    final theme = UserTheme.values.firstWhere(
      (t) => t.name.toLowerCase() == themeString,
      orElse: () => UserTheme.light,
    );

    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: role,
      suspended: data['suspended'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      theme: theme,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'suspended': suspended,
      'createdAt': createdAt,
      'theme': theme.name, // NEW
    };
  }
  
}
extension AppUserCopy on AppUser {
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    bool? suspended,
    Timestamp? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      suspended: suspended ?? this.suspended,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
