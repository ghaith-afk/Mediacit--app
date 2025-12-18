// views/admin_loans_reservations_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/admin_controller.dart';
import 'package:mediatech/controllers/loan_controller.dart';
import 'package:mediatech/models/loan_model.dart';
import 'package:mediatech/models/reservation_media_model.dart';
import 'package:mediatech/models/media_model.dart';
import 'package:mediatech/controllers/media_controller.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/models/user_model.dart';


class AdminLoansReservationsPage extends ConsumerStatefulWidget {
  const AdminLoansReservationsPage({super.key});

  @override
  ConsumerState<AdminLoansReservationsPage> createState() => _AdminLoansReservationsPageState();
}

class _AdminLoansReservationsPageState extends ConsumerState<AdminLoansReservationsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentTab = 0;

  // Colors
  static const Color _primaryColor = Color(0xFF7B1F2D);
  static const Color _secondaryColor = Color(0xFF1E2A4A);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _successColor = Color(0xFF28A745);
  static const Color _warningColor = Color(0xFFFFC107);
  static const Color _errorColor = Color(0xFFDC3545);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanControllerProvider);
    final mediaList = ref.watch(mediaControllerProvider).media;
    final users = ref.watch(adminControllerProvider).users; // Get users data

    if (loanState.loading) {
      return _buildLoading();
    }

    // Process data
    final activeLoans = loanState.loans.where((loan) => loan.returnedAt == null).toList();
    final returnedLoans = loanState.loans.where((loan) => loan.returnedAt != null).toList();
    final pendingReservations = loanState.reservations.where((res) => !res.approved).toList();
    final approvedReservations = loanState.reservations.where((res) => res.approved).toList();

    // Filter data
    final filteredActiveLoans = _filterLoans(activeLoans, mediaList, users);
    final filteredReturnedLoans = _filterLoans(returnedLoans, mediaList, users);
    final filteredPendingReservations = _filterReservations(pendingReservations, mediaList, users);
    final filteredApprovedReservations = _filterReservations(approvedReservations, mediaList, users);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Prêts'),
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(activeLoans, pendingReservations, returnedLoans),
          
          // Tabs
          _buildTabBar(),
          
          // Search
          _buildSearchBar(),
          
          // Content
          Expanded(
            child: _buildContent(
              filteredActiveLoans,
              filteredPendingReservations,
              filteredApprovedReservations,
              filteredReturnedLoans,
              mediaList,
              users,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildStatsOverview(List<LoanModel> activeLoans, List<ReservationModel> pendingReservations, List<LoanModel> returnedLoans) {
    final overdueCount = activeLoans.where((loan) => loan.dueDate.toDate().isBefore(DateTime.now())).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: activeLoans.length.toString(),
            label: 'Actifs',
            color: _secondaryColor,
            icon: Icons.library_books,
          ),
          _StatItem(
            value: overdueCount.toString(),
            label: 'En Retard',
            color: _errorColor,
            icon: Icons.warning,
          ),
          _StatItem(
            value: pendingReservations.length.toString(),
            label: 'En Attente',
            color: _warningColor,
            icon: Icons.pending,
          ),
          _StatItem(
            value: returnedLoans.length.toString(),
            label: 'Retournés',
            color: _successColor,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _TabItem(
            label: 'Prêts Actifs',
            isSelected: _currentTab == 0,
            onTap: () => setState(() => _currentTab = 0),
          ),
          _TabItem(
            label: 'Réservations',
            isSelected: _currentTab == 1,
            onTap: () => setState(() => _currentTab = 1),
          ),
          _TabItem(
            label: 'Historique',
            isSelected: _currentTab == 2,
            onTap: () => setState(() => _currentTab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par titre, auteur, utilisateur...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildContent(
    List<LoanModel> activeLoans,
    List<ReservationModel> pendingReservations,
    List<ReservationModel> approvedReservations,
    List<LoanModel> returnedLoans,
    List<MediaModel> mediaList,
    List<AppUser> users, // Add users parameter
  ) {
    switch (_currentTab) {
      case 0:
        return _LoansManagement(
          loans: activeLoans,
          mediaList: mediaList,
          users: users,
          isActive: true,
          onReturn: _returnLoan,
          onExtend: _extendLoan,
        );
      case 1:
        return _ReservationsManagement(
          pendingReservations: pendingReservations,
          approvedReservations: approvedReservations,
          mediaList: mediaList,
          users: users,
          onApprove: _approveReservation,
          onReject: _rejectReservation,
        );
      case 2:
        return _LoansManagement(
          loans: returnedLoans,
          mediaList: mediaList,
          users: users,
          isActive: false,
          onReturn: _returnLoan,
          onExtend: _extendLoan,
        );
      default:
        return const SizedBox();
    }
  }

  // Filter methods - UPDATED to include users
  List<LoanModel> _filterLoans(List<LoanModel> loans, List<MediaModel> mediaList, List<AppUser> users) {
    if (_searchQuery.isEmpty) return loans;
    
    return loans.where((loan) {
      final media = _getMediaForLoan(loan, mediaList);
      final user = _getAppUserById(loan.userId, users);
      
      return media.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.genre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ReservationModel> _filterReservations(List<ReservationModel> reservations, List<MediaModel> mediaList, List<AppUser> users) {
    if (_searchQuery.isEmpty) return reservations;
    
    return reservations.where((res) {
      final media = _getMediaForReservation(res, mediaList);
      final user = _getAppUserById(res.userId, users);
      
      return media.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.genre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Helper methods to get user data
  AppUser _getAppUserById(String userId, List<AppUser> users) {
    return users.firstWhere(
      (user) => user.uid == userId,
      orElse: () => AppUser(
        uid: userId,
        role:UserRole.user,
        suspended: true,
        createdAt: Timestamp.now(),
        email: 'Utilisateur inconnu',
        displayName: 'Utilisateur inconnu',
        // Add other required user fields
      ),
    );
  }

  MediaModel _getMediaForReservation(ReservationModel reservation, List<MediaModel> mediaList) {
  return mediaList.firstWhere(
    (m) => m.id == reservation.mediaId,
    orElse: () => MediaModel(
      id: reservation.mediaId,
      title: 'Média inconnu',
      author: 'Auteur inconnu',
      type: MediaType.book,
      description: '',
      coverUrl: '',
      pagesOrDuration: 0,
      totalCount: 0,
      availableCount: 0,
      tags: [],
      rating: 0,
      isbn: '',
      genre: 'Non spécifié',
      publisher: '',
      publicationYear: 0,
      language: 'Français',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    ),
  );
}
MediaModel _getMediaForLoan(LoanModel loan, List<MediaModel> mediaList) {
  return mediaList.firstWhere(
    (m) => m.id == loan.mediaId,
    orElse: () => MediaModel(
      id: loan.mediaId,
      title: 'Média inconnu',
      author: 'Auteur inconnu',
      type: MediaType.book,
      description: '',
      coverUrl: '',
      pagesOrDuration: 0,
      totalCount: 0,
      availableCount: 0,
      tags: [],
      rating: 0,
      isbn: '',
      genre: 'Non spécifié',
      publisher: '',
      publicationYear: 0,
      language: 'Français',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    ),
  );
}
 

  // Actions
  void _returnLoan(LoanModel loan) {
    ref.read(loanControllerProvider.notifier).returnLoan(loan);
    _showSnackbar('Prêt marqué comme retourné');
  }

  void _extendLoan(LoanModel loan) {
    ref.read(loanControllerProvider.notifier).extendLoan(loan);
    _showSnackbar('Prêt prolongé');
  }

  void _approveReservation(ReservationModel reservation) {
    ref.read(loanControllerProvider.notifier).approveReservation(reservation);
    _showSnackbar('Réservation approuvée');
  }

  void _rejectReservation(ReservationModel reservation) {
    ref.read(loanControllerProvider.notifier).rejectReservation(reservation);
    _showSnackbar('Réservation refusée');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _successColor,
      ),
    );
  }
}

// ========== IMPROVED COMPONENTS ==========

class _LoansManagement extends StatelessWidget {
  final List<LoanModel> loans;
  final List<MediaModel> mediaList;
  final List<AppUser> users;
  final bool isActive;
  final Function(LoanModel) onReturn;
  final Function(LoanModel) onExtend;

  const _LoansManagement({
    required this.loans,
    required this.mediaList,
    required this.users,
    required this.isActive,
    required this.onReturn,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return _EmptyState(
        icon: Icons.library_books,
        title: isActive ? 'Aucun prêt actif' : 'Aucun historique',
        subtitle: isActive ? 'Les prêts en cours apparaîtront ici' : 'Les retours apparaîtront ici',
      );
    }

    // Group by media type
    final books = loans.where((loan) {
      final media = _getMediaForLoan(loan, mediaList);
      return media.type == MediaType.book;
    }).toList();

    final movies = loans.where((loan) {
      final media = _getMediaForLoan(loan, mediaList);
      return media.type == MediaType.movie;
    }).toList();

    final music = loans.where((loan) {
      final media = _getMediaForLoan(loan, mediaList);
      return media.type == MediaType.music;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (books.isNotEmpty) ...[
          _CategoryHeader(title: 'Livres (${books.length})', icon: Icons.menu_book),
          ...books.map((loan) => _ImprovedLoanCard(
            loan: loan,
            media: _getMediaForLoan(loan, mediaList),
            user: _getAppUserById(loan.userId, users),
            isActive: isActive,
            onReturn: onReturn,
            onExtend: onExtend,
          )),
          const SizedBox(height: 16),
        ],
        if (movies.isNotEmpty) ...[
          _CategoryHeader(title: 'Films (${movies.length})', icon: Icons.movie),
          ...movies.map((loan) => _ImprovedLoanCard(
            loan: loan,
            media: _getMediaForLoan(loan, mediaList),
            user: _getAppUserById(loan.userId, users),
            isActive: isActive,
            onReturn: onReturn,
            onExtend: onExtend,
          )),
          const SizedBox(height: 16),
        ],
        if (music.isNotEmpty) ...[
          _CategoryHeader(title: 'Musique (${music.length})', icon: Icons.music_note),
          ...music.map((loan) => _ImprovedLoanCard(
            loan: loan,
            media: _getMediaForLoan(loan, mediaList),
            user: _getAppUserById(loan.userId, users),
            isActive: isActive,
            onReturn: onReturn,
            onExtend: onExtend,
          )),
        ],
      ],
    );
  }

  MediaModel _getMediaForLoan(LoanModel loan, List<MediaModel> mediaList) {
    return mediaList.firstWhere((m) => m.id == loan.mediaId);
  }

 AppUser _getAppUserById(String userId, List<AppUser> users) {
  return users.firstWhere(
    (user) => user.uid == userId,
    orElse: () => AppUser(
      uid: userId,
      role: UserRole.user,
      suspended: false,
      createdAt: Timestamp.now(),
      email: 'Utilisateur inconnu',
      displayName: 'Utilisateur inconnu',
      // Add other required user fields based on your AppUser model
    ),
  );
}
}

class _ReservationsManagement extends StatelessWidget {
  final List<ReservationModel> pendingReservations;
  final List<ReservationModel> approvedReservations;
  final List<MediaModel> mediaList;
  final List<AppUser> users;
  final Function(ReservationModel) onApprove;
  final Function(ReservationModel) onReject;

  const _ReservationsManagement({
    required this.pendingReservations,
    required this.approvedReservations,
    required this.mediaList,
    required this.users,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingReservations.isEmpty && approvedReservations.isEmpty) {
      return _EmptyState(
        icon: Icons.pending_actions,
        title: 'Aucune réservation',
        subtitle: 'Les réservations apparaîtront ici',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (pendingReservations.isNotEmpty) ...[
          _SectionHeader(title: 'En Attente (${pendingReservations.length})'),
          ...pendingReservations.map((reservation) {
            final media = _getMediaForReservation(reservation, mediaList);
            final user = _getAppUserById(reservation.userId, users);
            final queuePosition = _getReservationQueuePosition(reservation, pendingReservations);
            
            return _ImprovedReservationCard(
              reservation: reservation,
              media: media,
              user: user,
              queuePosition: queuePosition,
              isApproved: reservation.approved,
              onApprove: onApprove,
              onReject: onReject,
            );
          }),
          const SizedBox(height: 16),
        ],
        if (approvedReservations.isNotEmpty) ...[
          _SectionHeader(title: 'Approuvées (${approvedReservations.length})'),
          ...approvedReservations.map((reservation) {
            final media = _getMediaForReservation(reservation, mediaList);
            final user = _getAppUserById(reservation.userId, users);
            
            return _ImprovedReservationCard(
              reservation: reservation,
              media: media,
              user: user,
              queuePosition: 0,
              isApproved: reservation.approved,
              onApprove: onApprove,
              onReject: onReject,
            );
          }),
        ],
      ],
    );
  }
MediaModel _getMediaForReservation(ReservationModel reservation, List<MediaModel> mediaList) {
  return mediaList.firstWhere(
    (m) => m.id == reservation.mediaId,
    orElse: () => MediaModel(
      id: reservation.mediaId,
      title: 'Média inconnu',
      author: 'Auteur inconnu',
      type: MediaType.book,
      description: '',
      coverUrl: '',
      pagesOrDuration: 0,
      totalCount: 0,
      availableCount: 0,
      tags: [],
      rating: 0,
      isbn: '',
      genre: 'Non spécifié',
      publisher: '',
      publicationYear: 0,
      language: 'Français',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    ),
  );
}

  AppUser _getAppUserById(String userId, List<AppUser> users) {
    return users.firstWhere((user) => user.uid == userId);
  }

  int _getReservationQueuePosition(ReservationModel reservation, List<ReservationModel> allReservations) {
    // Get all reservations for the same media
    final mediaReservations = allReservations.where((r) => r.mediaId == reservation.mediaId).toList();
    
    // Sort by creation date
    mediaReservations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    // Find position in queue
    return mediaReservations.indexWhere((r) => r.id == reservation.id) + 1;
  }
}

class _ImprovedLoanCard extends StatelessWidget {
  final LoanModel loan;
  final MediaModel media;
  final AppUser user;
  final bool isActive;
  final Function(LoanModel) onReturn;
  final Function(LoanModel) onExtend;

  const _ImprovedLoanCard({
    required this.loan,
    required this.media,
    required this.user,
    required this.isActive,
    required this.onReturn,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = loan.dueDate.toDate();
    final isOverdue = isActive && dueDate.isBefore(DateTime.now());
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and media type
            Row(
              children: [
                _MediaTypeChip(type: media.type),
                const Spacer(),
                _StatusChip(
                  text: isActive ? (isOverdue ? 'EN RETARD' : 'EN COURS') : 'RETOURNÉ',
                  color: isActive ? (isOverdue ? _AdminLoansReservationsPageState._errorColor : _AdminLoansReservationsPageState._secondaryColor) : _AdminLoansReservationsPageState._successColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Media Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: media.coverUrl.isNotEmpty 
                        ? DecorationImage(
                            image: NetworkImage(media.coverUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: media.coverUrl.isEmpty ? 
                    Icon(_getMediaTypeIcon(media.type), color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                
                // Media Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Par ${media.author}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      if (media.genre.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Genre: ${media.genre}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // AppUser Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Due Date Info
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isOverdue ? _AdminLoansReservationsPageState._errorColor : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Échéance: ${_formatDate(dueDate)}',
                    style: TextStyle(
                      color: isOverdue ? _AdminLoansReservationsPageState._errorColor : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isActive && !isOverdue)
                  Text(
                    '$daysUntilDue jours restants',
                    style: TextStyle(
                      color: daysUntilDue <= 3 ? _AdminLoansReservationsPageState._warningColor : _AdminLoansReservationsPageState._successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            
            // Actions
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      text: 'Retourner',
                      icon: Icons.check,
                      color: _AdminLoansReservationsPageState._successColor,
                      onTap: () => onReturn(loan),
                    ),
                  ),
                  if (!loan.extended) ...[
                    const SizedBox(width: 1),
                    Expanded(
                      child: _ActionButton(
                        text: 'Prolonger',
                        icon: Icons.calendar_today,
                        color: _AdminLoansReservationsPageState._warningColor,
                        onTap: () => onExtend(loan),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImprovedReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final MediaModel media;
  final AppUser user;
  final int queuePosition;
  final bool isApproved;
  final Function(ReservationModel) onApprove;
  final Function(ReservationModel) onReject;

  const _ImprovedReservationCard({
    required this.reservation,
    required this.media,
    required this.user,
    required this.queuePosition,
    required this.isApproved,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and queue info
            Row(
              children: [
                _MediaTypeChip(type: media.type),
                const Spacer(),
                if (!reservation.approved && queuePosition > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _AdminLoansReservationsPageState._primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$queuePosition dans la file',
                      style: TextStyle(
                        color: _AdminLoansReservationsPageState._primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
              ],
            ),
                     _StatusChip(
                  text: isApproved ? 'APPROUVÉE' : 'EN ATTENTE',
                  color: isApproved ? _AdminLoansReservationsPageState._successColor : _AdminLoansReservationsPageState._warningColor,
                ),
            const SizedBox(height: 12),
            
            // Media Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: media.coverUrl.isNotEmpty 
                        ? DecorationImage(
                            image: NetworkImage(media.coverUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: media.coverUrl.isEmpty ? 
                    Icon(_getMediaTypeIcon(media.type), color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                
                // Media Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Par ${media.author}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      if (media.genre.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Genre: ${media.genre}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // AppUser Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Reservation Period
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_formatDate(reservation.createdAt.toDate())}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            // Actions
            if (!isApproved) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      text: 'Approuver',
                      icon: Icons.check,
                      color: _AdminLoansReservationsPageState._successColor,
                      onTap: () => onApprove(reservation),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      text: 'Refuser',
                      icon: Icons.close,
                      color: _AdminLoansReservationsPageState._errorColor,
                      onTap: () => onReject(reservation),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// NEW COMPONENTS

class _MediaTypeChip extends StatelessWidget {
  final MediaType type;

  const _MediaTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, text) = _getMediaTypeInfo(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getMediaTypeIcon(type), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _getMediaTypeInfo(MediaType type) {
    switch (type) {
      case MediaType.book:
        return (Colors.blue, 'LIVRE');
      case MediaType.movie:
        return (Colors.purple, 'FILM');
      case MediaType.music:
        return (Colors.orange, 'MUSIQUE');
      default:
        return (Colors.grey, 'AUTRE');
    }
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CategoryHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: _AdminLoansReservationsPageState._primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
// ========== REUSABLE COMPONENTS ==========

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? _AdminLoansReservationsPageState._primaryColor.withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? _AdminLoansReservationsPageState._primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _AdminLoansReservationsPageState._primaryColor : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // This is the key fix
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper functions
String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}


// Keep existing components (_StatItem, _TabItem, _StatusChip, _ActionButton, _SectionHeader, _EmptyState) 
// but update them to use the new improved card components

// Helper functions

IconData _getMediaTypeIcon(MediaType type) {
  switch (type) {
      case MediaType.game:
      return Icons.gamepad;
      case MediaType.magazine:
      return Icons.newspaper;
    case MediaType.book:
      return Icons.menu_book;
    case MediaType.movie:
      return Icons.movie;
    case MediaType.music:
      return Icons.music_note;
    default:
      return Icons.help;
  }
  
}

