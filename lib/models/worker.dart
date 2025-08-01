// lib/models/worker.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Worker {
  final String id;
  final String name;
  final String profileImage;
  final String profession;
  final List<String> skills;
  final double rating;
  final int completedJobs;
  final String location;
  final double priceRange;
  final String about;
  final String phoneNumber;
  final int experience;
  final double? latitude;
  final double? longitude;
  double? distance;
  final bool isAvailable; // Renamed for consistency with UI code

  final String? introVideoUrl;
  final Map<String, dynamic> galleryImages;
  final List<String> certificationImages;

  final double? serviceRadius;
  final Map<String, dynamic>? availability;

  Worker({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.profession,
    required this.skills,
    required this.rating,
    required this.completedJobs,
    required this.location,
    required this.priceRange,
    required this.about,
    required this.phoneNumber,
    required this.isAvailable,
    this.experience = 0,
    this.latitude,
    this.longitude,
    this.distance, // Added to constructor
    this.introVideoUrl,
    required this.galleryImages,
    required this.certificationImages,
    this.serviceRadius,
    this.availability,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Name',
      profileImage: json['profileImage'] ?? '',
      profession: json['profession'] ?? 'N/A',
      skills: List<String>.from(json['skills'] ?? []),
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      completedJobs: json['completedJobs'] as int? ?? 0,
      location: json['location'] ?? 'Not specified',
      priceRange: (json['priceRange'] as num? ?? 0.0).toDouble(),
      about: json['about'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      experience: json['experience'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(), // Parsing from JSON
      introVideoUrl: json['introVideoUrl'],
      galleryImages: Map<String, dynamic>.from(json['galleryImages'] ?? {}),

      certificationImages: List<String>.from(json['certificationImages'] ?? []),
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
      availability: Map<String, dynamic>.from(json['availability'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'profession': profession,
      'skills': skills,
      'rating': rating,
      'completedJobs': completedJobs,
      'location': location,
      'priceRange': priceRange,
      'isAvailable': isAvailable,
      'about': about,
      'phoneNumber': phoneNumber,
      'experience': experience,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance, // Added to JSON
      'introVideoUrl': introVideoUrl,
      'galleryImages': galleryImages,
      'certificationImages': certificationImages,
      'serviceRadius': serviceRadius,
      'availability': availability ?? {},
    };
  }
}
