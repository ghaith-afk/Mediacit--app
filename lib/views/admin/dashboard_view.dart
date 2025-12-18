import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/loan_controller.dart';
import 'package:mediatech/Controllers/media_controller.dart';
import 'package:mediatech/models/loan_model.dart';
import 'package:mediatech/models/media_model.dart';
import 'package:mediatech/models/reservation_media_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  String _search = '';
  String _filter = 'Tous';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _search = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LoanModel> _filteredLoans(List<LoanModel> loans, List<MediaModel> mediaList) {
    return loans.where((loan) {
      final mediaItem = mediaList.firstWhere(
        (m) => m.id == loan.mediaId,
        orElse: () => MediaModel(
          id: loan.mediaId,
          title: 'Inconnu',
          author: '',
          type: MediaType.book,
          description: '',
          coverUrl: '',
          pagesOrDuration: 0,
          totalCount: 0,
          availableCount: 0,
          tags: [],
          rating: 0,
          isbn: '',
          genre: '',
          publisher: '',
          publicationYear: 0,
          language: 'Français',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ),
      );

      final matchesSearch = loan.userId.toLowerCase().contains(_search.toLowerCase()) ||
          mediaItem.title.toLowerCase().contains(_search.toLowerCase());

      final matchesFilter = switch (_filter) {
        'Prêté' => loan.returnedAt == null,
        'Rendu' => loan.returnedAt != null,
        'En retard' => loan.dueDate.toDate().isBefore(DateTime.now()) && loan.returnedAt == null,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<ReservationModel> _filteredReservations(List<ReservationModel> reservations, List<MediaModel> mediaList) {
    return reservations.where((res) {
      final mediaItem = mediaList.firstWhere(
        (m) => m.id == res.mediaId,
        orElse: () => MediaModel(
          id: res.mediaId,
          title: 'Inconnu',
          author: '',
          type: MediaType.book,
          description: '',
          coverUrl: '',
          pagesOrDuration: 0,
          totalCount: 0,
          availableCount: 0,
          tags: [],
          rating: 0,
          isbn: '',
          genre: '',
          publisher: '',
          publicationYear: 0,
          language: 'Français',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ),
      );

      final matchesSearch = res.userId.toLowerCase().contains(_search.toLowerCase()) ||
          mediaItem.title.toLowerCase().contains(_search.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanControllerProvider);
    final mediaList = ref.read(mediaControllerProvider).media;

    final filteredLoans = _filteredLoans(loanState.loans, mediaList);
    final filteredReservations = _filteredReservations(loanState.reservations, mediaList);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Gestion des prêts et réservations'),
        backgroundColor: const Color(0xFF6B0E2A),
      ),
      body: Column(
        children: [
          // --- Barre de recherche ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par utilisateur ou média...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- Liste des réservations en attente ---
          if (filteredReservations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Réservations en attente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ),
            Expanded(
              flex: 1,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredReservations.length,
                itemBuilder: (_, i) {
                  final res = filteredReservations[i];
                  final mediaItem = mediaList.firstWhere(
                    (m) => m.id == res.mediaId,
                    orElse: () => MediaModel(id: res.mediaId, title: 'Inconnu', author: '', type: MediaType.book, description: '', coverUrl: '', pagesOrDuration: 0, totalCount: 0, availableCount: 0, tags: [], rating: 0, isbn: '', genre: '', publisher: '', publicationYear: 0, language: 'Français', createdAt: Timestamp.now(), updatedAt: Timestamp.now()),
                  );

                  return Card(
                    color: Colors.yellow.shade50,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${res.userId} — ${mediaItem.title}'),
                      subtitle: Text('Réservé le: ${res.createdAt.toDate().day}/${res.createdAt.toDate().month}/${res.createdAt.toDate().year}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await ref.read(loanControllerProvider.notifier).approveReservation(res);
                            },
                            tooltip: 'Accepter',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await ref.read(loanControllerProvider.notifier).rejectReservation(res);
                            },
                            tooltip: 'Refuser',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // --- Liste des prêts ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Prêts actifs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
          ),
          Expanded(
            flex: 2,
            child: filteredLoans.isEmpty
                ? Center(child: Text('Aucun prêt en cours', style: TextStyle(color: Colors.grey.shade600)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredLoans.length,
                    itemBuilder: (_, i) {
                      final loan = filteredLoans[i];
                      final mediaItem = mediaList.firstWhere(
                        (m) => m.id == loan.mediaId,
                        orElse: () => MediaModel(id: loan.mediaId, title: 'Inconnu', author: '', type: MediaType.book, description: '', coverUrl: '', pagesOrDuration: 0, totalCount: 0, availableCount: 0, tags: [], rating: 0, isbn: '', genre: '', publisher: '', publicationYear: 0, language: 'Français', createdAt: Timestamp.now(), updatedAt: Timestamp.now()),
                      );

                      final returned = loan.returnedAt != null;
                      final overdue = loan.dueDate.toDate().isBefore(DateTime.now()) && !returned;

                      return Card(
                        color: overdue ? Colors.red.shade50 : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('${loan.userId} — ${mediaItem.title}'),
                          subtitle: Text(
                              'Échéance: ${loan.dueDate.toDate().day}/${loan.dueDate.toDate().month}/${loan.dueDate.toDate().year}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                returned ? 'Rendu' : 'Prêté',
                                style: TextStyle(
                                    color: returned ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.assignment_return, color: Colors.redAccent),
                                onPressed: returned
                                    ? null
                                    : () async {
                                        await ref.read(loanControllerProvider.notifier).returnLoan(loan);
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.update, color: Colors.amber),
                                onPressed: returned || loan.extended
                                    ? null
                                    : () async {
                                        await ref.read(loanControllerProvider.notifier).extendLoan(loan);
                                      },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
