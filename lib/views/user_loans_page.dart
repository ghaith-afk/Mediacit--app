// views/user_loans_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/controllers/loan_controller.dart';
import 'package:mediatech/controllers/media_controller.dart';
import 'package:mediatech/models/loan_model.dart';
import 'package:mediatech/models/media_model.dart';
import 'package:mediatech/models/reservation_media_model.dart';
import 'package:mediatech/providers/auth_provider.dart';

class UserLoansPage extends ConsumerStatefulWidget {
  const UserLoansPage({super.key});

  @override
  ConsumerState<UserLoansPage> createState() => _UserLoansPageState();
}

class _UserLoansPageState extends ConsumerState<UserLoansPage> {
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
  static const Color _infoColor = Color(0xFF17A2B8);

  @override
  void initState() {
    super.initState();
    // Load data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanControllerProvider.notifier).loadAllData();
      ref.read(mediaControllerProvider.notifier).loadMedia();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider).value;
    final loanState = ref.watch(loanControllerProvider);
    final mediaState = ref.watch(mediaControllerProvider);

    if (appUser == null) {
      return _buildUnauthorizedView();
    }

    if (loanState.loading || mediaState.loading) {
      return _buildLoading();
    }

    // Process data for current user with proper logic
    final userLoans = loanState.loans.where((loan) => 
      loan.userId == appUser.uid && loan.returnedAt == null
    ).toList();

    final userReservations = loanState.reservations.where((res) => 
      res.userId == appUser.uid
    ).toList();

    final pendingReservations = userReservations.where((res) => !res.approved).toList();
    
    // Get completed loans (returned items) for history
    final completedLoans = loanState.loans.where((loan) => 
      loan.userId == appUser.uid && loan.returnedAt != null
    ).toList();

    // Filter data
    final filteredLoans = _filterLoans(userLoans, mediaState.media);
    final filteredPendingReservations = _filterReservations(pendingReservations, mediaState.media);
    final filteredCompletedLoans = _filterLoans(completedLoans, mediaState.media);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Emprunts & Réservations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(userLoans, pendingReservations, completedLoans),
          
          // Tabs
          _buildTabBar(),
          
          // Search
          _buildSearchBar(),
          
