import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id;
  final String userId;
  final String mediaId;
  final Timestamp borrowedAt;
  final Timestamp dueDate;
  final Timestamp? returnedAt;
  final bool extended;

  LoanModel({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    this.extended = false,
  });

  factory LoanModel.fromMap(String id, Map<String, dynamic> data) {
    return LoanModel(
      id: id,
      userId: data['userId'],
      mediaId: data['mediaId'],
      borrowedAt: data['borrowedAt'],
      dueDate: data['dueDate'],
      returnedAt: data['returnedAt'],
      extended: data['extended'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaId': mediaId,
      'borrowedAt': borrowedAt,
      'dueDate': dueDate,
      'returnedAt': returnedAt,
      'extended': extended,
    };
  }
}
