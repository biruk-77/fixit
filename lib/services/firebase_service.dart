import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:flutter/foundation.dart'
    show kIsWeb; // For checking web platform
import 'package:file_picker/file_picker.dart'; // For PlatformFile type
import 'package:mime/mime.dart';
import '../models/worker.dart';
import '../models/job.dart';

import '../models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  String? get currentUserId => _auth.currentUser?.uid;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  Future<void> logTransaction(Map<String, dynamic> data) async {
    await _firestore
        .collection('transactions')
        .doc(data['transactionId'])
        .set(data);
  }

  /// Updates a transaction
  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('transactions').doc(transactionId).update(data);
  }

  // Create sample professionals for demo purposes
  Future<void> _createSampleProfessionals() async {
    try {
      print('Starting to create sample professionals...');
      final sampleWorkers = [
        {
          'name': 'Abebe Kebede',
          'profession': 'Electrician',
          'experience': 5,
          'priceRange': 500.0,
          'location': 'Addis Ababa',
          'skills': ['Wiring', 'Installation', 'Repairs'],
          'about':
              'Experienced electrician specializing in home and office installations.',
          'profileImage': 'https://randomuser.me/api/portraits/men/1.jpg',
          'phoneNumber': '+251911234567',
          'email': 'abebe@example.com',
        },
        {
          'name': 'Sara Haile',
          'profession': 'Plumber',
          'experience': 3,
          'priceRange': 450.0,
          'location': 'Adama',
          'skills': ['Pipe Fitting', 'Leak Repair', 'Installation'],
          'about':
              'Professional plumber providing quality services for residential and commercial properties.',
          'profileImage': 'https://randomuser.me/api/portraits/women/2.jpg',
          'phoneNumber': '+251922345678',
          'email': 'sara@example.com',
        },
        {
          'name': 'Dawit Mengistu',
          'profession': 'Carpenter',
          'experience': 7,
          'priceRange': 600.0,
          'location': 'Bahir Dar',
          'skills': ['Furniture Making', 'Cabinet Installation', 'Wood Repair'],
          'about':
              'Skilled carpenter with expertise in custom furniture design and woodworking.',
          'profileImage': 'https://randomuser.me/api/portraits/men/3.jpg',
          'phoneNumber': '+251933456789',
          'email': 'dawit@example.com',
        },
      ];

      for (var worker in sampleWorkers) {
        print('Creating professional: ${worker['name']}');

        // Create in professionals collection
        final docRef = _firestore.collection('professionals').doc();
        await docRef.set({
          'name': worker['name'],
          'profession': worker['profession'],
          'experience': worker['experience'],
          'priceRange': worker['priceRange'],
          'location': worker['location'],
          'skills': worker['skills'],
          'about': worker['about'],
          'profileImage': worker['profileImage'],
          'phone': worker['phoneNumber'],
          'email': worker['email'],
          'userType': 'professional',
          'rating': 4.5,
          'completedJobs': 15,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Created professional with ID: ${docRef.id}');

        // Also create in workers collection for backward compatibility
        await _firestore.collection('professionals').doc(docRef.id).set({
          'id': docRef.id,
          'name': worker['name'],
          'profession': worker['profession'],
          'skills': worker['skills'],
          'location': worker['location'],
          'experience': worker['experience'],
          'priceRange': worker['priceRange'],
          'rating': 4.5,
          'completedJobs': 15,
          'about': worker['about'],
          'profileImage': worker['profileImage'],
          'phone': worker['phoneNumber'],
        });
      }

      print(
        'Successfully created ${sampleWorkers.length} sample professionals',
      );
    } catch (e) {
      print('Error creating sample professionals: $e');
    }
  }

  // In getWorkerJobs()
  Future<List<Job>> getWorkerJobs(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('professionals')
          .doc(userId)
          .collection('jobs')
          .where('workerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true) // Add sorting
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<List<Job>> getAppliedJobs(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('jobs')
          .where('applications', arrayContains: userId)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting applied jobs: $e');
      return [];
    }
  }

  Future<List<Job>> getClientJobs(String userId) async {
    try {
      // Check if the jobs collection uses 'clientId' or 'seekerId'
      final testDoc = await _firestore.collection('jobs').limit(1).get();
      final fieldExists =
          testDoc.docs.isNotEmpty &&
          (testDoc.docs.first.data()).containsKey('clientId');

      Query query = fieldExists
          ? _firestore.collection('jobs').where('clientId', isEqualTo: userId)
          : _firestore.collection('jobs').where('seekerId', isEqualTo: userId);

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting client jobs: $e');
      return [];
    }
  }

  Future<List<Worker>> getWorkers({String? location}) async {
    try {
      List<Worker> workers = [];
      print(
        'Attempting to load workers from the "professionals" collection...',
      );

      Query professionalsQuery = _firestore.collection('professionals');

      // Apply location filter if provided and not 'All'
      if (location != null && location != 'All') {
        professionalsQuery = professionalsQuery.where(
          'location',
          isEqualTo: location,
        );
      }

      professionalsQuery = professionalsQuery.where(
        'profileComplete',
        isEqualTo: true,
      );

      QuerySnapshot professionalsSnapshot = await professionalsQuery.get();
      print(
        'Found ${professionalsSnapshot.docs.length} completed profiles in "professionals" collection.',
      );

      for (var doc in professionalsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        try {
          // --> THE ERROR IS HAPPENING HERE! <--
          final worker = Worker.fromJson(
            data,
          ); // This line is failing silently.
          workers.add(worker);
        } catch (e, s) {
          print('--- ERROR PARSING WORKER DOCUMENT ---');
          print('Failed to process document ID: ${doc.id}');
          print('Error: $e');
          print('Stack Trace: $s');
          print('Problematic Data: $data');
          print('------------------------------------');
        }
      }

      // If no workers found, you can optionally create sample data for testing.
      // Note: This might not be desirable in a production app.
      if (workers.isEmpty) {
        print(
          'No professionals found. Creating sample data for demonstration...',
        );
        await _createSampleProfessionals();

        // Try fetching again after creating the samples.
        // This is a recursive call, be mindful of infinite loops if sample creation fails.
        print('Re-fetching professionals after creating samples...');
        return await getWorkers(location: location);
      }

      print('Successfully loaded ${workers.length} professionals.');
      return workers;
    } catch (e) {
      print('--- FATAL ERROR in getWorkers ---');
      print('Error: $e');
      print('---------------------------------');
      return []; // Return an empty list on failure
    }
  }

  Future<Worker?> getWorker(String userId) async {
    try {
      final doc = await _firestore
          .collection('professionals')
          .doc(userId)
          .get();
      if (doc.exists) {
        return Worker.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting professional profile: $e');
      return null;
    }
  }

  // In lib/services/firebase_service.dart

  // In lib/services/firebase_service.dart

  Future<void> saveWorker({
    required String name,
    required String profession,
    required String phone,
    required String location,
    required int experience,
    required String about,
    required double priceRange,
    required List<String> skills,
    String? profileImageUrl,
    String? introVideoUrl,
    required Map<String, List<String>> galleryImageUrls,

    required List<String> certificationImageUrls,
    double? serviceRadius,
    Map<String, Map<String, dynamic>>? availability,
    double? latitude,
    double? longitude,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in for profile save');

    final dataToSave = <String, dynamic>{
      'name': name,
      'profession': profession,
      'phoneNumber': phone,
      'location': location,
      'experience': experience,
      'about': about,
      'priceRange': priceRange,
      'skills': skills,
      'galleryImages': galleryImageUrls, // Now it correctly saves the map
      'certificationImages': certificationImageUrls,
      'profileComplete': true,
      'role': 'worker',
      'userType': 'professional',
      'updatedAt': FieldValue.serverTimestamp(),
      'id': user.uid,
      'email': user.email,
      'profileImage': profileImageUrl,
      'introVideoUrl': introVideoUrl,
      'serviceRadius': serviceRadius,
      'availabilityData': availability,
      'latitude': latitude,
      'longitude': longitude,
    };

    // Using `SetOptions(merge: true)` is safer for updates.
    await _firestore
        .collection('professionals')
        .doc(user.uid)
        .set(dataToSave, SetOptions(merge: true));
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    return _uploadFileToSupabase(
      file: imageFile,
      bucketName: 'images', // Your Supabase bucket for images
      folderPath: 'profile_images',
    );
  }

  Future<String?> uploadGenericImage(File imageFile, String folderName) async {
    return _uploadFileToSupabase(
      file: imageFile,
      bucketName: 'images', // Your Supabase bucket for images
      folderPath: folderName,
    );
  }

  Future<String?> uploadProfileVideoToSupabase({
    required PlatformFile platformFile,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    const String videoBucket = 'videos';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name.replaceAll(RegExp(r'\s+'), '_')}';
    final filePath = 'public/profile_videos/${user.uid}/$fileName';

    try {
      final mimeType = lookupMimeType(
        platformFile.name,
        headerBytes: platformFile.bytes?.take(1024).toList(),
      );
      final fileOptions = FileOptions(
        contentType: mimeType,
        cacheControl: '3600',
        upsert: false,
      );

      if (kIsWeb) {
        if (platformFile.bytes == null)
          throw Exception("File bytes are null for web upload.");
        await _supabaseClient.storage
            .from(videoBucket)
            .uploadBinary(
              filePath,
              platformFile.bytes!,
              fileOptions: fileOptions,
            );
      } else {
        if (platformFile.path == null)
          throw Exception("File path is null for mobile upload.");
        await _supabaseClient.storage
            .from(videoBucket)
            .upload(
              filePath,
              File(platformFile.path!),
              fileOptions: fileOptions,
            );
      }
      return _supabaseClient.storage.from(videoBucket).getPublicUrl(filePath);
    } catch (e) {
      print('Supabase video upload error: $e');
      return null;
    }
  }

  Future<String?> _uploadFileToSupabase({
    required File file,
    required String bucketName,
    required String folderPath,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('Cannot upload: User not logged in.');
      return null;
    }

    final fileExtension = file.path.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final pathInBucket = 'public/$folderPath/${user.uid}/$fileName';

    print(
      'Uploading to Supabase bucket: "$bucketName" at path: "$pathInBucket"',
    );

    try {
      await _supabaseClient.storage
          .from(bucketName)
          .upload(
            pathInBucket,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      final publicUrl = _supabaseClient.storage
          .from(bucketName)
          .getPublicUrl(pathInBucket);
      print('Supabase upload successful. URL: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      print('!!! Supabase Storage Error: ${e.message}');
      print('!!! PLEASE CHECK:');
      print('    1. Bucket named "$bucketName" exists and is PUBLIC.');
      print(
        '    2. You have a Storage Policy that allows INSERT for authenticated users.',
      );
      return null;
    } catch (e) {
      print('An unknown error occurred during Supabase upload: $e');
      return null;
    }
  }

  // Search workers by skill or profession
  Future<List<Worker>> searchWorkers(String query) async {
    try {
      // First search by profession (exact match)
      QuerySnapshot professionSnapshot = await _firestore
          .collection('professionals')
          .where('profession', isEqualTo: query)
          .get();

      // Then search by skills (contains)
      QuerySnapshot skillsSnapshot = await _firestore
          .collection('professionals')
          .where('skills', arrayContains: query)
          .get();

      // Combine results and remove duplicates
      Set<String> uniqueIds = {};
      List<Worker> workers = [];

      for (var doc in professionSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          workers.add(Worker.fromJson(data));
        }
      }

      for (var doc in skillsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          workers.add(Worker.fromJson(data));
        }
      }

      return workers;
    } catch (e) {
      print('Error searching workers: $e');
      return [];
    }
  }

  // Filter workers by location
  Future<List<Worker>> filterWorkersByLocation(String location) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('professionals')
          .where('location', isEqualTo: location)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Worker.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error filtering workers by location: $e');
      return [];
    }
  }

  // Get worker details by ID
  Future<Worker?> getWorkerById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('professionals')
          .doc(id)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Worker.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting worker by ID: $e');
      return null;
    }
  }

  // Add a dummy worker (for testing purposes)
  Future<void> addDummyWorker() async {
    try {
      await _firestore.collection('professionals').add({
        'name': 'Mohammed Ali',
        'profileImage': 'https://randomuser.me/api/portraits/men/1.jpg',
        'profession': 'Technician',
        'skills': ['Laptop Repair', 'Smartphone Repair', 'Printer Setup'],
        'rating': 4.8,
        'completedJobs': 157,
        'location': 'Adama',
        'priceRange': 250.0,
        'about':
            'Expert technician with 5+ years of experience in electronic repairs.',
        'phoneNumber': '+251912345678',
      });
    } catch (e) {
      print('Error adding dummy worker: $e');
    }
  }

  // Create a sample worker (for demo purposes)
  Future<void> createSampleWorker({
    required String name,
    required String profession,
    required int experience,
    required double priceRange,
    required String location,
    required List<String> skills,
    required String about,
    required String profileImage,
  }) async {
    try {
      // Generate a unique ID for the sample worker
      final docRef = _firestore.collection('professionals').doc();

      final workerData = {
        'id': docRef.id,
        'name': name,
        'profession': profession,
        'skills': skills,
        'rating': (3.5 + (skills.length / 10)), // Random rating between 3.5-4.5
        'completedJobs':
            (5 +
            experience *
                3), // More experienced workers have more completed jobs
        'location': location,
        'priceRange': priceRange,
        'about': about,
        'phoneNumber':
            '+251${900000000 + docRef.id.hashCode.abs() % 100000000}', // Generate a fake Ethiopian phone number
        'experience': experience,
        'profileImage': profileImage,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(workerData);
      print('Created sample worker: $name');
    } catch (e) {
      print('Error creating sample worker: $e');
      rethrow;
    }
  }

  // Job related methods
  Future<String> createJob(dynamic jobInput) async {
    try {
      Map<String, dynamic> jobData;
      if (jobInput is Job) {
        jobData = jobInput.toJson();
      } else if (jobInput is Map<String, dynamic>) {
        jobData = jobInput;
      } else {
        throw ArgumentError('Invalid job input type');
      }

      // Add current user as seekerId if not present
      final User? user = _auth.currentUser;
      if (user != null && !jobData.containsKey('seekerId')) {
        jobData['seekerId'] = user.uid;
      }

      // Initialize empty applications array if not present
      if (!jobData.containsKey('applications')) {
        jobData['applications'] = [];
      }

      DocumentReference docRef = _firestore.collection('jobs').doc();
      await docRef.set(jobData);

      await _firestore
          .collection('users')
          .doc(jobData['seekerId'])
          .collection('jobs')
          .doc(docRef.id)
          .set(jobData);

      return docRef.id;
    } catch (e) {
      print('Error creating job: $e');
      rethrow;
    }
  }

  // Get jobs with optional status filter
  Future<List<Job>> getJobs({String? status}) async {
    try {
      // Get the current user
      final User? user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      // Start with a base query
      Query query = _firestore.collection('jobs');

      // Check user type to filter jobs appropriately
      final userProfile = await getCurrentUserProfile();
      final userType = userProfile?.role ?? 'client';

      if (userType == 'client') {
        // For clients, only show their own jobs
        query = query.where('seekerId', isEqualTo: user.uid);
      } else {
        // For professionals, show all available jobs or jobs they've applied for
        // This approach shows all jobs that are open or the professional has applied to
        // A more sophisticated approach would be to use a compound query with OR
        if (status?.toLowerCase() == 'applied') {
          // Special case to show only jobs the professional has applied to
          query = query.where('applications', arrayContains: user.uid);
        }
        // Otherwise show jobs based on status (or all if no status filter)
      }

      // Apply status filter if provided (except for the special 'applied' case)
      if (status != null && status.toLowerCase() != 'applied') {
        query = query.where('status', isEqualTo: status.toLowerCase());
      }

      // Order by creation date, newest first
      query = query.orderBy('createdAt', descending: true);

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Handle the case where createdAt might be a Timestamp or null
        if (data['createdAt'] == null) {
          data['createdAt'] = Timestamp.now();
        }

        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching jobs: $e');
      return [];
    }
  }

  Future<void> declineJobApplication(
    String clientId,
    String jobId,
    String workerId,
  ) async {
    final batch = _firestore.batch();
    try {
      // 1. Remove worker's application from the main job document
      final jobRef = _firestore.collection('jobs').doc(jobId);
      batch.update(jobRef, {
        'applications': FieldValue.arrayRemove([workerId]),
      });

      // 2. Remove worker's application from the client's subcollection job document
      final clientJobRef = _firestore
          .collection('users')
          .doc(clientId)
          .collection('jobs')
          .doc(jobId);
      if ((await clientJobRef.get()).exists) {
        // Ensure document exists
        batch.update(clientJobRef, {
          'applications': FieldValue.arrayRemove([workerId]),
        });
      }

      // 3. Remove job from worker's 'appliedJobs' list (if you maintain such a list on the worker document)
      final workerRef = _firestore.collection('professionals').doc(workerId);
      if ((await workerRef.get()).exists) {
        // Ensure document exists
        batch.update(workerRef, {
          'appliedJobs': FieldValue.arrayRemove([jobId]),
        });
      }

      // Commit the batch
      await batch.commit();
      print(
        'Application declined for job $jobId by worker $workerId from client $clientId',
      );

      // NOTIFICATION: Notify the worker their application was declined
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobTitle = jobDoc.data()?['title'] ?? 'Untitled Job';
      final clientProfile =
          await getCurrentUserProfile(); // Assuming current user is the client
      final clientName = clientProfile?.name ?? 'The client';

      await createNotification(
        userId: workerId,
        title: 'Application Declined: "$jobTitle"',
        body:
            '$clientName has declined your application for the job: "$jobTitle".',
        type: 'application_declined',
        data: {'jobId': jobId, 'clientId': clientId, 'jobTitle': jobTitle},
      );
      print('Notification sent to worker for declined application.');
    } catch (e) {
      print('Error declining job application: $e');
      rethrow;
    }
  }

  // Get job by ID
  Future<Job?> getJobById(String jobId) async {
    try {
      DocumentSnapshot jobDoc = await _firestore
          .collection('jobs')
          .doc(jobId)
          .get();

      if (!jobDoc.exists) return null;

      Map<String, dynamic> jobData = jobDoc.data() as Map<String, dynamic>;
      jobData['id'] = jobId; // Add the document ID to the data

      // Convert to Job model
      return Job(
        id: jobId,
        clientId: jobData['clientId'] ?? '',
        seekerId:
            jobData['clientId'] ??
            '', // Use clientId as seekerId for compatibility
        title: jobData['title'] ?? 'Untitled Job',
        description: jobData['description'] ?? '',
        location: jobData['location'] ?? '',
        budget: (jobData['budget'] as num?)?.toDouble() ?? 0.0,
        createdAt:
            (jobData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: jobData['status'] ?? 'pending',
        workerId: jobData['workerId'],
        applications: List<String>.from(jobData['applications'] ?? []),
      );
    } catch (e) {
      print('Error getting job by ID: $e');
      return null;
    }
  }

  Future<void> applyToJob(String jobId, String workerId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'applications': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      print('Error applying to job: $e');
      rethrow;
    }
  }

  Future<void> assignJob(String jobId, String workerId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'workerId': workerId,
        'status': 'assigned',
      });
    } catch (e) {
      print('Error assigning job: $e');
      rethrow;
    }
  }

  Future<void> completeJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'completed',
      });
    } catch (e) {
      print('Error completing job: $e');
      rethrow;
    }
  }

  // User related methods
  Future<AppUser?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AppUser.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return null;
      }

      print('Getting profile for user ID: ${user.uid}');

      // First check professionals collection
      final professionalDoc = await _firestore
          .collection('professionals')
          .doc(user.uid)
          .get();
      if (professionalDoc.exists) {
        print('Found user in professionals collection');
        final data = professionalDoc.data() as Map<String, dynamic>;
        data['id'] = professionalDoc.id;
        return AppUser.fromJson(data);
      }

      // Then check workers collection
      final workerDoc = await _firestore
          .collection('professionals')
          .doc(user.uid)
          .get();
      if (workerDoc.exists) {
        print('Found user in workers collection');
        final data = workerDoc.data() as Map<String, dynamic>;
        data['id'] = workerDoc.id;
        data['role'] = 'worker'; // Ensure role is set correctly
        return AppUser.fromJson(data);
      }

      // Then check clients collection
      final clientDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (clientDoc.exists) {
        print('Found user in clients collection');
        final data = clientDoc.data() as Map<String, dynamic>;
        data['id'] = clientDoc.id;
        data['role'] = 'client'; // Ensure role is set correctly
        return AppUser.fromJson(data);
      }

      // If no profile found but user is authenticated, create a default client profile
      print(
        'No profile found for authenticated user, creating default client profile',
      );
      await createUserProfile(
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        userType: 'client',
        textualLocation: '',
      );

      // Try to get the newly created profile
      final newClientDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (newClientDoc.exists) {
        final data = newClientDoc.data() as Map<String, dynamic>;
        data['id'] = newClientDoc.id;
        data['role'] = 'client';
        return AppUser.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    required String userType,
    required String textualLocation,
    double? latitude,
    double? longitude,
    String? profession,
    double? professionalBaseLatitude,
    double? professionalBaseLongitude,
    double? professionalServiceRadiusKm,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found for profile creation');
        return;
      }

      final userData = {
        'id': user.uid,
        'name': name,
        'email': email,
        'phoneNumber': phone,
        'role': userType == 'client'
            ? 'client'
            : 'worker', // Map to consistent roles
        'userType': userType, // Keep for backward compatibility
        'location': '',
        'latitude': '',
        'professionalBaseLatitude': '',
        'professionalBaseLongitude': '',
        'professionalServiceRadiusKm': '',

        'longitude': '',
        'favoriteWorkers': [],
        'postedJobs': [],
        'appliedJobs': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (userType == 'client') {
        final clientData = {...userData, 'jobsPosted': 0, 'completedJobs': 0};

        print('Creating client profile for user ${user.uid}');
        await _firestore.collection('users').doc(user.uid).set(clientData);
      } else {
        final professionalData = {
          ...userData,
          'profession': profession ?? '',
          'profileComplete': profession != null && profession.isNotEmpty,
          'completedJobs': 0,
          'rating': 0.0,
          'reviewCount': 0,
          'profileImage': '',
        };

        print('Creating professional profile for user ${user.uid}');
        await _firestore
            .collection('professionals')
            .doc(user.uid)
            .set(professionalData);

        if (profession != null && profession.isNotEmpty) {
          await _firestore.collection('professionals').doc(user.uid).set({
            'id': user.uid,
            'name': name,
            'profession': profession,
            'skills': [],
            'location': '',
            'experience': 0,
            'priceRange': 0.0,
            'rating': 0.0,
            'completedJobs': 0,
            'phoneNumber': phone,
            'email': email,
            'favoriteWorkers': [],
            'postedJobs': [],
            'location': '',
            'latitude': '',
            'professionalBaseLatitude': '',
            'professionalBaseLongitude': '',
            'professionalServiceRadiusKm': '',
            'appliedJobs': [],
            'role': 'worker',
            'profileImage': '',
          });
        }
      }

      print('User profile created successfully for ${user.uid}');
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<List<Job>> getUserJobs({
    String? userId,
    bool isWorker = false,
    String? status,
  }) async {
    try {
      // Get the current user if no userId is provided
      User? user;
      if (userId == null) {
        user = _auth.currentUser;
        if (user == null) {
          print('No authenticated user found');
          return [];
        }
      }

      final actualUserId = userId ?? user!.uid;
      Query query;

      // Set up the query based on whether it's for a worker or seeker
      if (isWorker) {
        query = _firestore
            .collection('jobs')
            .where('workerId', isEqualTo: actualUserId);
      } else {
        // Check if the collection uses 'clientId' or 'seekerId'
        final testDoc = await _firestore.collection('jobs').limit(1).get();
        if (testDoc.docs.isNotEmpty) {
          final fieldExists = (testDoc.docs.first.data()).containsKey(
            'clientId',
          );
          if (fieldExists) {
            query = _firestore
                .collection('jobs')
                .where('clientId', isEqualTo: actualUserId);
          } else {
            query = _firestore
                .collection('jobs')
                .where('seekerId', isEqualTo: actualUserId);
          }
        } else {
          query = _firestore
              .collection('jobs')
              .where('clientId', isEqualTo: actualUserId);
        }
      }

      // Add status filter if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Fetch the data without ordering
      final snapshot = await query.get();

      // Convert to a list of Job objects
      final jobs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();

      // Sort by createdAt descending (newest first)
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return jobs;
    } catch (e) {
      print('Error getting user jobs: $e');
      return [];
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Trim whitespace from email and password
      email = email.trim();
      password = password.trim();

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Trim whitespace from email and password
      email = email.trim();
      password = password.trim();

      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update(data);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfileImageToSupabase(File imageFile) async {
    final User? user = _auth.currentUser; // Use aliased User
    if (user == null) {
      print('Error uploading image to Supabase: User not logged in.');
      return null;
    }

    const String profileImageBucket = 'images';

    try {
      final userId = user.uid;
      // Get file extension, default to jpg if extraction fails or isn't common image type
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final safeExtension =
          ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)
          ? fileExtension
          : 'jpg';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
      // Path structure: public/<user_id>/<filename>
      // Using 'public/' is a common convention for public buckets
      final filePath = 'public/$userId/$fileName';

      print('Uploading profile image to Supabase Storage...');
      print('  File: ${imageFile.path}');
      print('  Bucket: $profileImageBucket');
      print('  Path in bucket: $filePath');

      // Upload the file using Supabase client
      await _supabaseClient.storage
          .from(profileImageBucket)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600', // Cache for 1 hour
              upsert: false, // Don't overwrite existing file with same name
            ),
          );

      print('Supabase upload successful. Getting public URL...');

      // Get the public URL for the uploaded file
      final imageUrlResponse = _supabaseClient.storage
          .from(profileImageBucket)
          .getPublicUrl(filePath); // Use the same path used in upload()

      // The public URL is directly in the response string
      final imageUrl = imageUrlResponse;

      print('Supabase Profile Image URL: $imageUrl');
      return imageUrl;
    } on StorageException catch (e) {
      // Catch Supabase-specific storage errors
      print('[Supabase Storage Error]');
      print('  Message: ${e.message}');
      print('  Error details: ${e.error ?? 'N/A'}');
      print(
        '  Status code: ${e.statusCode ?? 'N/A'}',
      ); // Will show 404 if bucket not found
      return null; // Return null on Supabase-specific failure
    } catch (e, s) {
      print('[General Error during Supabase upload]');
      print('  Error: $e');
      print('  Stack Trace: $s');
      return null; // Return null on general failure
    }
  }

  Future<void> completeWorkerSetup({
    required String profession,
    required int experience,
    required double priceRange,
    required String location,
    required List<String> skills,
    required String about,
    String? profileImageUrl,
    double? latitude,
    double? longitude, // The URL string from Supabase (or null)
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in for worker setup');

    final userId = user.uid;
    print('Completing worker setup/update for user $userId...');

    try {
      // Data to save/update in the 'professionals' collection
      final dataToUpdate = {
        'profession': profession,
        'experience': experience,
        'priceRange': priceRange,
        'location': location,
        'skills': skills, // Ensure skills are correctly passed
        'about': about,
        'profileImage': profileImageUrl, // Save the URL here
        'profileComplete': true, // Mark profile as complete
        'role': 'worker', // Ensure role is explicitly worker
        'userType': 'professional', // Keep for compatibility if needed
        'updatedAt': FieldValue.serverTimestamp(),
        'latitude': latitude,
        'longitude': longitude,
        // Add other fields if needed, consider merging
        'name': user.displayName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'rating': FieldValue.increment(
          0,
        ), // Use increment to avoid overwriting if merging
        'reviewCount': FieldValue.increment(0),
        'completedJobs': FieldValue.increment(0),
        'isAvailable': true,
      };

      // Using set with merge: true is safer for updates
      await _firestore
          .collection('professionals')
          .doc(userId)
          .set(dataToUpdate, SetOptions(merge: true));

      print('Worker profile setup/update completed successfully for $userId.');
    } catch (e) {
      print('Error during worker profile setup/update: $e');
      rethrow;
    }
  }

  // Create worker profile
  Future<void> createWorkerProfile({
    required String profession,
    required int experience,
    required double priceRange,
    required String location,
    required List<String> skills,
    required String about,
    String? profileImage,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Get existing professional data
      final professionalDoc = await _firestore
          .collection('professionals')
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = {};

      if (professionalDoc.exists) {
        userData = professionalDoc.data() as Map<String, dynamic>;
      } else {
        // Get basic user data if professional profile doesn't exist
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
        }
      }

      // Set up worker profile data
      final workerData = {
        'profession': profession,
        'experience': experience,
        'priceRange': priceRange,
        'location': location,
        'skills': skills,
        'about': about,
        'profileComplete': true,
        'userType': 'professional',
        'completedJobs': userData['completedJobs'] ?? 0,
        'rating': userData['rating'] ?? 0.0,
        'reviewCount': userData['reviewCount'] ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add name, email and phone if available
      if (userData.containsKey('name')) {
        workerData['name'] = userData['name'];
      }

      if (userData.containsKey('email')) {
        workerData['email'] = userData['email'];
      }

      if (userData.containsKey('phone')) {
        workerData['phone'] = userData['phone'];
      }

      // Add profile image if provided
      if (profileImage != null) {
        workerData['profileImage'] = profileImage;
      } else if (userData.containsKey('profileImage')) {
        workerData['profileImage'] = userData['profileImage'];
      }

      // Update professionals collection with worker profile
      await _firestore
          .collection('professionals')
          .doc(user.uid)
          .set(workerData, SetOptions(merge: true));

      // Also update the workers collection for backward compatibility
      await _firestore.collection('professionals').doc(user.uid).set({
        'id': user.uid,
        ...workerData,
      }, SetOptions(merge: true));

      print('Worker profile created/updated for ${user.uid}');
    } catch (e) {
      print('Error creating worker profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfileImageInFirestore(
    String userId,
    String imageUrl,
    String role,
  ) async {
    String collectionPath;
    String normalizedRole = role.toLowerCase();
    if (normalizedRole == 'worker' || normalizedRole == 'professional') {
      collectionPath = 'professionals';
    } else if (normalizedRole == 'client' || normalizedRole == 'seeker') {
      collectionPath = 'users';
    } else {
      print("Error: Unknown user role '$role' for profile image update.");
      collectionPath = 'users'; // Defaulting
    }
    print(
      "Updating profile image URL in Firestore collection '$collectionPath' for user $userId...",
    );
    try {
      await _firestore.collection(collectionPath).doc(userId).update({
        // Make sure 'profileImage' is the correct field name in YOUR Firestore documents
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
        "Firestore profile image URL updated successfully in $collectionPath.",
      );
    } catch (e) {
      print(
        "Error updating profile image URL in Firestore ($collectionPath): $e",
      );
      rethrow;
    }
  }

  // Apply for a job
  Future<void> applyForJob(String jobId, String workerId) async {
    // Get the current worker user ID (redundant if workerId is passed, but good practice)
    final User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != workerId) {
      throw 'User not logged in or worker ID mismatch';
    }

    final jobRef = _firestore.collection('jobs').doc(jobId);

    try {
      // --- Get the clientId (seekerId) from the main job document ---
      final jobSnapshot = await jobRef.get();
      if (!jobSnapshot.exists) {
        throw 'Job document not found in main collection.';
      }
      final jobData = jobSnapshot.data();
      // Determine the correct client ID field ('seekerId' or 'clientId')
      final clientId = jobData?['seekerId'] ?? jobData?['clientId'];
      if (clientId == null || clientId is! String || clientId.isEmpty) {
        print(
          'Error in applyForJob: Could not find valid seekerId/clientId in job document $jobId',
        );
        print('Job Data: $jobData');
        throw 'Could not find client ID for the job.';
      }
      // --- End Get Client ID ---

      // Reference to the job document inside the user's subcollection
      final userJobRef = _firestore
          .collection('users')
          .doc(clientId) // Use the fetched clientId
          .collection('jobs')
          .doc(jobId);

      // --- Use a Batch Write for atomic update ---
      WriteBatch batch = _firestore.batch();

      // 1. Update the main /jobs/{jobId} document
      batch.update(jobRef, {
        'applications': FieldValue.arrayUnion([workerId]),
      });

      // 2. Update the /users/{clientId}/jobs/{jobId} document
      // Important: Check if the user's job subcollection document exists first
      final userJobSnapshot = await userJobRef.get();
      if (userJobSnapshot.exists) {
        print("Updating user's job subcollection document...");
        batch.update(userJobRef, {
          'applications': FieldValue.arrayUnion([workerId]),
        });
      } else {
        // This case might happen if the initial copy failed or structure changed.
        // Decide how to handle: Log an error, or maybe create/set it here?
        // Setting it might overwrite other fields if the structure diverged.
        print(
          "Warning: Job document not found in user subcollection /users/$clientId/jobs/$jobId. Only updating main job doc.",
        );
        // OPTIONALLY: You could try setting it, but be careful:
        // final initialJobData = { ... create a minimal job map or fetch again ... };
        // initialJobData['applications'] = [workerId];
        // batch.set(userJobRef, initialJobData);
      }

      // Commit the batch
      await batch.commit();
      print('Application added to both job locations successfully.');
      // --- End Batch Write ---
    } catch (e, s) {
      print('Error applying for job (batch update): $e\n$s');
      // Rethrow or handle the error appropriately
      rethrow;
    }
  }

  // Add job id to user's job applications
  Future<void> addApplicationToUser(String jobId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final clientId = jobDoc.data()?['seekerId'];
      print('Client ID: $clientId');

      if (clientId == null) print('Client ID not found in job document');

      final userDoc = await _firestore.collection('users').doc(clientId).get();
      if (userDoc.exists) {
        await _firestore
            .collection('users')
            .doc(clientId)
            .collection('jobs')
            .doc(jobId)
            .set({
              'applications': FieldValue.arrayUnion([user.uid]),
            }, SetOptions(merge: true));
      } else {
        print('Client not found. Cannot add job id to their job applications');
      }
    } catch (e) {
      print('Error adding job id to user\'s job applications: $e');
      rethrow;
    }
  }

  Future<List<Job>> getClientJobsWithApplications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('jobs')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final applications = List<String>.from(data['applications'] ?? []);
        return Job.fromFirestore({
          ...data,
          'id': doc.id,
          'applications': applications,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load jobs with applications: $e');
    }
  }

  // Assign job to worker
  Future<void> assignJobToWorker(String jobId, String workerId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'workerId': workerId,
        'status': 'assigned',
      });
    } catch (e) {
      print('Error assigning job to worker: $e');
      rethrow;
    }
  }

  Future<void> addReview(
    String workerId,
    String comment,
    double rating, {
    String? jobTitle,
    String? clientPhotoUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final userProfile = await getCurrentUserProfile();
      final reviewData = {
        'workerId': workerId,
        'userId': user.uid,
        'userName': userProfile?.name ?? 'Anonymous',
        'clientPhotoUrl': clientPhotoUrl ?? userProfile?.profileImage ?? '',
        'rating': rating,
        'comment': comment,
        'jobTitle': jobTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('professionals')
          .doc(workerId)
          .collection('reviews')
          .add(reviewData);
      final workerDoc = await _firestore
          .collection('professionals')
          .doc(workerId)
          .get();
      if (workerDoc.exists) {
        final data = workerDoc.data() as Map<String, dynamic>;
        final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewCount = (data['reviewCount'] as int?) ?? 0;

        final newReviewCount = reviewCount + 1;
        final newRating =
            ((currentRating * reviewCount) + rating) / newReviewCount;

        await _firestore.collection('professionals').doc(workerId).update({
          'rating': newRating,
          'reviewCount': newReviewCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      print('Review added successfully');
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  Stream<double> streamWorkerRating(String workerId) {
    return _firestore
        .collection('professionals')
        .doc(workerId)
        .snapshots()
        .map(
          (snapshot) => (snapshot.data()?['rating'] as num?)?.toDouble() ?? 0.0,
        );
  }

  Stream<bool> streamProfessionalAvailability(String workerId) {
    DateTime today = DateTime.now();
    String todayString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return _firestore
        .collection('professionals')
        .doc(workerId)
        .collection('availability')
        .doc(todayString)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          final isAvailable = data?['isAvailable'] as bool? ?? true;

          // If it's today's date and marked unavailable, update it to false
          if (todayString == todayString && isAvailable == false) {
            _firestore
                .collection('professionals')
                .doc(workerId)
                .update({'isAvailable': false})
                .then((_) {
                  print('✅ Successfully updated Firestore to false');
                })
                .catchError((error) {
                  print('❌ Error updating Firestore: $error');
                });
          }

          return isAvailable;
        });
  }

  Stream<List<Map<String, dynamic>>> streamWorkerReviews(String workerId) {
    return _firestore
        .collection('professionals')
        .doc(workerId)
        .collection('reviews')
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  Stream<bool> streamDayAvailability(String workerId, DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    print('🔍 Checking availability for worker: $workerId on $dateString');

    return _firestore
        .collection('professionals')
        .doc(workerId)
        .collection('availability')
        .doc(dateString)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            print('❌ Document does NOT exist for $workerId on $dateString');
            return true; // Default to available if document doesn't exist
          }

          DateTime today = DateTime.now();
          String todayString =
              "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

          print('📅 Today: $todayString');

          final data = snapshot.data();
          if (data == null || !data.containsKey('isAvailable')) {
            print(
              '⚠️ "isAvailable" field missing for $workerId on $dateString',
            );
            return true; // Default to available if field is missing
          }

          final isAvailable = data['isAvailable'] as bool? ?? true;

          // 🔄 If it's today's date and marked unavailable, update it to false
          if (dateString == todayString && isAvailable == false) {
            print(
              '🔄 Updating availability for $workerId on $dateString to FALSE',
            );

            _firestore
                .collection('professionals')
                .doc(workerId)
                .update({'isAvailable': false})
                .then((_) {
                  print('✅ Successfully updated Firestore to false');
                })
                .catchError((error) {
                  print('❌ Error updating Firestore: $error');
                });
          } else {
            _firestore
                .collection('professionals')
                .doc(workerId)
                .update({'isAvailable': true})
                .then((_) {
                  print('✅ Successfully updated Firestore to false');
                })
                .catchError((error) {
                  print('❌ Error updating Firestore: $error');
                });
          }

          print('✅ Availability for $workerId on $dateString: $isAvailable');
          return isAvailable;
        })
        .handleError((error) {
          print('🔥 Firestore error for $workerId on $dateString: $error');
          return false; // Default to unavailable on error
        });
  }

  Stream<List<bool>> streamTimeSlots(String workerId, DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _firestore
        .collection('professionals')
        .doc(workerId)
        .collection('availability')
        .doc(dateString)
        .collection('timeSlots')
        .orderBy('hour')
        .snapshots()
        .map((snapshot) {
          final timeSlots = List<bool>.filled(9, true); // Default to available
          for (var doc in snapshot.docs) {
            final hour = int.tryParse(doc.id);
            if (hour != null && hour >= 9 && hour <= 17) {
              timeSlots[hour - 9] = doc.data()['available'] as bool? ?? true;
            }
          }
          return timeSlots;
        });
  }

  /// Updates the status of a job across client and professional collections
  Future<bool> updateJobStatus(
    String jobId,
    String? professionalId,
    String clientId,
    String status,
  ) async {
    final batch = _firestore.batch(); // Initialize Firestore batch
    try {
      print('✅ Updating job status for job: $jobId to $status');
      print('👨‍💻 Professional ID: $professionalId');
      print('👨‍👩‍👧 Client ID: $clientId');

      // Verify job exists and get workerId
      final jobDoc = await _firestore
          .collection('users')
          .doc(clientId)
          .collection('jobs')
          .doc(jobId)
          .get();

      if (!jobDoc.exists) {
        print('🛑 Job $jobId not found in client jobs');
        return false;
      }

      // Use workerId from jobDoc if available, fallback to professionalId
      final workerId = jobDoc.data()?['workerId'] as String? ?? professionalId;
      if (workerId == null) {
        print('🛑 No valid workerId found for job $jobId');
        return false;
      }
      print('👷 Worker ID resolved: $workerId');

      // Collections to update
      final collectionsToUpdate = [
        // Client collections
        _firestore
            .collection('users')
            .doc(clientId)
            .collection('requests')
            .doc(jobId),
        _firestore
            .collection('users')
            .doc(clientId)
            .collection('jobs')
            .doc(jobId),
        // Professional collections
        _firestore
            .collection('professionals')
            .doc(workerId)
            .collection('requests')
            .doc(jobId),
        _firestore
            .collection('professionals')
            .doc(workerId)
            .collection('jobs')
            .doc(jobId),
      ];

      // Update existing documents in batch
      for (final docRef in collectionsToUpdate) {
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          print('⚠️ Skipping non-existent doc: ${docRef.path}');
          continue;
        }

        print('✅ Adding to batch: ${docRef.path}');
        batch.update(docRef, {
          'status': status,
          'lastUpdated':
              FieldValue.serverTimestamp(), // Use Firestore timestamp
        });
      }

      // Commit batch
      await batch.commit();
      print('🎉 Successfully updated job $jobId to status: $status');

      // Send notification to client
      await createNotification(
        userId: clientId,
        title: 'Job Status Updated',
        body: 'Your job $jobId status changed to $status.',
        type: 'job_status_update',
        data: {'jobId': jobId, 'status': status},
      );
      // Send notification to worker
      if (workerId != null) {
        await createNotification(
          userId: workerId,
          title: 'Job Status Updated',
          body: 'A job you are working on ($jobId) changed to $status.',
          type: 'job_status_update',
          data: {'jobId': jobId, 'status': status},
        );
      }
      return true;
    } catch (e) {
      print('🔥 Error updating job status: $e');
      return false;
    }
  }

  Future<bool> checkDayAvailability(String workerId, DateTime date) async {
    try {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      print('🔍 Checking availability for worker: $workerId on $dateString');

      final snapshot = await _firestore
          .collection('professionals')
          .doc(workerId)
          .collection('availability')
          .doc(dateString)
          .get();

      if (!snapshot.exists) {
        print('❌ Document does NOT exist for $workerId on $dateString');
        return true; // Default to available if document doesn't exist
      }

      final data = snapshot.data();
      if (data == null || !data.containsKey('isAvailable')) {
        print('⚠️ "isAvailable" field missing for $workerId on $dateString');
        return true; // Default to available if field is missing
      }

      final isAvailable = data['isAvailable'] as bool? ?? true;
      print('✅ Availability for $workerId on $dateString: $isAvailable');
      return isAvailable;
    } catch (e) {
      print('🔥 Error checking availability for $workerId on : $e');
      return false; // Default to unavailable on error
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'userId': userId,
            'title': title,
            'body': body,
            'type': type,
            'data': data,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error creating notification: $e');
    }
    _createNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  @Deprecated('Use createNotification instead')
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      print("⚠️ No authenticated user found for notification stream.");
      return Stream.value([]); // Return empty stream if logged out
    }

    final String userId = user.uid; // Store UID for clearer path reference

    try {
      print(
        "👂 Listening for notifications for user $userId at users/$userId/notifications",
      );
      return _firestore
          .collection('users')
          .doc(userId) // Document of the current user
          .collection(
            'notifications',
          ) // Their specific notification subcollection
          .orderBy('createdAt', descending: true) // Show newest first
          .snapshots() // Real-time stream
          .map((snapshot) {
            print(
              "📬 Received notification snapshot with ${snapshot.docs.length} docs for user $userId.",
            );
            // IMPORTANT: Ensure the conversion handles null data gracefully if needed.
            // Using `doc.data()!` asserts non-null, which might crash if a doc is empty.
            // Safer: Check existence or use `?` and default values.
            return snapshot.docs
                .where((doc) => doc.exists) // Filter out potential issues
                .map((doc) {
                  final data = doc.data(); // Now safe to cast
                  data['id'] =
                      doc.id; // *Important:* Add the document ID to the map
                  return data;
                })
                .toList();
          })
          .handleError((error) {
            print("🔥 Error in notification stream for user $userId: $error");
            return <
              Map<String, dynamic>
            >[]; // Return empty list on error to prevent UI crash
          });
    } catch (e) {
      print('🔥 Error setting up notification stream for user $userId: $e');
      return Stream.error(e); // Propagate error to StreamBuilder
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');
      final userId = user.uid;
      final notificationsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications');
      final query = await notificationsRef
          .where(FieldPath.documentId, isEqualTo: notificationId)
          .get();
      if (query.docs.isNotEmpty) {
        await notificationsRef.doc(notificationId).update({'isRead': true});
      } else {
        print(
          'Notification with id $notificationId not found for user $userId',
        );
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Check if a professional is available for work
  Future<bool> checkProfessionalAvailability(String professionalId) async {
    try {
      // Get the professional's active jobs
      final activeJobs = await _firestore
          .collection('jobs')
          .where('workerId', isEqualTo: professionalId)
          .where('status', whereIn: ['in_progress', 'pending', 'working'])
          .get();

      // Get the professional's availability settings (if any)
      final professionalDoc = await _firestore
          .collection('professionals')
          .doc(professionalId)
          .get();

      if (!professionalDoc.exists) {
        return false; // Professional not found
      }

      final data = professionalDoc.data();
      final bool? isAvailable = data?['isAvailable'] as bool?;

      // If professional has explicitly set availability to false, respect that
      if (isAvailable == false) {
        return false;
      }

      // If professional has more than 3 active jobs, consider them unavailable
      if (activeJobs.docs.length >= 3) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking professional availability: $e');
      return false; // Default to unavailable on error
    }
  }

  /// Creates a job request and syncs it across client and professional collections.
  /// Returns the job ID if successful, null if it fails (e.g., pro unavailable).
  Future<String?> createJobRequest({
    required String clientId, // Who's droppin' the gig
    required String professionalId, // Who's pickin' it up
    required String title, // What's the gig called
    required String description, // Spill the deets
    required String location, // Where it's goin' down
    required double budget, // How much ETB we talkin'
    DateTime? scheduledDate, // When it's happenin' (optional)
  }) async {
    try {
      print("🚀 Kickin' off job request creation...");
      print('👤 Client: $clientId | 👨‍💻 Pro: $professionalId');

      // Check if the pro's free when we need 'em
      if (scheduledDate != null) {
        final isAvailable = await checkDayAvailability(
          professionalId,
          scheduledDate,
        );
        if (!isAvailable) {
          print("📅 $professionalId's booked on $scheduledDate—can't do it!");
          return null;
        }
        print("✅ $professionalId's good for $scheduledDate");
      } else {
        final isAvailable = await checkProfessionalAvailability(professionalId);
        if (!isAvailable) {
          print("🚫 $professionalId's too busy right now");
          return null;
        }
        print("✅ $professionalId's ready to roll!");
      }

      // Fetch client and pro profiles—make sure they exist
      print("🔍 Lookin' up client and pro deets...");
      final clientDoc = await _firestore
          .collection('users')
          .doc(clientId)
          .get();
      final proDoc = await _firestore
          .collection('professionals')
          .doc(professionalId)
          .get();

      if (!clientDoc.exists) {
        print("❌ Client $clientId ain't in the system");
        return null;
      }
      if (!proDoc.exists) {
        print("❌ Pro $professionalId ain't found");
        return null;
      }

      final clientData = clientDoc.data() as Map<String, dynamic>;
      final proData = proDoc.data() as Map<String, dynamic>;
      print(
        '👤 Found client: ${clientData['name']} | 👨‍💻 Found pro: ${proData['name']}',
      );

      // Generate a single job ID for all collections
      final jobId = _firestore.collection('jobs').doc().id;
      print('🆔 New job ID: $jobId');

      // Build the job data with fallback vibes
      Map<String, dynamic> jobData = {
        'clientId': clientId,
        'clientName': clientData['name'] ?? 'Mystery Client',
        'clientPhone': clientData['phoneNumber'] ?? 'No Phone',
        'clientEmail': clientData['email'] ?? 'No Email',
        'workerId': professionalId,
        'workerName': proData['name'] ?? 'Unknown Pro',
        'workerPhone': proData['phoneNumber'] ?? 'No Phone',
        'workerExperience': proData['experience'] ?? 0,
        'profession': proData['profession'] ?? 'All-Star',
        'title': title,
        'description': description,
        'location': location,
        'budget': budget,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'scheduledDate': scheduledDate != null
            ? Timestamp.fromDate(scheduledDate)
            : null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'applications': [], // Keep track of who's applyin'
        'priority': budget > 1000
            ? 'high'
            : 'normal', // Extra feature: prioritize big bucks
      };

      // Batch it up—atomic writes for the win
      final batch = _firestore.batch();
      print("📦 Batchin' up the writes...");

      // Main jobs collection
      batch.set(_firestore.collection('jobs').doc(jobId), jobData);

      // Client's side
      batch.set(
        _firestore
            .collection('users')
            .doc(clientId)
            .collection('requests')
            .doc(jobId),
        jobData,
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(clientId)
            .collection('jobs')
            .doc(jobId),
        jobData,
      );

      // Pro's side
      batch.set(
        _firestore
            .collection('professionals')
            .doc(professionalId)
            .collection('requests')
            .doc(jobId),
        jobData,
      );
      batch.set(
        _firestore
            .collection('professionals')
            .doc(professionalId)
            .collection('jobs')
            .doc(jobId),
        jobData,
      );

      // Lock the date if scheduled
      if (scheduledDate != null) {
        final dateString =
            '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
        batch.set(
          _firestore
              .collection('professionals')
              .doc(professionalId)
              .collection('availability')
              .doc(dateString),
          {
            'isAvailable': false,
            'updatedAt': FieldValue.serverTimestamp(),
            'jobId': jobId, // Link it to this job—extra dope feature
          },
          SetOptions(merge: true),
        );
        print('📅 Locked $dateString for $professionalId');
      }

      // Commit the batch—make it official
      await batch.commit();
      print('✅ Job $jobId is live across all collections!');

      // Notify the pro with some swagger
      await createNotification(
        userId: professionalId,
        title: 'Yo, New Gig Dropped!',
        body:
            '$title just came in—${clientData['name'] ?? 'someone'} needs you!',
        type: 'job_request',
        data: {
          'jobId': jobId,
          'budget': budget,
          'scheduledDate': scheduledDate?.toIso8601String(),
        },
      );
      print('🔔 Pro $professionalId got the memo!');

      return jobId;
    } catch (e) {
      print("🔥 Whoops, somethin' broke: $e");
      return null;
    }
  }

  Future<List<Job>> getRequestedJobs(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('requests')
          // Add this filter if you have a request flag
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Job.fromFirestore(data..['id'] = doc.id); // Include document ID
      }).toList();
    } catch (e) {
      print('Error fetching requested jobs: $e');
      return [];
    }
  }

  // Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }

  // Get job applicants
  Future<List<Map<String, dynamic>>> getJobApplicants(String jobId) async {
    try {
      // Get job to retrieve applicant IDs
      DocumentSnapshot jobDoc = await _firestore
          .collection('jobs')
          .doc(jobId)
          .get();
      if (!jobDoc.exists) return [];

      Map<String, dynamic> jobData = jobDoc.data() as Map<String, dynamic>;
      List<dynamic> applicantIds = jobData['applications'] ?? [];

      if (applicantIds.isEmpty) return [];

      List<Map<String, dynamic>> applicants = [];

      // Get worker data for each applicant
      for (String applicantId in applicantIds) {
        DocumentSnapshot workerDoc = await _firestore
            .collection('professionals')
            .doc(applicantId)
            .get();
        if (workerDoc.exists) {
          Map<String, dynamic> workerData =
              workerDoc.data() as Map<String, dynamic>;
          workerData['id'] = applicantId;
          applicants.add(workerData);
        }
      }

      return applicants;
    } catch (e) {
      print('Error getting job applicants: $e');
      return [];
    }
  }

  // In FirebaseService
  Future<List<Map<String, dynamic>>> getWorkerReviews(String workerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('professionals')
          .doc(workerId)
          .collection('reviews')
          .where('workerId', isEqualTo: workerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting worker reviews: $e');
      return [];
    }
  }

  // Fetch worker's rating
  Future<double> getWorkerRating(String workerId) async {
    final doc = await _firestore.collection('workers').doc(workerId).get();
    return doc.data()?['rating']?.toDouble() ?? 0.0;
  }

  // Check worker's general availability
  Future<bool> getProfessionalAvailability(String workerId) async {
    final doc = await _firestore.collection('workers').doc(workerId).get();
    return doc.data()?['isAvailable'] ?? false;
  }

  // Check availability for a specific day
  Future<bool> getDayAvailability(String workerId, DateTime date) async {
    final snapshot = await _firestore
        .collection('workers')
        .doc(workerId)
        .collection('availability')
        .where('date', isEqualTo: date.toIso8601String().split('T')[0])
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Fetch time slots for a specific day
  Future<List<bool>> getTimeSlots(String workerId, DateTime date) async {
    // Example: Return availability for 9 time slots (e.g., 9 AM to 5 PM)
    final snapshot = await _firestore
        .collection('workers')
        .doc(workerId)
        .collection('availability')
        .doc(date.toIso8601String().split('T')[0])
        .get();
    final slots = snapshot.data()?['timeSlots'] as List<dynamic>?;
    return slots?.map((slot) => slot as bool).toList() ?? List.filled(9, true);
  }

  Future<void> acceptJobApplication(
    String jobId,
    String workerId,
    String clientId,
  ) async {
    // Create a batch write to ensure all operations succeed or fail together
    final batch = _firestore.batch();
    print('this is from acceptjobapplication  ::: id of client $clientId');

    // 1. Update the main job document
    final jobRef = _firestore.collection('jobs').doc(jobId);
    batch.update(jobRef, {
      'status': 'assigned',
      'workerId': workerId,
      'assignedAt': FieldValue.serverTimestamp(),
    }); // Use merge to update or create if doesn't exist

    // 2. Add to worker's assigned jobs subcollection
    final workerJobRef = _firestore
        .collection('professionals')
        .doc(workerId)
        .collection('assigned_jobs')
        .doc(jobId);
    final userjobRef = _firestore
        .collection('users')
        .doc(clientId)
        .collection('jobs')
        .doc(jobId);
    batch.set(workerJobRef, {
      'jobId': jobId,
      'status': 'assigned',
      'assignedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(userjobRef, {
      'jobId': jobId,
      'status': 'assigned',
      'assignedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Update worker's document with assigned jobs array
    final workerRef = _firestore.collection('professionals').doc(workerId);
    batch.update(workerRef, {
      'assignedJobs': FieldValue.arrayUnion([jobId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
      print('Job $jobId successfully assigned to worker $workerId');
    } catch (e) {
      print('Error assigning job: $e');
      throw 'Failed to assign job: $e';
    }
  }

  Future<List<Job>> getworkersactivejob(String userID) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'assigned')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting worker assigned jobs: $e');
      return [];
    }
  }

  Future<List<Job>> getWorkerAssignedJobs(String workerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('professionals')
          .doc(workerId)
          .collection('jobs')
          .where('status', isEqualTo: 'assigned')
          .orderBy('createdAt', descending: true)
          .get();
      print('this is worker id form getworkereassignedjobs$workerId');
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting worker assigned jobs: $e');
      return [];
    }
  }

  Future<String?> uploadJobAttachment({
    required PlatformFile platformFile, // Input is PlatformFile
    required String userId, // User ID for path structure
  }) async {
    if (userId.isEmpty) {
      print('Error uploading job attachment: User ID is empty.');
      return null;
    }

    // *** CHOOSE YOUR BUCKET NAME - Must exist in Supabase, be public, have INSERT policy ***
    const String jobAttachmentsBucket = 'job-attachments'; // Example name
    final String fileName = platformFile.name.replaceAll(
      RegExp(r'\s+'),
      '_',
    ); // Sanitize name
    // Path structure: public/jobs/user_id/timestamp_filename.ext
    final String filePath =
        'public/jobs/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    print('Uploading job attachment to Supabase Storage...');
    print('  File Name: ${platformFile.name}');
    print('  Bucket: $jobAttachmentsBucket');
    print('  Path in bucket: $filePath');

    try {
      // Determine content type
      final String? mimeType = lookupMimeType(
        platformFile.name,
        headerBytes: platformFile.bytes?.take(1024).toList(),
      );
      final fileOptions = FileOptions(
        cacheControl: '3600', // Cache for 1 hour
        upsert: false, // Don't overwrite files
        contentType: mimeType, // Set content type
      );
      print('  Detected MIME type: $mimeType');

      if (kIsWeb) {
        // WEB Upload using bytes
        if (platformFile.bytes == null) {
          throw Exception('File bytes are null for web upload.');
        }
        print('  Uploading using bytes (Web)...');
        // Use uploadBinary for web byte arrays
        await _supabaseClient.storage
            .from(jobAttachmentsBucket)
            .uploadBinary(
              filePath,
              platformFile.bytes!,
              fileOptions: fileOptions,
            );
      } else {
        // MOBILE/DESKTOP Upload using path
        if (platformFile.path == null) {
          throw Exception('File path is null for mobile upload.');
        }
        print('  Uploading using path (Mobile/Desktop)...');
        final file = File(platformFile.path!);
        // Use upload for mobile File objects
        await _supabaseClient.storage
            .from(jobAttachmentsBucket)
            .upload(filePath, file, fileOptions: fileOptions);
      }

      print('Supabase attachment upload successful. Getting public URL...');

      // Get the public URL for the uploaded file
      final imageUrlResponse = _supabaseClient.storage
          .from(jobAttachmentsBucket)
          .getPublicUrl(filePath);

      final imageUrl = imageUrlResponse; // URL is the string itself
      print('Supabase Job Attachment URL: $imageUrl');
      return imageUrl;
    } on StorageException catch (e) {
      // Catch specific Supabase errors
      print('[Supabase Storage Error - Job Attachment]');
      print(
        '  Message: ${e.message}',
      ); // This will show bucket not found or RLS errors
      print('  Error details: ${e.error ?? 'N/A'}');
      print('  Status code: ${e.statusCode ?? 'N/A'}');
      return null;
    } catch (e, s) {
      print('[General Error during Supabase job attachment upload]');
      print('  Error: $e');
      print('  Stack Trace: $s');
      return null;
    }
  }

  // Create payment record
  Future<void> createPaymentRecord({
    required String jobId,
    required double amount,
    required String paymentMethod,
    required String status,
    required String transactionId,
    required String workerID,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      await _firestore.collection('payments').add({
        'jobId': jobId,
        'userId': user.uid,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'transactionId': transactionId,
      });
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
            'jobId': jobId,
            'amount': amount,
            'paymentMethod': paymentMethod,
            'status': status,
            'timestamp': FieldValue.serverTimestamp(),
            'transactionId': transactionId,
          });
      await _firestore.collection('users').doc(user.uid).set({
        'completedJobs': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('jobs')
          .doc(jobId)
          .update({'status': 'paycompleted'});
      await _firestore
          .collection('professionals')
          .doc(workerID)
          .collection('jobs')
          .doc(jobId)
          .update({'status': 'paycompleted'});
      print('Incremented completedJobs for user ${user.uid}');
    } catch (e) {
      print('Error creating payment record: $e');
      rethrow;
    }
  }
}
