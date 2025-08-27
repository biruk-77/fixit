// lib/models/worker.dart

class AvailabilitySlot {
  final String start;
  final String end;
  final bool isActive;

  AvailabilitySlot({
    required this.start,
    required this.end,
    required this.isActive,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      start: json['start'] ?? '00:00',
      end: json['end'] ?? '00:00',
      isActive: json['isActive'] ?? false,
    );
  }
}

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
  final bool isAvailable;

  final String? introVideoUrl;
  final Map<String, List<String>> galleryImages; // Correctly typed
  final List<String> certificationImages;

  final double? serviceRadius;
  final Map<String, AvailabilitySlot> availability; // Correctly typed

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
    this.isAvailable = true,
    this.experience = 0,
    this.latitude,
    this.longitude,
    this.distance,
    this.introVideoUrl,
    required this.galleryImages,
    required this.certificationImages,
    this.serviceRadius,
    required this.availability,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    // --- THIS IS THE CRASH FIX ---
    // Safely parse galleryImages, handling both Map and List cases
    Map<String, List<String>> parsedGalleryImages = {};
    if (json['galleryImages'] is Map) {
      // If it's a Map (the correct format), parse it
      final galleryData = json['galleryImages'] as Map;
      galleryData.forEach((key, value) {
        if (value is List) {
          parsedGalleryImages[key.toString()] = List<String>.from(value);
        }
      });
    }
    // If json['galleryImages'] is a List (like in your error data) or null,
    // it will just remain an empty map, which prevents the app from crashing.

    // Safely parse availabilityData
    Map<String, AvailabilitySlot> parsedAvailability = {};
    if (json['availabilityData'] is Map) {
      final availabilityData = json['availabilityData'] as Map;
      availabilityData.forEach((key, value) {
        if (value is Map) {
          try {
            parsedAvailability[key.toString()] = AvailabilitySlot.fromJson(
              value as Map<String, dynamic>,
            );
          } catch (e) {
            print("Could not parse availability slot for key $key: $e");
          }
        }
      });
    }

    return Worker(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Name',
      profileImage: json['profileImage'] ?? '',
      profession: json['profession'] ?? 'N/A',
      skills: List<String>.from(json['skills'] ?? []),
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      completedJobs: (json['completedJobs'] as num?)?.toInt() ?? 0,
      location: json['location'] ?? 'Not specified',
      priceRange: (json['priceRange'] as num? ?? 0.0).toDouble(),
      about: json['about'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      introVideoUrl: json['introVideoUrl'],
      certificationImages: List<String>.from(json['certificationImages'] ?? []),

      // Use the safely parsed variables
      galleryImages: parsedGalleryImages,
      availability: parsedAvailability,

      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
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
      'distance': distance,
      'introVideoUrl': introVideoUrl,
      // Note: toJson for complex objects would need custom logic if you were writing back
      // but for reading from Firestore, this is not needed.
      'galleryImages': galleryImages,
      'certificationImages': certificationImages,
      'serviceRadius': serviceRadius,
      // 'availability': availability, // This would also need a custom toJson method
    };
  }
}
