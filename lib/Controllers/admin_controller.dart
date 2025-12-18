import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mediatech/models/user_model.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/services/user_service.dart';

final adminServiceProvider = Provider((ref) => Userservice());

final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminState>((ref) {
  return AdminController(ref.read(adminServiceProvider));
});

class AdminState {
  final bool loading;
  final String? error;
  final String? success;
  final List<AppUser> users;

  AdminState({
    this.loading = false,
    this.error,
    this.success,
    this.users = const [],
  });

  AdminState copyWith({
    bool? loading,
    String? error,
    String? success,
    List<AppUser>? users,
  }) {
    return AdminState(
      loading: loading ?? this.loading,
      error: error,
      success: success,
      users: users ?? this.users,
    );
  }
}

class AdminController extends StateNotifier<AdminState> {
  final Userservice service;

  AdminController(this.service) : super(AdminState()) {
    loadUsers();
  }

  void clearMessages() {
    state = state.copyWith(error: null, success: null);
  }

  Future<void> loadUsers() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final users = await service.loadUsers();
      state = state.copyWith(users: users, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  Future<void> addUser(AppUser user, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await service.addUser(user, password);
      await loadUsers();
      state = state.copyWith(success: "User created");
    } catch (e) {
      state = state.copyWith(error: "Failed to create user", loading: false);
    }
  }

  Future<bool> updateUser(
    AppUser user, {
    String? newPassword,
    String? currentPassword,
  }) async {
    state = state.copyWith(error: null);
    try {
      // Update auth or send reset
      if (currentPassword != null || newPassword != null) {
        await service.updateOwnCredentials(
          user,
          newPassword: newPassword,
          currentPassword: currentPassword,
        );
      } else if (newPassword != null) {
        await service.sendPasswordReset(user.email);
      }

      await service.updateFirestoreUser(user);
      await loadUsers();
      state = state.copyWith(success: "User updated");
      return true;
    } catch (e) {
      state = state.copyWith(error: "Update failed");
      return false;
    }
  }

  Future<void> deleteUser(String uid) async {
    state = state.copyWith(error: null);
    try {
      await service.deleteOwnAccount(uid);
      await loadUsers();
      state = state.copyWith(success: "Account deleted");
    } catch (_) {
      state = state.copyWith(error: "Deletion failed");
    }
  }

  Future<void> toggleSuspend(String uid, bool suspended) async {
    try {
      await service.toggleSuspend(uid, suspended);
      await loadUsers();
      state = state.copyWith(
          success: suspended ? "User suspended" : "User activated");
    } catch (_) {
      state = state.copyWith(error: "Action failed");
    }
  }

  Future<void> setRole(String uid, UserRole role) async {
    try {
      await service.setRole(uid, role);
      await loadUsers();
      state = state.copyWith(success: "Role updated");
    } catch (_) {
      state = state.copyWith(error: "Role update failed");
    }
  AppUser? getUserById(String uid) {
    // First try to find in current state
    final user = state.users.firstWhere(
      (user) => user.uid == uid,
      orElse: () => AppUser(
        uid: uid,
        email: 'Utilisateur inconnu',
        displayName: 'Utilisateur inconnu',
        role: UserRole.user,
        createdAt: Timestamp.fromDate(DateTime.now()),
        suspended: false,
      ),
    );
    
    // If we found a valid user, return it
    if (user.uid == uid && user.email != 'Utilisateur inconnu') {
      return user;
    }
    
    // If not found in state, we'll need to fetch it individually
    // For now return the fallback user
    return user;
  }
  }

  /// Fetch user by ID directly from service (useful for real-time updates)
  Future<AppUser?> fetchUserById(String uid) async {
    try {
      return await service.getUserById(uid);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  /// Get multiple users by IDs efficiently
  Future<List<AppUser>> getUsersByIds(List<String> uids) async {
    try {
      return await service.getUsersByIds(uids);
    } catch (e) {
      print('Error fetching users by IDs: $e');
      return [];
    }
  }
}
