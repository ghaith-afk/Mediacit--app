import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/loan_controller.dart';
import 'package:mediatech/Controllers/media_controller.dart';
import 'package:mediatech/models/loan_model.dart';
import 'package:mediatech/models/media_model.dart';
import 'package:mediatech/models/reservation_media_model.dart';
import 'package:mediatech/providers/auth_provider.dart';

class MediaDetailPage extends ConsumerStatefulWidget {
  final MediaModel media;
  const MediaDetailPage({super.key, required this.media});

  @override
  ConsumerState<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends ConsumerState<MediaDetailPage> {
  @override
  void initState() {
    super.initState();
    // Refresh data when page loads
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this page
    _refreshData();
  }

  void _refreshData() {
    // Force reload of data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanControllerProvider.notifier).loadAllData();
      ref.read(mediaControllerProvider.notifier).loadMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(appUserProvider);
    final loanState = ref.watch(loanControllerProvider);
    final mediaState = ref.watch(mediaControllerProvider);

    return appUserAsync.when(
      data: (appUser) {
        if (appUser == null) {
          return _buildUnauthorizedView(context);
        }
        return _buildPage(context, ref, loanState, appUser.uid);
      },
      loading: () => _buildLoadingView(),
      error: (e, st) => _buildErrorView(context, e),
    );
  }

  Widget _buildUnauthorizedView(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Connexion requise",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Connectez-vous pour accéder aux détails",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Retour"),
              ),
            ],
          ),
        ),
      );

  Widget _buildLoadingView() => Scaffold(
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

  Widget _buildErrorView(BuildContext context, Object error) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                "Une erreur est survenue",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                ),
                child: const Text("Retour"),
              ),
            ],
          ),
        ),
      );

  Widget _buildPage(
      BuildContext context, WidgetRef ref, LoanState loanState, String userId) {
    
    // DEBUG: Print current state
    _debugState(loanState, userId);

    final userLoanIter = loanState.loans.where(
      (l) => l.userId == userId && l.mediaId == widget.media.id,
    );
    final LoanModel? userLoan =
        userLoanIter.isNotEmpty ? userLoanIter.first : null;

    final reservationIter = loanState.reservations.where(
      (r) => r.userId == userId && r.mediaId == widget.media.id,
    );
    final ReservationModel? userReservation =
        reservationIter.isNotEmpty ? reservationIter.first : null;

    // FIXED: Only count PENDING reservations for queue calculation
    final pendingQueue = loanState.reservations
        .where((r) => r.mediaId == widget.media.id && r.approved==false)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // FIXED: Better queue position calculation using ID comparison
    final int? queuePosition = userReservation != null && userReservation.approved == false
        ? _calculateQueuePosition(userId, pendingQueue)
        : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Détails du média",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color.fromARGB(167, 138, 0, 21),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with cover image
            _buildMediaHeader(context),
            
            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaInfo(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildActionSection(
                    context: context,
                    ref: ref,
                    userLoan: userLoan,
                    userReservation: userReservation,
                    userId: userId,
                    queuePosition: queuePosition,
                  ),
                  if (pendingQueue.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildQueueSection(context, pendingQueue, userId, ref),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DEBUG method to see what's happening
  void _debugState(LoanState loanState, String userId) {
    final userReservations = loanState.reservations.where((r) => 
      r.userId == userId && r.mediaId == widget.media.id
    ).toList();
    
    final pendingQueue = loanState.reservations.where((r) => 
      r.mediaId == widget.media.id && r.approved == false
    ).toList();

    print('🔍 MediaDetailPage DEBUG:');
    print('   User ID: $userId');
    print('   Media ID: ${widget.media.id}');
    print('   User reservations: ${userReservations.length}');
    print('   Pending queue: ${pendingQueue.length}');
    print('   User in queue: ${userReservations.any((r) => !r.approved)}');
  }

  // FIXED: Better queue position calculation
  int _calculateQueuePosition(String userId, List<ReservationModel> queue) {
    for (int i = 0; i < queue.length; i++) {
      if (queue[i].userId == userId) {
        return i + 1;
      }
    }
    return -1;
  }

  // Header Section
  Widget _buildMediaHeader(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7B1F2D),
            Color.fromARGB(221, 122, 40, 54),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background blur effect
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                widget.media.coverUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Content
          Center(
            child: Container(
              width: 180,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.media.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Media Information
  Widget _buildMediaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.media.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.media.author,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getAvailabilityColor(widget.media.availableCount).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getAvailabilityColor(widget.media.availableCount).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.media.availableCount > 0 ? Icons.check_circle : Icons.schedule,
                color: _getAvailabilityColor(widget.media.availableCount),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "${widget.media.availableCount}/${widget.media.totalCount} disponible(s)",
                style: TextStyle(
                  color: _getAvailabilityColor(widget.media.availableCount),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAvailabilityColor(int availableCount) {
    if (availableCount > 0) return Colors.green.shade600;
    return Colors.orange.shade600;
  }

  // Description
  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.media.description,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Action Buttons Section
  Widget _buildActionSection({
    required BuildContext context,
    required WidgetRef ref,
    required LoanModel? userLoan,
    required ReservationModel? userReservation,
    required String userId,
    required int? queuePosition,
  }) {
    // User has an active loan
    if (userLoan != null && userLoan.returnedAt == null) {
      return _buildLoanManagementSection(context, ref, userLoan);
    }

    // User has a pending reservation
    if (userReservation != null && userReservation.approved==false) {
      return _buildPendingReservationSection(
        context: context,
        ref: ref,
        userReservation: userReservation,
        queuePosition: queuePosition,
      );
    }

    // Media is available
    if (widget.media.availableCount > 0) {
      return _buildReservationButton(
        context: context,
        ref: ref,
        userId: userId,
        label: "Réserver maintenant",
        icon: Icons.event_available_rounded,
        color: Colors.green.shade600,
        isDisabled: false,
      );
    }

    // Media is unavailable - show queue options
    return _buildQueueSectionWithAction(
      context: context,
      ref: ref,
      userId: userId,
      userReservation: userReservation,
      queuePosition: queuePosition,
    );
  }

  Widget _buildLoanManagementSection(
      BuildContext context, WidgetRef ref, LoanModel userLoan) {
    final dueDate = userLoan.dueDate.toDate();
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_books_rounded, color: Colors.blueAccent.shade700),
              const SizedBox(width: 8),
              Text(
                "Emprunt en cours",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Date de retour : ${_formatDate(dueDate)}",
            style: TextStyle(
              color: isOverdue ? Colors.red.shade600 : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isOverdue) ...[
            const SizedBox(height: 4),
            Text(
              "En retard",
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
     
        ],
      ),
    );
  }

  Widget _buildPendingReservationSection({
    required BuildContext context,
    required WidgetRef ref,
    required ReservationModel userReservation,
    required int? queuePosition,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                "En file d'attente",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Vous êtes en position $queuePosition dans la file d'attente",
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 78, 70, 70),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded),
                      SizedBox(width: 8),
                      Text("Déjà en file"),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _leaveQueue(context, ref, userReservation),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade600),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        "Quitter",
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationButton({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String label,
    required IconData icon,
    required Color color,
    bool isDisabled = false,
  }) {
    return FilledButton(
      onPressed: isDisabled ? null : () => _openReservationModal(context, ref, userId),
      style: FilledButton.styleFrom(
        backgroundColor: isDisabled ? Colors.grey.shade400 : color,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            isDisabled ? "Déjà en file d'attente" : label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSectionWithAction({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required ReservationModel? userReservation,
    required int? queuePosition,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                "File d'attente",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (userReservation != null && userReservation.approved==false) ...[
            Text(
              "Vous êtes en position $queuePosition dans la file d'attente",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded),
                        SizedBox(width: 8),
                        Text("Déjà en file d'attente"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _leaveQueue(context, ref, userReservation),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.red.shade600),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Quitter",
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              "Ce média n'est pas disponible pour le moment",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildReservationButton(
              context: context,
              ref: ref,
              userId: userId,
              label: "Rejoindre la file d'attente",
              icon: Icons.hourglass_bottom_rounded,
              color: Colors.orange.shade600,
              isDisabled: false,
            ),
          ],
        ],
      ),
    );
  }

  // Queue Section
  Widget _buildQueueSection(BuildContext context, List<ReservationModel> queue, String userId, WidgetRef ref) {
    final userReservation = queue.firstWhere(
      (r) => r.userId == userId,
      orElse: () => ReservationModel(id: '', mediaId: '', userId: '', createdAt: Timestamp.now(), approved: false),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_rounded, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                "File d'attente (${queue.length})",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...queue.asMap().entries.map((entry) {
            final index = entry.key;
            final reservation = entry.value;
            final isCurrentUser = reservation.userId == userId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color.fromARGB(255, 246, 231, 231)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentUser
                      ? const Color.fromARGB(255, 233, 196, 199)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ?  Color.fromARGB(255, 114, 24, 38)
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCurrentUser
                          ? "Vous (Position ${index + 1})"
                          : "Utilisateur ${index + 1}",
                      style: TextStyle(
                        fontWeight: isCurrentUser
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isCurrentUser
                            ? Color.fromARGB(255, 131, 15, 32)
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  if (isCurrentUser) ...[
                    IconButton(
                      icon: Icon(Icons.exit_to_app, color: Color.fromARGB(255, 114, 24, 38)),
                      onPressed: () => _leaveQueue(context, ref, reservation),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.person_rounded,
                      color: Color.fromARGB(255, 114, 24, 38),
                      size: 16,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper Methods

  Future<void> _extendLoan(
      BuildContext context, WidgetRef ref, LoanModel userLoan) async {
    await ref.read(loanControllerProvider.notifier).extendLoan(userLoan);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Emprunt prolongé avec succès"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _leaveQueue(BuildContext context, WidgetRef ref, ReservationModel reservation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quitter la file d'attente"),
        content: const Text("Êtes-vous sûr de vouloir quitter la file d'attente ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text("Quitter"),
          ),
        ],
      ),
    );

    if (result == true) {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 10),
              Text('Annulation en cours...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );

      final success = await ref.read(loanControllerProvider.notifier).cancelReservation(reservation);
      
      // Hide loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Vous avez quitté la file d'attente"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Force immediate refresh
        _refreshData();
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // MODAL
  Future<void> _openReservationModal(BuildContext context, WidgetRef ref, String userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.queue, color: Color.fromARGB(255, 133, 29, 45)),
                      const SizedBox(width: 8),
                      Text(
                        "Rejoindre la file d'attente",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Demandez à réserver ce média",
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Media Info
                  _buildModalMediaInfo(),
                  const SizedBox(height: 20),

                  // Queue Information
                  _buildModalQueueInfo(ref, userId),
                  const SizedBox(height: 20),

                  // Instructions
                  _buildModalInstructions(),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Annuler"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _joinQueueFromModal(context, ref, userId),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Rejoindre la file"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalMediaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Media Cover
          Container(
            width: 50,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: widget.media.coverUrl.isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage(widget.media.coverUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
            ),
            child: widget.media.coverUrl.isEmpty 
                ? const Icon(Icons.book, color: Colors.grey, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.media.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.media.author,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (widget.media.genre.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Genre: ${widget.media.genre}",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalQueueInfo(WidgetRef ref, String userId) {
    final loanState = ref.watch(loanControllerProvider);
    
    final pendingQueue = loanState.reservations
        .where((r) => r.mediaId == widget.media.id && r.approved==false)
        .toList();

    final userInQueue = pendingQueue.any((r) => r.userId == userId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "File d'attente actuelle",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                    fontSize: 14,
                ),
                ),
                const SizedBox(height: 2),
                Text(
                  pendingQueue.isEmpty 
                      ? 'Aucune personne en attente'
                      : '${pendingQueue.length} personne${pendingQueue.length > 1 ? 's' : ''} dans la file',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 13,
                  ),
                ),
                if (pendingQueue.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${pendingQueue.length} personne${pendingQueue.length > 1 ? 's' : ''} devant vous',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  userInQueue 
                      ? 'Vous êtes déjà dans la file'
                      : 'Votre position sera: #${pendingQueue.length + 1}',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                "Comment ça marche",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModalInstructionItem("1. Rejoignez la file d'attente"),
          _buildModalInstructionItem("2. Attendez votre tour"),
          _buildModalInstructionItem("3. Récupérez votre media"),
        ],
      ),
    );
  }

  Widget _buildModalInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinQueueFromModal(BuildContext context, WidgetRef ref, String userId) async {
    try {
      final success = await ref.read(loanControllerProvider.notifier).reserveMedia(userId, widget.media.id);
      
      if (context.mounted && success) {
        Navigator.pop(context);
        
        // Force refresh to get updated state
        _refreshData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Vous avez rejoint la file d\'attente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = "Erreur lors de la réservation";
        
        if (e.toString().contains('emprunt actif')) {
          errorMessage = "Vous avez déjà un emprunt actif pour ce média";
        } else if (e.toString().contains('file d\'attente')) {
          errorMessage = "Vous êtes déjà dans la file d'attente pour ce média";
        } else if (e.toString().contains('Limite d\'emprunts')) {
          errorMessage = "Limite d'emprunts simultanés atteinte";
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}