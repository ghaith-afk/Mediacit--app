import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_page.dart';

class Sidebar extends ConsumerWidget {
  final bool collapsed;
  const Sidebar({super.key, required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);

    final items = [
      _SidebarItem(Icons.dashboard_rounded, "Dashboard", 0),
      _SidebarItem(Icons.video_library_rounded, "Media", 1),
      _SidebarItem(Icons.event_rounded, "Events", 2),
      _SidebarItem(Icons.people_alt_rounded, "Users", 3),
     
    ];

    return Column(
      children: [
        const SizedBox(height: 24),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              collapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          secondChild: Column(
            children: const [
              Icon(Icons.auto_awesome_motion_sharp, color: Colors.white, size: 32),
              SizedBox(height: 8),
              Text("Mediacité Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: ListView(
            children: items.map((item) {
              final isActive = currentPage == item.index;
              return ListTile(
                leading: Icon(item.icon,
                    color: isActive ? const Color(0xfffe4c50) : Colors.white70),
                title: collapsed
                    ? null
                    : Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xfffe4c50)
                              : Colors.white70,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                onTap: () =>
                    ref.read(currentPageProvider.notifier).state = item.index,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  final int index;
  _SidebarItem(this.icon, this.label, this.index);
}