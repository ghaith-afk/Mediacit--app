import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/models/theme_enum.dart';
import 'package:mediatech/models/user_model.dart' ;
import 'package:mediatech/services/auth_service.dart';

// AuthService provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    FirebaseFirestore.instance,
  );
});

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Auth state stream provider (listens to login/logout)
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// AppUser provider (loads Firestore user document)
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final doc = await docRef.get();

  if (!doc.exists) {
    // Only create default user if NOT admin
    if (user.email != "admin@myapp.com") {
      final newUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        role: UserRole.user,
        suspended: false,
        createdAt: Timestamp.now(),
        theme: UserTheme.light,
      );
      await docRef.set(newUser.toMap());
      return newUser;
    } else {
      // Admin exists in Auth but not Firestore -> create default admin doc
      final newAdminUser = AppUser(
        uid: user.uid,
        email: user.email ?? 'admin@myapp.com',
        displayName: user.displayName ?? 'Super Admin',
        role: UserRole.admin,
        suspended: false,
        createdAt: Timestamp.now(),
        theme: UserTheme.light,
      );
      await docRef.set(newAdminUser.toMap());
      return newAdminUser;
    }
  }

  // Return normal AppUser
  final data = doc.data()!;
  return AppUser.fromMap(doc.id, data);
}

)
;
