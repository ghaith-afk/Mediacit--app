import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/auth_controller.dart';
import 'package:mediatech/Controllers/ThemeController.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/models/theme_enum.dart';
import 'package:mediatech/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class AppDrawer extends ConsumerWidget {
  final VoidCallback onLogout;

  const AppDrawer({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);
    final theme = ref.watch(themeControllerProvider);
    final themeNotifier = ref.watch(themeControllerProvider.notifier);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            appUserAsync.when(
              data: (user) => user == null
                  ? _buildDefaultHeader(theme, themeNotifier)
                  : _buildUserHeader(user, theme, themeNotifier),
              loading: _buildLoadingHeader,
              error: (e, st) => _buildErrorHeader(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                
                    _buildMenuItem(
                      context, 
                      Icons.library_books_outlined, 
                      "Catalogue",
                      onTap: () => _navigateToRoute(context, '/catalogue'),
                      theme: theme,
                    ),
                    _buildMenuItem(
                      context, 
                      Icons.book_online_outlined, 
                      "Mes Réservations",
                      onTap: () => _navigateToRoute(context, '/user/loans'),
                      theme: theme,
                    ),
                    _buildMenuItem(
                      context, 
                      Icons.event_note_outlined, 
                      "Événements",
                      onTap: () => _navigateToRoute(context, '/events'),
                      theme: theme,
                    ),
                    // Admin-only menu items
                    if (appUserAsync.value?.role == UserRole.admin) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "ADMINISTRATION",
                          style: TextStyle(
                            color: theme == UserTheme.dark ? Colors.white54 : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context, 
                        Icons.people_outlined, 
                        "Gestion Utilisateurs",
                        onTap: () => _navigateToRoute(context, '/users-management'),
                        theme: theme,
                      ),
                      _buildMenuItem(
                        context, 
                        Icons.inventory_2_outlined, 
                        "Gestion Médiathèque",
                        onTap: () => _navigateToRoute(context, '/media-management'),
                        theme: theme,
                      ),
                      _buildMenuItem(
                        context, 
                        Icons.bar_chart_outlined, 
                        "Statistiques",
                        onTap: () => _navigateToRoute(context, '/statistics'),
                        theme: theme,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1),
            _buildMenuItem(
              context,
              Icons.logout_outlined,
              "Se déconnecter",
              isLogout: true,
              theme: theme,
              onTap: () async {
                Navigator.of(context).pop(); // Close drawer first
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Navigation helper method
  void _navigateToRoute(BuildContext context, String routeName) {
    Navigator.of(context).pop(); // Close drawer first
    Navigator.pushNamed(context, routeName);
  }

  // HEADER: Default
  Widget _buildDefaultHeader(UserTheme theme, ThemeController themeNotifier) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bordeaux, AppColors.bordeaux.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              "MediaTech",
              style: TextStyle(
                color: theme == UserTheme.light ? Colors.white : Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _buildThemeSwitch(theme, themeNotifier),
          ),
        ],
      ),
    );
  }

  // HEADER: User
  Widget _buildUserHeader(AppUser user, UserTheme theme, ThemeController themeNotifier) {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bordeaux, AppColors.bordeaux.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.bordeaux
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName.isNotEmpty ? user.displayName : "Utilisateur",
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildBadge('Role: ${user.role.name.toUpperCase()}', roleColor(user.role)),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _buildThemeSwitch(theme, themeNotifier),
          ),
        ],
      ),
    );
  }

  // SUN/MOON THEME SWITCH
  Widget _buildThemeSwitch(UserTheme theme, ThemeController themeNotifier) {
    return GestureDetector(
      onTap: () {
        final newTheme = theme == UserTheme.light ? UserTheme.dark : UserTheme.light;
        themeNotifier.setTheme(newTheme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme == UserTheme.light ? Colors.yellow[100] : Colors.grey[800],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => RotationTransition(turns: anim, child: child),
          child: Icon(
            theme == UserTheme.light ? Icons.wb_sunny : Icons.nightlight_round,
            key: ValueKey(theme),
            color: theme == UserTheme.light ? Colors.orange : Colors.yellow[300],
            size: 28,
          ),
        ),
      ),
    );
  }

  // MENU ITEM
  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap, bool isLogout = false, required UserTheme theme}) {
    final isDark = theme == UserTheme.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: isDark ? Colors.white24 : Colors.grey.withOpacity(0.2),
          highlightColor: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isLogout
                  ? Colors.red.withOpacity(0.1)
                  : isDark
                      ? Colors.grey[850]
                      : Colors.grey[100],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout ? Colors.red : isDark ? Colors.white70 : Colors.grey[800],
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isLogout ? FontWeight.bold : FontWeight.w500,
                    color: isLogout ? Colors.red : isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (!isLogout)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
            color: bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLoadingHeader() => Container(
        height: 180,
        color: AppColors.bordeaux,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

  Widget _buildErrorHeader() => Container(
        height: 180,
        color: AppColors.bordeaux,
        child: const Center(
          child: Text("Erreur de chargement", style: TextStyle(color: Colors.white)),
        ),
      );

  Color roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.redAccent;
      case UserRole.user:
        return Colors.blueAccent;
    }
  }
}