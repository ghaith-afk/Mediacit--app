import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/models/user_model.dart';


class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  /// LOGIN
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// REGISTER
  Future<void> register(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;

    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      role: UserRole.user,
      suspended: false,
      createdAt: Timestamp.now(),
    );

    await _firestore.collection("users").doc(user.uid).set(appUser.toMap());
  }

  /// LOGOUT
  Future<void> logout() async {
    return _auth.signOut();
  }


}
