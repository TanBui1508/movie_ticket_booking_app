import 'package:cloud_firestore/cloud_firestore.dart';

class Cinema {
  final String? id;
  final String name;
  final String address;
  final String city;
  final GeoPoint location;
  final String phone;
  final String logoUrl;
  final DateTime createdAt;
  final String openingHours;     
  final List<String> amenities; 
  final List<String> imageUrls; 

  Cinema({
    this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.location,
    required this.phone,
    required this.logoUrl,
    required this.createdAt,
    required this.openingHours, 
    this.amenities = const [],
    this.imageUrls = const [],
  });

  factory Cinema.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Cinema(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      location: data['location'] is GeoPoint ? data['location'] : const GeoPoint(0, 0), 
      phone: data['phone'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      openingHours: data['openingHours'] as String? ?? '9:00 – 23:00', 
      amenities: List<String>.from(data['amenities'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'address': address,
        'city': city,
        'location': location,
        'phone': phone,
        'logoUrl': logoUrl,
        'createdAt': createdAt,
        'openingHours': openingHours,
        'amenities': amenities,
        'imageUrls': imageUrls,
      };
}