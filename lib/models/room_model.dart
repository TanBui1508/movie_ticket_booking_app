import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String? id;
  final String cinemaId;
  final String name;
  final List<int> seatMap; 
  final int totalSeats;
  final String screenType;
  final bool isActive;
  final DateTime createdAt;

  Room({
    this.id,
    required this.cinemaId,
    required this.name,
    required this.seatMap,
    required this.totalSeats,
    required this.screenType,
    required this.isActive,
    required this.createdAt,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      cinemaId: data['cinemaId'] ?? '',
      name: data['name'] ?? '',
      seatMap: List<int>.from(data['seatMap'] ?? []),
      totalSeats: data['totalSeats'] ?? 0,
      screenType: data['screenType'] ?? '2D',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cinemaId': cinemaId,
      'name': name,
      'seatMap': seatMap,
      'totalSeats': totalSeats,
      'screenType': screenType,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}