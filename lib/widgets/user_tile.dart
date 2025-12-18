
import 'package:flutter/material.dart';
import 'package:mediatech/models/user_model.dart';
import 'package:mediatech/models/role.dart';

class UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onSuspend;
  final Future<void> Function()? onPromote;

  const UserTile({
    super.key,
    required this.user,
    this.onEdit,
    this.onDelete,
    this.onSuspend,
    this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: user.role == UserRole.admin 
                ? Colors.orange.shade100 
                : const Color(0xFF6B0E2A).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.person,
            color: user.role == UserRole.admin 
                ? Colors.orange 
                : const Color(0xFF6B0E2A),
            size: 20,
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(user.email),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                onEdit?.call();
                break;
              case 'promote':
                await onPromote?.call();
                break;
              case 'suspend':
                await onSuspend?.call();
                break;
              case 'delete':
                await onDelete?.call();
                break;
            }
          },
          itemBuilder: (_) => [
            if (onEdit != null)
              const PopupMenuItem(value: 'edit', child: Text('Edit User')),
            if (onPromote != null)
              PopupMenuItem(
                value: 'promote',
                child: Text(user.role == UserRole.admin ? 'Remove Admin' : 'Make Admin'),
              ),
            if (onSuspend != null)
              PopupMenuItem(
                value: 'suspend',
                child: Text(user.suspended ? 'Activate User' : 'Suspend User'),
              ),
            if (onDelete != null) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Account', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}