          // Content
          Expanded(
            child: _buildContent(
              filteredLoans,
              filteredPendingReservations,
              filteredCompletedLoans,
              mediaState.media,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Emprunts'),
        backgroundColor: _primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour voir vos emprunts',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildLoading() => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF7B1F2D),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Chargement...",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatsOverview(
    List<LoanModel> loans, 
    List<ReservationModel> pendingReservations,
    List<LoanModel> completedLoans,
  ) {
    final overdueCount = loans.where((loan) => loan.dueDate.toDate().isBefore(DateTime.now())).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: loans.length.toString(),
            label: 'Emprunts',
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
            value: completedLoans.length.toString(),
            label: 'Historique',
            color: _infoColor,
            icon: Icons.history,
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
            label: 'Mes Emprunts',
            isSelected: _currentTab == 0,
            onTap: () => setState(() => _currentTab = 0),
          ),
          _TabItem(
            label: 'En Attente',
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
          hintText: 'Rechercher par titre, auteur...',
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
    List<LoanModel> loans,
    List<ReservationModel> pendingReservations,
    List<LoanModel> completedLoans,
    List<MediaModel> mediaList,
  ) {
    switch (_currentTab) {
      case 0:
        return _LoansSection(
          loans: loans,
          mediaList: mediaList,
          onExtend: _extendLoan,
        );
      case 1:
        return _PendingReservationsSection(
          reservations: pendingReservations,
          mediaList: mediaList,
          onCancel: _cancelReservation,
        );
      case 2:
        return _HistorySection(
          loans: completedLoans,
          mediaList: mediaList,
        );
      default:
        return const SizedBox();
    }
  }

  // Filter methods
  List<LoanModel> _filterLoans(List<LoanModel> loans, List<MediaModel> mediaList) {
    if (_searchQuery.isEmpty) return loans;
    
    return loans.where((loan) {
      final media = _getMediaForLoan(loan, mediaList);
      return media.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.genre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ReservationModel> _filterReservations(List<ReservationModel> reservations, List<MediaModel> mediaList) {
    if (_searchQuery.isEmpty) return reservations;
    
    return reservations.where((res) {
      final media = _getMediaForReservation(res, mediaList);
      return media.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             media.genre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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

  // Actions
  Future<void> _extendLoan(LoanModel loan) async {
    final success = await ref.read(loanControllerProvider.notifier).extendLoan(loan);
    if (context.mounted) {
      _showSnackbar(
        success ? '✅ Emprunt prolongé avec succès' : '❌ Échec de la prolongation',
        success ? _successColor : _errorColor,
      );
    }
  }

  Future<void> _cancelReservation(ReservationModel reservation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _errorColor),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref.read(loanControllerProvider.notifier).cancelReservation(reservation);
      if (context.mounted) {
        _showSnackbar(
          success ? '✅ Réservation annulée' : '❌ Échec de l\'annulation',
          success ? _successColor : _errorColor,
        );
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ========== SECTION COMPONENTS ==========

class _LoansSection extends StatelessWidget {
  final List<LoanModel> loans;
  final List<MediaModel> mediaList;
  final Function(LoanModel) onExtend;

  const _LoansSection({
    required this.loans,
    required this.mediaList,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return _EmptyState(
        icon: Icons.library_books,
        title: 'Aucun emprunt actif',
        subtitle: 'Vos emprunts en cours apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        final media = _getMediaForLoan(loan, mediaList);
        
        return _LoanCard(
          loan: loan,
          media: media,
          onExtend: () => onExtend(loan),
        );
      },
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
}

class _PendingReservationsSection extends ConsumerWidget {
  final List<ReservationModel> reservations;
  final List<MediaModel> mediaList;
  final Function(ReservationModel) onCancel;

  const _PendingReservationsSection({
    required this.reservations,
    required this.mediaList,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reservations.isEmpty) {
      return _EmptyState(
        icon: Icons.hourglass_empty,
        title: 'Aucune réservation en attente',
        subtitle: 'Vos réservations en file d\'attente apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        final media = _getMediaForReservation(reservation, mediaList);
        final queuePosition = _calculateQueuePosition(reservation, ref);
        
        return _PendingReservationCard(
          reservation: reservation,
          media: media,
          queuePosition: queuePosition,
          onCancel: () => onCancel(reservation),
        );
      },
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

  int _calculateQueuePosition(ReservationModel reservation, WidgetRef ref) {
    final loanState = ref.read(loanControllerProvider);
    final queue = loanState.reservations
        .where((r) => r.mediaId == reservation.mediaId && !r.approved)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return queue.indexWhere((r) => r.id == reservation.id) + 1;
  }
}

class _HistorySection extends StatelessWidget {
  final List<LoanModel> loans;
  final List<MediaModel> mediaList;

  const _HistorySection({
    required this.loans,
    required this.mediaList,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: 'Aucun historique',
        subtitle: 'Votre historique d\'emprunts apparaîtra ici',
      );
    }

    // Sort by returned date (most recent first)
    final sortedLoans = loans.toList()
      ..sort((a, b) => b.returnedAt!.compareTo(a.returnedAt!));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedLoans.length,
      itemBuilder: (context, index) {
        final loan = sortedLoans[index];
        final media = _getMediaForLoan(loan, mediaList);
        
        return _HistoryCard(
          loan: loan,
          media: media,
        );
      },
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
}

// ========== CARD COMPONENTS ==========

class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  final MediaModel media;
  final VoidCallback onExtend;

  const _LoanCard({
    required this.loan,
    required this.media,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = loan.dueDate.toDate();
    final isOverdue = dueDate.isBefore(DateTime.now());
    final canExtend = !loan.extended && !isOverdue;
    final daysRemaining = dueDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                _StatusChip(
                  text: isOverdue ? 'EN RETARD' : 'EMPRUNT EN COURS',
                  color: isOverdue ? _UserLoansPageState._errorColor : _UserLoansPageState._secondaryColor,
                ),
                const Spacer(),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _UserLoansPageState._errorColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'RETARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  child: media.coverUrl.isEmpty 
                      ? const Icon(Icons.book, color: Colors.grey)
                      : null,
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
            
            // Due Date Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverdue ? _UserLoansPageState._errorColor.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOverdue ? _UserLoansPageState._errorColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue ? _UserLoansPageState._errorColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOverdue ? 'En retard depuis le ${_formatDate(dueDate)}' : 'À retourner le ${_formatDate(dueDate)}',
                          style: TextStyle(
                            color: isOverdue ? _UserLoansPageState._errorColor : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isOverdue) ...[
                          const SizedBox(height: 2),
                          Text(
                            daysRemaining == 0 
                                ? 'À rendre aujourd\'hui'
                                : daysRemaining == 1
                                    ? '1 jour restant'
                                    : '$daysRemaining jours restants',
                            style: TextStyle(
                              color: daysRemaining <= 3 ? _UserLoansPageState._warningColor : _UserLoansPageState._successColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Loan Period Info
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _UserLoansPageState._infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _UserLoansPageState._infoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: _UserLoansPageState._infoColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emprunté du ${_formatDate(loan.borrowedAt.toDate())} au ${_formatDate(dueDate)}',
                      style: TextStyle(
                        color: _UserLoansPageState._infoColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    text: loan.extended ? 'Déjà prolongé' : 'Prolonger',
                    icon: Icons.update_rounded,
                    color: _UserLoansPageState._warningColor,
                    onTap: canExtend ? onExtend : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final MediaModel media;
  final int queuePosition;
  final VoidCallback onCancel;

  const _PendingReservationCard({
    required this.reservation,
    required this.media,
    required this.queuePosition,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with queue info
            Row(
              children: [
                _StatusChip(
                  text: 'EN ATTENTE',
                  color: _UserLoansPageState._warningColor,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _UserLoansPageState._primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Position #$queuePosition',
                    style: TextStyle(
                      color: _UserLoansPageState._primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                  child: media.coverUrl.isEmpty 
                      ? const Icon(Icons.book, color: Colors.grey)
                      : null,
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
            
            // Queue Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_alt_rounded, size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous êtes position $queuePosition dans la file d\'attente',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 4),
            Text(
              'Réservé le ${_formatDateWithTime(reservation.createdAt.toDate())}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            
            // Action
            const SizedBox(height: 12),
            _ActionButton(
              text: 'Annuler la réservation',
              icon: Icons.cancel_rounded,
              color: _UserLoansPageState._errorColor,
              onTap: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final LoanModel loan;
  final MediaModel media;

  const _HistoryCard({
    required this.loan,
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
    final loanDate = loan.borrowedAt.toDate();
    final dueDate = loan.dueDate.toDate();
    final returnedDate = loan.returnedAt!.toDate();
    final wasOverdue = returnedDate.isAfter(dueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _StatusChip(
                  text: wasOverdue ? 'RENDU EN RETARD' : 'RENDU',
                  color: wasOverdue ? _UserLoansPageState._errorColor : _UserLoansPageState._successColor,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _UserLoansPageState._infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TERMINÉ',
                    style: TextStyle(
                      color: Color(0xFF17A2B8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                  child: media.coverUrl.isEmpty 
                      ? const Icon(Icons.book, color: Colors.grey)
                      : null,
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
            
            // Loan Period Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _UserLoansPageState._infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _UserLoansPageState._infoColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: _UserLoansPageState._infoColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Période d\'emprunt: ${_formatDate(loanDate)} - ${_formatDate(returnedDate)}',
                          style: TextStyle(
                            color: _UserLoansPageState._infoColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 24), // Align with icon above
                      Expanded(
                        child: Text(
                          'Durée: ${returnedDate.difference(loanDate).inDays} jours',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Return Info
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: wasOverdue ? _UserLoansPageState._errorColor.withOpacity(0.1) : _UserLoansPageState._successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: wasOverdue ? _UserLoansPageState._errorColor.withOpacity(0.3) : _UserLoansPageState._successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    wasOverdue ? Icons.warning : Icons.check_circle,
                    size: 16,
                    color: wasOverdue ? _UserLoansPageState._errorColor : _UserLoansPageState._successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wasOverdue 
                          ? 'Rendu le ${_formatDate(returnedDate)} (${returnedDate.difference(dueDate).inDays} jours de retard)'
                          : 'Rendu le ${_formatDate(returnedDate)}',
                      style: TextStyle(
                        color: wasOverdue ? _UserLoansPageState._errorColor : _UserLoansPageState._successColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
        color: isSelected ? _UserLoansPageState._primaryColor.withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? _UserLoansPageState._primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _UserLoansPageState._primaryColor : Colors.grey,
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
  final VoidCallback? onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(text),
        ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
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
    );
  }
}

// Helper functions
String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateWithTime(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}