// user_form_dialog.dart - Responsive
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediatech/Controllers/admin_controller.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/models/user_model.dart';
import 'package:mediatech/widgets/confirm_dialog.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final AppUser? user;
  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _currentPassCtrl;
  UserRole _role = UserRole.user;
  bool _suspended = false;
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureCurrent = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.displayName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _passCtrl = TextEditingController();
    _currentPassCtrl = TextEditingController();
    _role = widget.user?.role ?? UserRole.user;
    _suspended = widget.user?.suspended ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _currentPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);
    final isSelf = widget.user?.uid == FirebaseAuth.instance.currentUser?.uid;
    final isSmall = MediaQuery.of(context).size.width < 400;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmall ? MediaQuery.of(context).size.width * 0.9 : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B0E2A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                          color: const Color(0xFF6B0E2A),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEdit ? 'Edit User' : 'Add User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message
                if (state.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Name Field
                Text(
                  'Display Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email Field
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !isEdit || isSelf,
                  decoration: InputDecoration(
                    hintText: 'user@example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Section
                if (isEdit && isSelf) ...[
                  Text(
                    'Current Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _currentPassCtrl,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      hintText: 'Enter current password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (!isEdit || isSelf) ...[
                  Text(
                    isEdit ? 'New Password' : 'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (!isEdit && v!.isEmpty) return 'Password required';
                      if (v!.isNotEmpty && v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (isEdit && !isSelf)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001F3F).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, color: const Color(0xFF001F3F)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password Reset',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                'Send reset email to user',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _loading ? null : () async {
                            setState(() => _loading = true);
                            await controller.updateUser(widget.user!, newPassword: "reset");
                            setState(() => _loading = false);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF001F3F),
                          ),
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Role & Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Role',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<UserRole>(
                              value: _role,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: UserRole.values.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (r) => setState(() => _role = r!),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _suspended ? 'Suspended' : 'Active',
                                    style: TextStyle(
                                      color: _suspended ? Colors.orange : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: !_suspended,
                                  onChanged: (v) => setState(() => _suspended = !v),
                                  activeColor: const Color(0xFF6B0E2A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    if (isEdit && isSelf)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : () async {
                            final confirm = await showConfirmDialog(
                              context,
                              'Delete Account?',
                              'This action cannot be undone. All your data will be permanently deleted.',
                            );
                            if (!confirm) return;
                            setState(() => _loading = true);
                            await controller.deleteUser(widget.user!.uid);
                            setState(() => _loading = false);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Delete Account'),
                        ),
                      ),
                    if (isEdit && isSelf) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading ? null : () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          setState(() => _loading = true);
                          controller.clearMessages();

                          if (isEdit) {
                            await controller.updateUser(
                              widget.user!.copyWith(
                                displayName: _nameCtrl.text,
                                email: _emailCtrl.text,
                                role: _role,
                                suspended: _suspended,
                              ),
                              newPassword: _passCtrl.text.isNotEmpty ? _passCtrl.text : null,
                              currentPassword: _currentPassCtrl.text.isNotEmpty ? _currentPassCtrl.text : null,
                            );
                          } else {
                            await controller.addUser(
                              AppUser(
                                uid: DateTime.now().millisecondsSinceEpoch.toString(),
                                displayName: _nameCtrl.text,
                                email: _emailCtrl.text,
                                role: _role,
                                suspended: _suspended,
                                createdAt: Timestamp.now(),
                              ),
                              _passCtrl.text,
                            );
                          }

                          setState(() => _loading = false);
                          if (state.error == null && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6B0E2A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isEdit ? 'Save Changes' : 'Create User'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}