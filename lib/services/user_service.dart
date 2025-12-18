import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediatech/models/user_model.dart';
import 'package:mediatech/models/role.dart';

class Userservice {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('users');

  /// Get all users
  Future<List<AppUser>> loadUsers() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
return snap.docs
    .map((d) {
      final data = d.data();
      if (data is! Map<String, dynamic>) {
        throw Exception("Invalid Firestore user document format");
      }
      return AppUser.fromMap(d.id, data);
    })
    .toList();

  }

  /// Add user with secondary auth
  Future<AppUser> addUser(AppUser user, String password) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    final newUser = user.copyWith(uid: cred.user!.uid);
    await _col.doc(newUser.uid).set(newUser.toMap());

    await secondaryAuth.signOut();
    await secondaryApp.delete();

    return newUser;
  }

  /// Update Firestore user document
  Future<void> updateFirestoreUser(AppUser user) async {
    await _col.doc(user.uid).update(user.toMap());
  }

  /// Update email/password for the SAME USER
  Future<void> updateOwnCredentials(
    AppUser user, {
    String? newPassword,
    String? currentPassword,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != user.uid) return;

    if (currentPassword != null && currentPassword.isNotEmpty) {
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);
    }

    if (user.email != currentUser.email) {
      await currentUser.verifyBeforeUpdateEmail(user.email);
    }

    if (newPassword != null && newPassword.isNotEmpty) {
      await currentUser.updatePassword(newPassword);
    }
  }

  /// For OTHER users → send reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Delete own account (Firestore + Auth)
  Future<void> deleteOwnAccount(String uid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      throw Exception("Cannot delete other users");
    }

    await _col.doc(uid).delete();
    await currentUser.delete();
  }

  /// Toggle suspend
  Future<void> toggleSuspend(String uid, bool suspended) async {
    await _col.doc(uid).update({"suspended": suspended});
  }

  /// Set role
  Future<void> setRole(String uid, UserRole role) async {
    await _col.doc(uid).update({"role": role.name});
  }




  // User Functions Here :))
   Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return AppUser.fromMap(doc.id, data);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  /// Get multiple users by their IDs (for batch operations)
  Future<List<AppUser>> getUsersByIds(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];
      
      // Firestore allows up to 10 documents per query in 'in' clauses
      final chunks = _chunkList(uids, 10);
      final allUsers = <AppUser>[];
      
      for (final chunk in chunks) {
        final snapshot = await _col.where(FieldPath.documentId, whereIn: chunk).get();
        final users = snapshot.docs.map((doc) {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            return AppUser.fromMap(doc.id, data);
          }
          throw Exception("Invalid user data format");
        }).toList();
        allUsers.addAll(users);
      }
      
      return allUsers;
    } catch (e) {
      print('Error fetching users by IDs: $e');
      return [];
    }
  }

  // Helper method to chunk list for Firestore queries
  List<List<String>> _chunkList(List<String> list, int chunkSize) {
    final chunks = <List<String>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
  
}
