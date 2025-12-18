// controllers/loan_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediatech/models/loan_model.dart';
import 'package:mediatech/models/reservation_media_model.dart';

class LoanState {
  final List<LoanModel> loans;
  final List<ReservationModel> reservations;
  final bool loading;
  final String? error;

  LoanState({
    required this.loans,
    required this.reservations,
    this.loading = false,
    this.error,
  });

  LoanState copyWith({
    List<LoanModel>? loans,
    List<ReservationModel>? reservations,
    bool? loading,
    String? error,
  }) {
    return LoanState(
      loans: loans ?? this.loans,
      reservations: reservations ?? this.reservations,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class LoanController extends StateNotifier<LoanState> {
  final FirebaseFirestore _firestore;
  static const int MAX_CONCURRENT_LOANS = 2;
  static const int LOAN_DURATION_DAYS = 14;
  static const int EXTENSION_DAYS = 7;
  static const int MAX_RESERVATION_DAYS = 30;

  LoanController(this._firestore) : super(LoanState(loans: [], reservations: [])) {
    loadAllData();
  }

  // Load all data
  Future<void> loadAllData() async {
    try {
      state = state.copyWith(loading: true);
      
      final loansSnapshot = await _firestore.collection('loans').get();
      final reservationsSnapshot = await _firestore.collection('reservations').get();

      final loans = loansSnapshot.docs.map((doc) {
        return LoanModel.fromMap(doc.id, doc.data());
      }).toList();

      final reservations = reservationsSnapshot.docs.map((doc) {
        return ReservationModel.fromMap(doc.id, doc.data());
      }).toList();

      state = state.copyWith(
        loans: loans,
        reservations: reservations,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  // VALIDATION METHODS
  bool _hasActiveLoan(String userId, String mediaId) {
    return state.loans.any((loan) => 
      loan.userId == userId && 
      loan.mediaId == mediaId && 
      loan.returnedAt == null
    );
  }

  bool _hasPendingReservation(String userId, String mediaId) {
    return state.reservations.any((res) => 
      res.userId == userId && 
      res.mediaId == mediaId && 
      res.approved == false
    );
  }


  int _getUserActiveLoansCount(String userId) {
    return state.loans.where((loan) => 
      loan.userId == userId && loan.returnedAt == null
    ).length;
  }

  // FIXED: Comprehensive validation for reservations
  String? _validateReservation(String userId, String mediaId) {
    // Check for active loan - user cannot reserve if they already have an active loan
    if (_hasActiveLoan(userId, mediaId)) {
      return 'Vous avez déjà un emprunt actif pour ce média';
    }

    // Check for pending reservation - user cannot reserve if already in queue
    if (_hasPendingReservation(userId, mediaId)) {
      return 'Vous êtes déjà dans la file d\'attente pour ce média';
    }

    // REMOVED: Don't check for approved reservations
    // Users can have approved reservations that get converted to loans
    // Once the loan ends, they should be able to reserve again
    // if (_hasApprovedReservation(userId, mediaId)) {
    //   return 'Vous avez déjà une réservation approuvée pour ce média';
    // }

    // Check loan limit - user cannot reserve if they have max active loans
    if (_getUserActiveLoansCount(userId) >= MAX_CONCURRENT_LOANS) {
      return 'Limite d\'emprunts simultanés atteinte ($MAX_CONCURRENT_LOANS)';
    }

    return null; // No errors
  }

  // RESERVATION METHODS
  Future<bool> reserveMedia(String userId, String mediaId) async {
    try {
      // Validate reservation
      final validationError = _validateReservation(userId, mediaId);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Create reservation
      final reservation = ReservationModel(
        id: _firestore.collection('reservations').doc().id,
        mediaId: mediaId,
        userId: userId,
        createdAt: Timestamp.now(),
        approved: false,
      );

      await _firestore.collection('reservations').doc(reservation.id).set(reservation.toMap());
      
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // QR CODE / BARCODE METHODS
  Future<bool> borrowMediaWithScan(String userId, String mediaId, String qrCode) async {
    try {
      // Verify QR code matches media
      final mediaDoc = await _firestore.collection('media').doc(mediaId).get();
      if (!mediaDoc.exists) {
        throw Exception('Média non trouvé');
      }

      final mediaData = mediaDoc.data()!;
      final availableCount = mediaData['availableCount'] ?? 0;
      
      if (availableCount <= 0) {
        throw Exception('Plus d\'exemplaires disponibles');
      }

      // Check user can borrow
      if (_getUserActiveLoansCount(userId) >= MAX_CONCURRENT_LOANS) {
        throw Exception('Limite d\'emprunts atteinte');
      }

      if (_hasActiveLoan(userId, mediaId)) {
        throw Exception('Vous avez déjà emprunté ce média');
      }

      // Create loan directly (bypass reservation for direct scan)
      final loan = LoanModel(
        id: _firestore.collection('loans').doc().id,
        userId: userId,
        mediaId: mediaId,
        borrowedAt: Timestamp.now(),
        dueDate: Timestamp.fromDate(DateTime.now().add(Duration(days: LOAN_DURATION_DAYS))),
        extended: false,
      );

      final batch = _firestore.batch();
      
      // Create loan
      batch.set(_firestore.collection('loans').doc(loan.id), loan.toMap());
      
      // Update media availability
      batch.update(_firestore.collection('media').doc(mediaId), {
        'availableCount': availableCount - 1
      });

      await batch.commit();
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> returnMediaWithScan(String loanId, String qrCode) async {
    try {
      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      if (!loanDoc.exists) {
        throw Exception('Emprunt non trouvé');
      }

      final loan = LoanModel.fromMap(loanId, loanDoc.data()!);
      
      if (loan.returnedAt != null) {
        throw Exception('Ce média a déjà été retourné');
      }

      return await returnLoan(loan);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // LOAN MANAGEMENT
  Future<bool> returnLoan(LoanModel loan) async {
    final batch = _firestore.batch();
    
    try {
      // Mark loan as returned
      batch.update(
        _firestore.collection('loans').doc(loan.id),
        {'returnedAt': Timestamp.now()}
      );

      // Increase available count
      final mediaDoc = await _firestore.collection('media').doc(loan.mediaId).get();
      if (mediaDoc.exists) {
        final mediaData = mediaDoc.data()!;
        final availableCount = mediaData['availableCount'] ?? 0;
        
        batch.update(
          _firestore.collection('media').doc(loan.mediaId),
          {'availableCount': availableCount + 1}
        );
      }

      // FIXED: No auto-approval when returning a loan
      // The next reservation should stay in queue until manually approved
      // This prevents automatic loan creation without admin approval

      await batch.commit();
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> extendLoan(LoanModel loan) async {
    try {
      if (loan.extended) {
        throw Exception('Emprunt déjà prolongé');
      }

      if (loan.returnedAt != null) {
        throw Exception('Emprunt déjà retourné');
      }

      // Check if extension is possible (no pending reservations)
      final hasPendingReservations = state.reservations.any((res) => 
        res.mediaId == loan.mediaId && res.approved==false
      );

      if (hasPendingReservations) {
        throw Exception('Impossible de prolonger - réservations en attente');
      }

      // Check if loan is overdue
      if (loan.dueDate.toDate().isBefore(DateTime.now())) {
        throw Exception('Impossible de prolonger un emprunt en retard');
      }

      final newDueDate = loan.dueDate.toDate().add(Duration(days: EXTENSION_DAYS));
      
      await _firestore.collection('loans').doc(loan.id).update({
        'dueDate': Timestamp.fromDate(newDueDate),
        'extended': true,
      });

      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // RESERVATION MANAGEMENT
  Future<bool> approveReservation(ReservationModel reservation) async {
    final batch = _firestore.batch();
    
    try {
      final mediaDoc = await _firestore.collection('media').doc(reservation.mediaId).get();
      if (!mediaDoc.exists) {
        throw Exception('Média non trouvé');
      }

      final mediaData = mediaDoc.data()!;
      final availableCount = mediaData['availableCount'] ?? 0;
      
      if (availableCount <= 0) {
        throw Exception('Plus d\'exemplaires disponibles');
      }

      // Check if user can still borrow
      if (_getUserActiveLoansCount(reservation.userId) >= MAX_CONCURRENT_LOANS) {
        throw Exception('Utilisateur a atteint la limite d\'emprunts');
      }

      // Check if user already has an active loan for this media
      if (_hasActiveLoan(reservation.userId, reservation.mediaId)) {
        throw Exception('Utilisateur a déjà un emprunt actif pour ce média');
      }

      // FIXED: When approving reservation, immediately create a loan and pick the media
      final loan = LoanModel(
        id: _firestore.collection('loans').doc().id,
        userId: reservation.userId,
        mediaId: reservation.mediaId,
        borrowedAt: Timestamp.now(),
        dueDate: Timestamp.fromDate(DateTime.now().add(Duration(days: LOAN_DURATION_DAYS))),
        extended: false,
      );

      // Update reservation as approved
      batch.update(
        _firestore.collection('reservations').doc(reservation.id),
        {'approved': true}
      );

      // Create loan immediately
      batch.set(_firestore.collection('loans').doc(loan.id), loan.toMap());

      // Update media availability (pick the media)
      batch.update(
        _firestore.collection('media').doc(reservation.mediaId),
        {'availableCount': availableCount - 1}
      );

      await batch.commit();
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

 Future<bool> cancelReservation(ReservationModel reservation) async {
  try {
    await _firestore.collection('reservations').doc(reservation.id).delete();
    
    // IMMEDIATELY update local state instead of waiting for loadAllData
    final updatedReservations = List<ReservationModel>.from(state.reservations)
      ..removeWhere((res) => res.id == reservation.id);
    
    state = state.copyWith(reservations: updatedReservations);
    
    // Optional: Still reload for complete sync
    await loadAllData();
    return true;
  } catch (e) {
    state = state.copyWith(error: e.toString());
    return false;
  }
}

Future<bool> rejectReservation(ReservationModel reservation) async {
  try {
    await _firestore.collection('reservations').doc(reservation.id).delete();
    
    // IMMEDIATELY update local state
    final updatedReservations = List<ReservationModel>.from(state.reservations)
      ..removeWhere((res) => res.id == reservation.id);
    
    state = state.copyWith(reservations: updatedReservations);
    
    await loadAllData();
    return true;
  } catch (e) {
    state = state.copyWith(error: e.toString());
    return false;
  }
}

  // NOTIFICATION METHODS
  List<LoanModel> getOverdueLoans() {
    final now = DateTime.now();
    return state.loans.where((loan) => 
      loan.returnedAt == null && 
      loan.dueDate.toDate().isBefore(now)
    ).toList();
  }

  List<LoanModel> getLoansDueSoon() {
    final now = DateTime.now();
    final soon = now.add(Duration(days: 2)); // Notify 2 days before due date
    return state.loans.where((loan) => 
      loan.returnedAt == null && 
      loan.dueDate.toDate().isAfter(now) &&
      loan.dueDate.toDate().isBefore(soon)
    ).toList();
  }

  // QUEUE MANAGEMENT
  int getQueuePosition(String mediaId, String userId) {
    final queue = state.reservations.where((res) => 
      res.mediaId == mediaId && res.approved==false
    ).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    final userIndex = queue.indexWhere((res) => res.userId == userId);
    return userIndex >= 0 ? userIndex + 1 : -1;
  }

  // USER STATUS
  Map<String, dynamic> getUserMediaStatus(String userId, String mediaId) {
    final activeLoan = state.loans.firstWhere(
      (loan) => loan.userId == userId && loan.mediaId == mediaId && loan.returnedAt == null,
      orElse: () => LoanModel(
        id: '',
        userId: '',
        mediaId: '',
        borrowedAt: Timestamp.now(),
        dueDate: Timestamp.now(),
        extended: false,
      ),
    );

    final pendingReservation = state.reservations.firstWhere(
      (res) => res.userId == userId && res.mediaId == mediaId && res.approved == false,
      orElse: () => ReservationModel(
        id: '',
        mediaId: '',
        userId: '',
        createdAt: Timestamp.now(),
        approved: false,
      ),
    );

    final approvedReservation = state.reservations.firstWhere(
      (res) => res.userId == userId && res.mediaId == mediaId && res.approved,
      orElse: () => ReservationModel(
        id: '',
        mediaId: '',
        userId: '',
        createdAt: Timestamp.now(),
        approved: false,
      ),
    );

    return {
      'hasActiveLoan': activeLoan.id.isNotEmpty,
      'hasPendingReservation': pendingReservation.id.isNotEmpty,
      'hasApprovedReservation': approvedReservation.id.isNotEmpty,
      'activeLoan': activeLoan.id.isNotEmpty ? activeLoan : null,
      'pendingReservation': pendingReservation.id.isNotEmpty ? pendingReservation : null,
      'approvedReservation': approvedReservation.id.isNotEmpty ? approvedReservation : null,
      'canBorrow': _getUserActiveLoansCount(userId) < MAX_CONCURRENT_LOANS,
    };
  }
}

final loanControllerProvider = StateNotifierProvider<LoanController, LoanState>((ref) {
  return LoanController(FirebaseFirestore.instance);
});