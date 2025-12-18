// lib/views/admin/permissions_view.dart
import 'package:flutter/material.dart';

class PermissionsView extends StatelessWidget {
  const PermissionsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('permissions'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gestion des permissions", style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("Configurez ici les rôles et droits d'accès (CRUD, validation, etc.)"),
          // Add UI for role -> allowed actions mapping (table or cards)
        ],
      ),
    );
  }
}
