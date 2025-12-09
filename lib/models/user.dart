class AppUser {
  final String uid;
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // 'client' or 'worker'/'professional'
  final String? profileImage;
  final String location; // Textual location (e.g., "Bole, Addis Ababa")

  final double? baseLatitude;
  final double? baseLongitude;
  final double? serviceRadiusKm;

  final double? distanceFromClientContext;

  final List<String> favoriteWorkers;
  final List<String> postedJobs;
  final List<String> appliedJobs;
  final bool? profileComplete;

  final int? jobsCompleted;
  final double? rating;
  final int? experience;
  final int? reviewCount;
  final int? jobsPosted;
  final int? paymentsComplete;

  AppUser({
    required this.uid,
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profileImage,
    required this.location, // General text location
    // For Professionals
    this.baseLatitude,
    this.baseLongitude,
    this.serviceRadiusKm,

    // For UI display
    this.distanceFromClientContext,
    required this.favoriteWorkers,
    required this.postedJobs,
    required this.appliedJobs,
    this.profileComplete,
    this.jobsCompleted,
    this.rating,
    this.experience,
    this.reviewCount,
    this.jobsPosted,
    this.paymentsComplete,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber:
          json['phoneNumber'] ??
          json['phone'] ??
          '', // Added fallback for 'phone'
      role: json['role'] ?? json['userType'] ?? 'client',
      profileImage: json['profileImage'],
      location: json['location'] ?? '',

      // For Professionals from Firestore
      baseLatitude:
          (json['baseLatitude'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble(), // Fallback for 'latitude'
      baseLongitude:
          (json['baseLongitude'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble(), // Fallback for 'longitude'
      serviceRadiusKm: (json['serviceRadiusKm'] as num?)?.toDouble(),

      // distanceFromClientContext will be calculated, not from JSON
      distanceFromClientContext: null,

      favoriteWorkers: List<String>.from(json['favoriteWorkers'] ?? []),
      postedJobs: List<String>.from(json['postedJobs'] ?? []),
      appliedJobs: List<String>.from(json['appliedJobs'] ?? []),
      profileComplete: json['profileComplete'] as bool?,
      jobsCompleted: json['completedJobs'] is int
          ? json['completedJobs']
          : (json['jobsCompleted'] is int
                ? json['jobsCompleted']
                : null), // Fallback for completedJobs
      rating: json['rating'] is double
          ? json['rating']
          : (json['rating'] is int ? (json['rating'] as int).toDouble() : null),
      experience: json['experience'] is int ? json['experience'] : null,
      reviewCount: json['reviewCount'] is int ? json['reviewCount'] : null,
      jobsPosted: json['jobsPosted'] is int ? json['jobsPosted'] : null,
      paymentsComplete: json['paymentsComplete'] is int
          ? json['paymentsComplete']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'profileImage': profileImage,
      'location': location,
      'favoriteWorkers': favoriteWorkers,
      'postedJobs': postedJobs,
      'appliedJobs': appliedJobs,
      'profileComplete': profileComplete,
      'jobsCompleted': jobsCompleted,
      'rating': rating,
      'experience': experience,
      'reviewCount': reviewCount,
      'jobsPosted': jobsPosted,
      'paymentsComplete': paymentsComplete,
    };
    // Only include professional-specific fields if they are not null
    if (baseLatitude != null) data['baseLatitude'] = baseLatitude;
    if (baseLongitude != null) data['baseLongitude'] = baseLongitude;
    if (serviceRadiusKm != null) data['serviceRadiusKm'] = serviceRadiusKm;
    // DO NOT include distanceFromClientContext in toJson as it's transient
    return data;
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? profileImage,
    String? location,
    double? baseLatitude, // Make these nullable for copyWith
    double? baseLongitude,
    double? serviceRadiusKm,
    double? distanceFromClientContext, // Allow setting this in copyWith
    List<String>? favoriteWorkers,
    List<String>? postedJobs,
    List<String>? appliedJobs,
    bool? profileComplete,
    int? jobsCompleted,
    double? rating,
    int? experience,
    int? reviewCount,
    int? jobsPosted,
    int? paymentsComplete,
  }) {
    return AppUser(
      uid: uid,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      baseLatitude: baseLatitude ?? this.baseLatitude,
      baseLongitude: baseLongitude ?? this.baseLongitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      distanceFromClientContext:
          distanceFromClientContext ?? this.distanceFromClientContext,
      favoriteWorkers: favoriteWorkers ?? this.favoriteWorkers,
      postedJobs: postedJobs ?? this.postedJobs,
      appliedJobs: appliedJobs ?? this.appliedJobs,
      profileComplete: profileComplete ?? this.profileComplete,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      reviewCount: reviewCount ?? this.reviewCount,
      jobsPosted: jobsPosted ?? this.jobsPosted,
      paymentsComplete: paymentsComplete ?? this.paymentsComplete,
    );
  }
}
