// lib/views/admin/users_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('users');
    return Padding(
      key: const ValueKey('users'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(children: [
            Text("Gestion des utilisateurs", style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: col.orderBy('createdAt', descending: true).snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_,__) => const Divider(),
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text((d['displayName'] ?? 'U').toString().substring(0,1).toUpperCase())),
                      title: Text(d['displayName'] ?? d['email'] ?? 'Sans nom'),
                      subtitle: Text(d['email'] ?? ''),
                      trailing: PopupMenuButton<int>(
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 1, child: Text("Promouvoir admin")),
                          const PopupMenuItem(value: 2, child: Text("Suspendre")),
                        ],
                        onSelected: (v) async {
                          if (v == 1) await docs[i].reference.update({'role': 'admin'});
                          if (v == 2) await docs[i].reference.update({'suspended': true});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
