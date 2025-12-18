import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String mediaId;
  final String userId;

  final Timestamp createdAt;
  final bool approved;

  ReservationModel({
    required this.id,
    required this.mediaId,
    required this.userId,
  
    required this.createdAt,
    this.approved = false,
  });

  factory ReservationModel.fromMap(String id, Map<String, dynamic> data) {
    return ReservationModel(
      id: id,
      mediaId: data['mediaId'],
      userId: data['userId'],
  
      createdAt: data['createdAt'],
      approved: data['approved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mediaId': mediaId,
      'userId': userId,
    
      'createdAt': createdAt,
      'approved': approved,
    };
  }
}
