import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mediatech/providers/auth_provider.dart';


class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    return Scaffold(
      body: userAsync.when(
        data: (user) => user == null ? const Center(child: Text('Non connecté')) : Center(child: Text('Bonjour ${user.displayName}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
