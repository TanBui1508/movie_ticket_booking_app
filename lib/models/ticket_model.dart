// lib/models/ticket_model.dart
import 'package:cinema_app_flutter/models/movie_model.dart';
import 'ticket_seat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String? id;
  final String userId;
  final Movie movie;
  final String showtimeId;
  final String theaterName;
  final DateTime showDateTime;
  final List<TicketSeat> seats;
  final double originalPrice;
  final double discountAmount;
  final double totalPrice;
  final DateTime bookingTime;
  final String paymentStatus;
  final String? paymentMethod;
  final String roomId;     
  final String roomName;   
  final DateTime? paidAt;
  final String? appliedVoucherId;   
  final String? appliedVoucherCode;

  Ticket({
    this.id,
    required this.userId,
    required this.movie,
    required this.showtimeId,
    required this.theaterName,
    required this.showDateTime,
    required this.seats,
    required this.originalPrice,
    required this.discountAmount,
    required this.totalPrice,
    required this.bookingTime,
    this.paymentStatus = 'pending',
    this.paymentMethod,
    required this.roomId,   
    required this.roomName, 
    this.paidAt,

    this.appliedVoucherId,
    this.appliedVoucherCode,
  });

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    Map<String, dynamic> movieData = data['movie'] ?? {};
    
    return Ticket(
      id: doc.id,
      userId: data['userId'] ?? '',
      movie: Movie.fromJson(movieData['id'], movieData),
      showtimeId: data['showtimeId'] ?? '',
      theaterName: data['theaterName'] ?? '',
      showDateTime: (data['showDateTime'] as Timestamp).toDate(),
      seats: (data['seats'] as List<dynamic>? ?? [])
          .map((seatJson) => TicketSeat.fromJson(seatJson))
          .toList(),
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0, 
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      bookingTime: (data['bookingTime'] as Timestamp).toDate(),
      paymentStatus: data['paymentStatus'] ?? 'failed',
      paymentMethod: data['paymentMethod'],
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      appliedVoucherId: data['appliedVoucherId'], 
      appliedVoucherCode: data['appliedVoucherCode'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'movie': movie.toJson(), 
      'showtimeId': showtimeId,
      'theaterName': theaterName,
      'showDateTime': Timestamp.fromDate(showDateTime),
      'seats': seats.map((seat) => seat.toJson()).toList(),
      'originalPrice': originalPrice, 
      'discountAmount': discountAmount,
      'totalPrice': totalPrice,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'roomId': roomId,
      'roomName': roomName,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'appliedVoucherId': appliedVoucherId,   
      'appliedVoucherCode': appliedVoucherCode,
    };
  }
}