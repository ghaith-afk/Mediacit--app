import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/views/admin/admin_sidebar.dart';
import 'package:mediatech/views/admin/admin_topbar.dart';
import 'package:mediatech/views/admin/admins_loans_page.dart';
import 'package:mediatech/views/admin/dashboard_view.dart';
import 'package:mediatech/views/admin/media_view.dart';
import 'package:mediatech/views/admin/user_management_view.dart';

final currentPageProvider = StateProvider<int>((ref) => 0);
final sidebarCollapsedProvider = StateProvider<bool>((ref) => true);

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final collapsed = ref.watch(sidebarCollapsedProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff9f9fb),
      body: SafeArea(
        child: Row(
          children: [
            // SIDEBAR
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: collapsed ? 70 : 240,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff1e1e2c), Color(0xff2a2a3d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Sidebar(collapsed: collapsed),
            ),

            // MAIN CONTENT
            Expanded(
              child: Column(
                children: [
                  // TOP BAR
                  TopBar(
                    onToggleSidebar: () => ref
                        .read(sidebarCollapsedProvider.notifier)
                        .state = !collapsed,
                  ),
                  // CONTENT AREA
                  Expanded(
                    child: Container(
                      color: const Color(0xfff9f9fb),
                      child: _getPage(currentPage),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _getPage(int index) {
  switch (index) {
    case 0:
      return const AdminLoansReservationsPage();
    case 1:
     return const MediaManagementView(); // Media Management View
    case 2:
      return const Center(child: Text('Events Management'));
    case 3:
      return const UserManagementView(); // User Management View
    case 4:
      return const Center(child: Text('Settings'));
    default:
      return const Center(child: Text('Dashboard View'));
  }
}

}