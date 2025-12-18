import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediatech/providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/theme_enum.dart';

/// ThemeControllerProvider that reacts to changes in AppUser
final themeControllerProvider =
    StateNotifierProvider<ThemeController, UserTheme>((ref) {
  final appUserAsync = ref.watch(appUserProvider);
  return ThemeController(ref, appUserAsync);
});

class ThemeController extends StateNotifier<UserTheme> {
  final Ref ref;

  ThemeController(this.ref, AsyncValue<AppUser?> appUserAsync)
      : super(appUserAsync.value?.theme ?? UserTheme.light) {
    // Listen to changes in AppUser
    appUserAsync.whenData((user) {
      if (user != null && user.theme != state) {
        state = user.theme;
      }
    });
  }

  /// Change theme and persist to Firestore
  Future<void> setTheme(UserTheme newTheme) async {
    state = newTheme;

    final appUser = ref.read(appUserProvider).value;
    if (appUser != null) {
      try {
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(appUser.uid);
        await docRef.update({'theme': newTheme.name});
      } catch (e) {
        print("❌ Failed to update theme in Firestore: $e");
      }
    }
  }
}
