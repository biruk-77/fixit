import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Import for Color

class Job {
  final String clientId;
  final String id;
  final String seekerId;
  final String title;
  final String description;
  final String location;
  final double budget;
  final DateTime createdAt;
  final String status;
  final String? workerId;
  final List<String> applications;
  final String clientName;
  final String workerName;
  final String? workerImage;
  final String? workerProfession;
  final double? workerRating;
  final String? workerPhone;
  final bool isRequest;
  final String? workerExperience;
  // --- FIXED: Added attachments field ---
  final List<String> attachments; // Store URLs from Storage
  // --- FIXED: Changed scheduledDate to DateTime? ---
  final DateTime? scheduledDate;

  Job({
    required this.clientId,
    required this.id,
    required this.seekerId,
    required this.title,
    required this.description,
    required this.location,
    required this.budget,
    required this.createdAt,
    required this.status,
    this.workerId,
    required this.applications,
    this.clientName = 'Unknown Client',
    this.workerName = 'Unknown Professional',
    this.workerImage,
    this.workerProfession,
    this.workerRating,
    this.workerPhone,
    this.isRequest = false,
    this.workerExperience,
    // --- FIXED: Added attachments to constructor, provide default ---
    this.attachments = const [], // Default to empty list if not provided
    // --- FIXED: Changed scheduledDate type ---
    this.scheduledDate,
  });

  // Convert Firestore DocumentSnapshot to Job
  factory Job.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Ensure ID is passed correctly to fromFirestore if not already in data
    return Job.fromFirestore(data..['id'] = doc.id);
  }

  // Convert JSON/Firestore data to Job
  factory Job.fromFirestore(Map<String, dynamic> data) {
    // Helper function to safely parse Timestamp or null
    DateTime? parseTimestamp(Timestamp? timestamp) {
      return timestamp?.toDate();
    }

    return Job(
      id: data['id'] ?? '', // Make sure ID is handled
      clientId: data['clientId'] ?? data['seekerId'] ?? '', // Added fallback
      seekerId: data['seekerId'] ?? data['clientId'] ?? '', // Added fallback
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      budget: (data['budget'] ?? 0.0).toDouble(),
      createdAt: parseTimestamp(data['createdAt'] as Timestamp?) ??
          DateTime.now(), // Use helper
      status: data['status']?.toString().toLowerCase() ?? 'open',
      workerId: data['workerId']?.toString(),
      applications: List<String>.from(data['applications'] ?? []),
      // --- FIXED: Parsing for attachments ---
      attachments: List<String>.from(
          data['attachments'] ?? []), // Expecting a list of strings (URLs)
      clientName: data['clientName']?.toString() ?? 'Unknown Client',
      workerName: data['workerName']?.toString() ?? 'Unknown Professional',
      workerImage: data['workerImage']?.toString(),
      workerProfession: data['workerProfession']?.toString(),
      workerRating: (data['workerRating'] as num?)?.toDouble(),
      workerPhone: data['workerPhone']?.toString(),
      isRequest: data['isRequest'] == true,
      workerExperience: data['workerExperience']?.toString(),
      // --- FIXED: Parsing for scheduledDate ---
      scheduledDate:
          parseTimestamp(data['scheduledDate'] as Timestamp?), // Use helper
    );
  }

  // Convert Job to Firestore/JSON data
  Map<String, dynamic> toFirestore() {
    return {
      // Generally exclude 'id' when writing, as it's the document ID
      // 'id': id,
      'clientId': clientId,
      'seekerId': seekerId,
      'title': title,
      'description': description,
      'location': location,
      'budget': budget,
      'createdAt': Timestamp.fromDate(createdAt), // Store as Timestamp
      'status': status,
      'workerId': workerId, // Will store null if null
      'applications': applications,
      // --- FIXED: Added attachments ---
      'attachments': attachments,
      'clientName': clientName,
      'workerName': workerName,
      'workerImage': workerImage,
      'workerProfession': workerProfession,
      'workerRating': workerRating,
      'workerPhone': workerPhone,
      'isRequest': isRequest,
      'workerExperience': workerExperience,
      // --- FIXED: Store Timestamp or null ---
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
    };
  }

  // For JSON compatibility (often used with APIs, here just points to Firestore method)
  factory Job.fromJson(Map<String, dynamic> json) => Job.fromFirestore(json);
  Map<String, dynamic> toJson() => toFirestore();

  // Create a copy with updated values
  Job copyWith({
    String? clientId,
    String? id,
    String? seekerId,
    String? title,
    String? description,
    String? location,
    double? budget,
    DateTime? createdAt,
    String? status,
    // Use Object? to allow explicitly setting workerId to null
    Object? workerId = const _Undefined(),
    List<String>? applications,
    // --- FIXED: Added attachments ---
    List<String>? attachments,
    String? clientName,
    String? workerName,
    // Use Object? for nullable fields to allow setting them to null
    Object? workerImage = const _Undefined(),
    Object? workerProfession = const _Undefined(),
    Object? workerRating = const _Undefined(),
    Object? workerPhone = const _Undefined(),
    bool? isRequest,
    Object? workerExperience = const _Undefined(),
    // --- FIXED: Changed scheduledDate type ---
    Object? scheduledDate = const _Undefined(),
  }) {
    return Job(
      clientId: clientId ?? this.clientId,
      id: id ?? this.id,
      seekerId: seekerId ?? this.seekerId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      // Handle explicit null for workerId
      workerId: workerId is _Undefined ? this.workerId : workerId as String?,
      applications: applications ?? this.applications,
      // --- FIXED: Added attachments ---
      attachments: attachments ?? this.attachments,
      clientName: clientName ?? this.clientName,
      workerName: workerName ?? this.workerName,
      // Handle explicit null for nullable fields
      workerImage:
          workerImage is _Undefined ? this.workerImage : workerImage as String?,
      workerProfession: workerProfession is _Undefined
          ? this.workerProfession
          : workerProfession as String?,
      workerRating: workerRating is _Undefined
          ? this.workerRating
          : workerRating as double?,
      workerPhone:
          workerPhone is _Undefined ? this.workerPhone : workerPhone as String?,
      isRequest: isRequest ?? this.isRequest,
      workerExperience: workerExperience is _Undefined
          ? this.workerExperience
          : workerExperience as String?,
      // --- FIXED: Changed scheduledDate type and handle explicit null ---
      scheduledDate: scheduledDate is _Undefined
          ? this.scheduledDate
          : scheduledDate as DateTime?,
    );
  }

  // Helper method to check if job is assigned
  bool get isAssigned => workerId != null && workerId!.isNotEmpty;

  // Helper method to get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'accepted':
        return Colors.purple; // Added distinct color
      case 'started working':
      case 'in_progress':
        return Colors.lightBlue; // Added distinct color
      case 'completed':
        return Colors.green;
      case 'pending':
        return const Color.fromARGB(255, 71, 56, 11);
      case 'cancelled':
      case 'rejected':
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.hourglass_empty_rounded;
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'accepted':
        return Icons.thumb_up_alt_outlined;
      case 'started working':
      case 'in_progress':
        return Icons.construction_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.pending_outlined;
      case 'cancelled':
      case 'rejected':
      case 'closed':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  String toString() {
    return 'Job{id: $id, title: $title, status: $status, client: $clientName, worker: $workerName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job &&
          runtimeType == other.runtimeType &&
          id == other.id; // Usually comparing by ID is sufficient

  @override
  int get hashCode => id.hashCode;
}

// Helper class for copyWith to distinguish between null and not provided
class _Undefined {
  const _Undefined();
}
