// user_management_view.dart - User-focused with accurate filter numbers
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediatech/Controllers/admin_controller.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/models/user_model.dart';
import 'package:mediatech/views/admin/user_form_dialog.dart';
import 'package:mediatech/widgets/confirm_dialog.dart';
import 'package:mediatech/widgets/user_tile.dart';

class UserManagementView extends ConsumerStatefulWidget {
  const UserManagementView({super.key});

  @override
  ConsumerState<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends ConsumerState<UserManagementView> {
  String _search = '';
  String _filter = 'All';
  late String _currentUserUid;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _searchController.addListener(() {
      setState(() => _search = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Calculate filter counts
  Map<String, int> _getFilterCounts(List<AppUser> users) {
    return {
      'All': users.length,
      'Admins': users.where((u) => u.role == UserRole.admin).length,
      'Active': users.where((u) => !u.suspended).length,
      'Suspended': users.where((u) => u.suspended).length,
    };
  }

  Widget _buildFilterChip(String label, int count, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B0E2A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B0E2A) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF6B0E2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFF6B0E2A) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    // Get filtered users
    final filteredUsers = state.users.where((u) {
      final matchesSearch = u.displayName.toLowerCase().contains(_search.toLowerCase()) ||
          u.email.toLowerCase().contains(_search.toLowerCase());
      final matchesFilter = switch (_filter) {
        'Admins' => u.role == UserRole.admin,
        'Suspended' => u.suspended,
        'Active' => !u.suspended,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();

    // Get accurate filter counts
    final filterCounts = _getFilterCounts(state.users);
    final currentFilterCount = _getFilterCounts(filteredUsers)['All']!;

    return Scaffold(
  appBar: AppBar(
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'User Management',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
      Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(adminControllerProvider);
          return Text(
            '${state.users.length} Users',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          );
        },
      ),
    ],
  ),
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF001F3F),
  elevation: 0,
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(
      height: 1,
      color: Colors.grey.shade200,
    ),
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.refresh, color: Colors.grey.shade600),
      onPressed: controller.loadUsers,
    ),
    Container(
      height: 32,
      margin: const EdgeInsets.only(right: 16),
      child: FilledButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const UserFormDialog(),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6B0E2A),
          foregroundColor: Colors.white,
        ),
      ),
    ),
  ],
),
      body: Column(
        children: [
          // Stats Header - More compact
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.people_alt, color: const Color(0xFF6B0E2A), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Users (${currentFilterCount})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B0E2A),
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${state.users.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B0E2A)),
                    hintText: 'Search users by name or email...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6B0E2A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips with accurate counts
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', filterCounts['All']!, _filter == 'All', 
                          () => setState(() => _filter = 'All')),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admins', filterCounts['Admins']!, _filter == 'Admins', 
                          () => setState(() => _filter = 'Admins')),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', filterCounts['Active']!, _filter == 'Active', 
                          () => setState(() => _filter = 'Active')),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspended', filterCounts['Suspended']!, _filter == 'Suspended', 
                          () => setState(() => _filter = 'Suspended')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: controller.clearMessages,
                  ),
                ],
              ),
            ),

          if (state.success != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.success!)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: controller.clearMessages,
                  ),
                ],
              ),
            ),

          // User List - Takes most space
          Expanded(
            child: state.loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6B0E2A)),
                        SizedBox(height: 16),
                        Text(
                          'Loading users...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _search.isEmpty ? 'No users found' : 'No users match your search',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_search.isNotEmpty || _filter != 'All') ...[
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _search = '';
                                    _filter = 'All';
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B0E2A),
                                ),
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (ctx, i) {
                          final user = filteredUsers[i];
                          final isSelf = user.uid == _currentUserUid;

                          return UserTile(
                            user: user,
                            onEdit: () => showDialog(
                              context: context,
                              builder: (_) => UserFormDialog(user: user),
                            ),
                            onDelete: isSelf
                                ? () async {
                                    final confirm = await showConfirmDialog(
                                      context,
                                      'Delete Account?',
                                      'This will permanently delete your account and all associated data.',
                                    );
                                    if (confirm) {
                                      await controller.deleteUser(_currentUserUid);
                                    }
                                  }
                                : null,
                            onSuspend: !isSelf
                                ? () async {
                                    final confirm = await showConfirmDialog(
                                      context,
                                      user.suspended ? 'Activate User?' : 'Suspend User?',
                                      user.suspended 
                                          ? 'This user will be able to access the system again.'
                                          : 'This user will be temporarily blocked from accessing the system.',
                                    );
                                    if (confirm) {
                                      await controller.toggleSuspend(user.uid, !user.suspended);
                                    }
                                  }
                                : null,
                            onPromote: !isSelf
                                ? () async {
                                    final confirm = await showConfirmDialog(
                                      context,
                                      user.role == UserRole.admin ? 'Remove Admin Role?' : 'Make Admin?',
                                      user.role == UserRole.admin
                                          ? 'This user will lose administrator privileges.'
                                          : 'This user will gain full administrator access to the system.',
                                    );
                                    if (confirm) {
                                      await controller.setRole(
                                        user.uid,
                                        user.role == UserRole.admin ? UserRole.user : UserRole.admin,
                                      );
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}