import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediatech/Controllers/auth_controller.dart';

class TopBar extends ConsumerWidget {
  final VoidCallback onToggleSidebar;
  const TopBar({super.key, required this.onToggleSidebar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 65,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggleSidebar,
            icon: const Icon(Icons.menu_rounded, color: Colors.black87),
            tooltip: "Toggle sidebar",
          ),
          const Spacer(),
          _NotificationButton(),
          const SizedBox(width: 8),
          _ProfileMenu(ref: ref),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Badge(
        label: const Text("3"),
        backgroundColor: const Color(0xFF7B1F2D),
        child: const Icon(Icons.notifications_outlined, color: Colors.black54, size: 22),
      ),
      tooltip: "Notifications",
      onPressed: () => _showNotifications(context),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Notifications",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const Spacer(),
                    Badge(
                      label: const Text("3"),
                      backgroundColor: const Color(0xFF7B1F2D),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNotificationItem("New user registered", Icons.person_add, "2 min ago"),
                _buildNotificationItem("Server usage 90%", Icons.warning_amber_rounded, "5 min ago"),
                _buildNotificationItem("Payment received", Icons.attach_money, "1 hour ago"),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1F2D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("View All Notifications"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String text, IconData icon, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF7B1F2D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7B1F2D), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends ConsumerWidget {
  final WidgetRef ref;
  
  const _ProfileMenu({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (value) => _handleMenuSelection(value, context, ref),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(LucideIcons.user, size: 18, color: Colors.black54),
              const SizedBox(width: 12),
              const Text('My Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(LucideIcons.settings, size: 18, color: Colors.black54),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(LucideIcons.logOut, size: 18, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF7B1F2D),
        child: _buildProfileAvatar(user),
      ),
    );
  }

  Widget _buildProfileAvatar(User? user) {
    if (user?.photoURL != null) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(user!.photoURL!));
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return Text(
        user.displayName!.substring(0, 1).toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      );
    } else {
      return const Icon(Icons.person, color: Colors.white, size: 18);
    }
  }

  void _handleMenuSelection(String value, BuildContext context, WidgetRef ref) {
    switch (value) {
      case 'profile':
        _showProfile(context);
        break;
      case 'settings':
        _showSettings(context);
        break;
      case 'logout':
        _handleLogout(context, ref);
        break;
    }
  }

  void _showProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user?.displayName != null) Text("Name: ${user!.displayName}"),
            if (user?.email != null) Text("Email: ${user!.email}"),
            if (user?.phoneNumber != null) Text("Phone: ${user!.phoneNumber}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: const Text("Settings will be available soon."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout Confirmation"),
          content: const Text("Are you sure you want to logout from your account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7B1F2D)),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final authController = ref.read(authControllerProvider.notifier);
        await authController.logout();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged out'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: const Color(0xFF7B1F2D),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}