import 'package:flutter/material.dart';
import '../../models/worker.dart';
import '../../services/firebase_service.dart';

class QuickJobRequestScreen extends StatefulWidget {
  final Worker worker;

  const QuickJobRequestScreen({
    super.key,
    required this.worker,
  });

  @override
  _QuickJobRequestScreenState createState() => _QuickJobRequestScreenState();
}

class _QuickJobRequestScreenState extends State<QuickJobRequestScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for the input fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.worker.location;
    _budgetController.text = widget.worker.priceRange.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // Date picker with a sleek dark theme
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.tealAccent,
            onPrimary: Colors.black,
            surface: Color(0xFF141414),
            onSurface: Colors.white70,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.tealAccent,
            ),
          ),
          dialogTheme:
              DialogThemeData(backgroundColor: const Color(0xFF080808)),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // Submit the job request with swagger
  Future<void> _submitJobRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      setState(() => _errorMessage = 'Yo, pick a date for the person!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = await _firebaseService.getCurrentUserProfile();
      if (currentUser == null) throw "Can't grab your profile, fam!";

      final clientId = currentUser.id;

      final jobId = await _firebaseService.createJobRequest(
        clientId: clientId,
        professionalId: widget.worker.id,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        budget: double.parse(_budgetController.text),
        scheduledDate: _selectedDate,
      );

      if (jobId == null) {
        setState(() {
          _errorMessage =
              "❌ Unfortunately, \n 🚫 the pro is unavailable on this date. 📅 Please choose another.";
          _isLoading = false;
        });
        return;
      }

      // Send notification to client (current user)
      await _firebaseService.createNotification(
        userId: clientId,
        title: "Job Request Submitted",
        body: "Your job request for '${_titleController.text}' has been sent!",
        type: "job_request_submitted",
        data: {
          'jobId': jobId,
          'title': _titleController.text,
          'workerId': widget.worker.id,
          'scheduledDate': _selectedDate?.toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'person $jobId sent—boom!',
              style: const TextStyle(color: Colors.tealAccent),
            ),
            backgroundColor: const Color(0xFF141414),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "🔥 Somethin' broke: $e";
        _isLoading = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(158, 2, 143, 32), // Deep dark base
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Smooth, bouncy scroll
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.tealAccent, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    const Text(
                      'Quick Job Request',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.tealAccent,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.tealAccent, blurRadius: 8)
                        ],
                      ),
                    ),
                  ],
                ),
                // Worker card with neon glow
                SizedBox(height: 25),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: widget.worker.profileImage.isNotEmpty
                            ? NetworkImage(widget.worker.profileImage)
                            : null,
                        backgroundColor: Colors.grey[900],
                        onBackgroundImageError:
                            widget.worker.profileImage.isNotEmpty
                                ? (_, __) {}
                                : null,
                        child: widget.worker.profileImage.isEmpty
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.tealAccent)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.tealAccent,
                                    Colors.cyanAccent
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Selected Pro',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.worker.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              widget.worker.profession,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  widget.worker.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${widget.worker.priceRange.toInt()} ETB/hr',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Error message with a neon alert vibe
                if (_errorMessage != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.redAccent.withOpacity(0.3),
                            blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error,
                            color: Color.fromARGB(255, 215, 190, 190),
                            size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 229, 255, 0),
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Job details header with glow
                const Text(
                  'Job Request',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.tealAccent,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Colors.tealAccent, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 24),

                // Title field with sleek design
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Job Title',
                    hintText: 'e.g., Fix My Sink',
                    labelStyle: const TextStyle(color: Colors.tealAccent),
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon:
                        const Icon(Icons.work, color: Colors.tealAccent),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Gimme a title, fam!' : null,
                ),
                const SizedBox(height: 20),

                // Description field with multi-line swagger
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: "What's the deal with this person?",
                    labelStyle: const TextStyle(color: Colors.tealAccent),
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon:
                        const Icon(Icons.description, color: Colors.tealAccent),
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Spill the deets, yo!' : null,
                ),
                const SizedBox(height: 20),

                // Location field with sharp edges
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: "Location",
                    hintText: "Where's it happenin'?",
                    labelStyle: const TextStyle(color: Colors.tealAccent),
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon:
                        const Icon(Icons.location_on, color: Colors.tealAccent),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Where at, fam?' : null,
                ),
                const SizedBox(height: 20),

                // Budget field with neon money vibes
                TextFormField(
                  controller: _budgetController,
                  decoration: InputDecoration(
                    labelText: "Budget (ETB)",
                    hintText: "How much you droppin'?",
                    labelStyle: const TextStyle(color: Colors.tealAccent),
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: Colors.tealAccent),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Drop some ETB, yo!';
                    if (double.tryParse(value!) == null) {
                      return 'Numbers only, fam!';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Gotta be more than 0!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date picker with a futuristic tap
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.tealAccent),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Pick a Date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button with bold neon swagger
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitJobRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Colors.tealAccent.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                        : const Text(
                            'hire ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
