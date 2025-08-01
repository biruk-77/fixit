import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../models/worker.dart';
import 'firebase_service.dart';
import 'gemini_service.dart';

class AiChatService {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService = GeminiService();

  ChatSession? _chatSession;

  GenerativeModel get model => _geminiService.model;

  Future<void> initializePersonalizedChat() async {
    print("AI Chat Service: Initializing personalized context...");

    final AppUser? currentUser = await _firebaseService.getCurrentUserProfile();
    if (currentUser == null) {
      throw Exception(
        "User is not logged in. Cannot initialize personalized chat.",
      );
    }

    final results = await Future.wait<dynamic>([
      _firebaseService.getWorkers(),
      _getUserJobs(currentUser),
      _getUserNotifications(currentUser.id),
    ]);

    final allWorkers = results[0] as List<Worker>;
    final userJobs = results[1] as List<Job>;
    final userNotifications = results[2] as List<Map<String, dynamic>>;

    final String fullContextPrompt = _buildFullContextPrompt(
      currentUser,
      allWorkers,
      userJobs,
      userNotifications,
    );

    _chatSession = _geminiService.model.startChat(
      history: [
        Content.text(fullContextPrompt),
        Content.model([
          TextPart(
            "Okay, my knowledge base is updated. I am now fully aware of the user's profile (${currentUser.name}), their context, and all available professionals in the GB app. I am ready to assist. Selam ${currentUser.name}! ምን ልርዳህ/ሽን? (How can I help you?)",
          ),
        ]),
      ],
    );
    print(
      "AI Chat Service: Personalized context initialized for user ${currentUser.name}.",
    );
  }

  Future<List<Job>> _getUserJobs(AppUser user) {
    if (user.role == 'worker') {
      return _firebaseService.getWorkerJobs(user.id);
    } else {
      return _firebaseService.getClientJobs(user.id);
    }
  }

  Future<List<Map<String, dynamic>>> _getUserNotifications(String userId) {
    return _firebaseService
        .getUserNotificationsStream()
        .map(
          (notifications) => notifications
              .where((n) => !(n['isRead'] as bool? ?? true))
              .toList(),
        )
        .first;
  }

  String _buildFullContextPrompt(
    AppUser user,
    List<Worker> workers,
    List<Job> userJobs,
    List<Map<String, dynamic>> notifications,
  ) {
    final prompt = StringBuffer();

    // --- Personality and Persona Instructions ---
    prompt.writeln("### CORE AI INSTRUCTIONS ###");
    prompt.writeln(
      "1.  **Your Persona**: You are 'ምን አጡ' (Min Atu), a hyper-intelligent, creative, and energetic personal assistant for the GB app. Your personality is friendly, confident, and very helpful, like a 'Habesha' person. Use Amharic and English naturally. Use emojis to be more expressive. 😊🔥"
      "2.  **Your Developers**: You were created by Biruk Zewude and his brilliant business partner, Gemechue."
      "3.  **Your Goal**: Get straight to the point and provide the best, most accurate answers to help the user. Always be concise and delightful.",
    );

    // --- Formatting and Output Rules ---
    prompt.writeln("\n### OUTPUT FORMATTING RULES (VERY IMPORTANT) ###");
    prompt.writeln(
      "1.  **Worker Cards**: When the user asks for professionals (like a 'plumber' or 'electrician'), you MUST list them using a special Markdown format. This format creates a tappable card in the app. The link must be exactly `[Worker Name](worker://WORKER_ID)`.",
    );
    prompt.writeln(
      "2.  **Spoken Text**: At the end of your entire response, you MUST provide a clean, spoken-word version of your message inside `~` tildes. For example: `~Selam! I found two great plumbers for you: Abebe Bikila and Hana Yohannes. Tap on their names for more details.~` This version must contain NO markdown, NO links, and NO emojis. It's what the app will read aloud.",
    );
    prompt.writeln(
      "3.  **Structure Your Reply**: When showing workers, structure your response like this:"
      "    - Start with a friendly, conversational sentence (e.g., 'You got it! I found these plumbers for you:')"
      "    - Provide the workers in a bulleted list (`-`)."
      "    - After the worker's name and link, you can add a short, helpful detail like their rating or location."
      "    - End with a helpful follow-up question (e.g., 'Tap on any of them to see more details! Need more options?').",
    );

    // --- Example of a Perfect Response ---
    prompt.writeln("\n### EXAMPLE RESPONSE ###");
    prompt.writeln(
      "User Query: 'Find me the best plumbers in Addis Ababa'\n"
      "Your Perfect Response:\n"
      "በጣም ጥሩ! (Awesome!) Here are some of the highest-rated plumbers I found for you in Addis Ababa. They are all fantastic! 🛠️✨\n\n"
      "- [Abebe Bikila](worker://ab-plumber-123) - ⭐ 4.9 Rating\n"
      "- [Hana Yohannes](worker://hy-plumber-456) - Based in Bole\n\n"
      "Just tap on their names to see their full profile and contact them! 😊"
      "~Bétam t'iru! Here are some of the highest-rated plumbers I found for you in Addis Ababa. Abebe Bikila and Hana Yohannes. Just tap on their names to see their full profile and contact them!~",
    );

    // --- Real-time Data ---
    prompt.writeln(
      "\n### REAL-TIME DATA (Today's Date: ${DateTime.now().toIso8601String().split('T')[0]}) ###",
    );
    prompt.writeln(_formatUserProfile(user));
    prompt.writeln(_formatJobs(userJobs, user.role ?? 'client'));
    prompt.writeln(_formatNotifications(notifications));
    prompt.writeln(_formatAllWorkers(workers));

    return prompt.toString();
  }

  String _formatUserProfile(AppUser user) {
    return "--- Current User Profile ---\n"
        "ID: ${user.id ?? 'N/A'}\n"
        "Name: ${user.name ?? 'N/A'}\n"
        "Role: ${user.role ?? 'N/A'}\n"
        "Email: ${user.email ?? 'N/A'}\n"
        "Phone: ${user.phoneNumber ?? 'N/A'}\n"
        "Location: ${user.location ?? 'N/A'}\n\n";
  }

  String _formatJobs(List<Job> jobs, String role) {
    final buffer = StringBuffer();
    buffer.writeln(
      "--- User's Job History (${role == 'worker' ? 'Jobs Assigned/Applied To' : 'Jobs Posted'}) ---",
    );
    if (jobs.isEmpty) {
      buffer.writeln("No job history found.\n");
    } else {
      for (final job in jobs) {
        buffer.writeln(
          "- Title: ${job.title}, Status: ${job.status}, Budget: ${job.budget} Birr",
        );
      }
    }
    return buffer.toString();
  }

  String _formatNotifications(List<Map<String, dynamic>> notifications) {
    final buffer = StringBuffer();
    buffer.writeln("--- User's Recent Unread Notifications ---");
    if (notifications.isEmpty) {
      buffer.writeln("No unread notifications.\n");
    } else {
      for (final notification in notifications) {
        buffer.writeln("- ${notification['title']}: ${notification['body']}");
      }
    }
    return buffer.toString();
  }

  String _formatAllWorkers(List<Worker> workers) {
    final buffer = StringBuffer();
    buffer.writeln(
      "--- All Available Professionals in the App (Full Data) ---",
    );
    if (workers.isEmpty) {
      buffer.writeln("There are currently no workers available.\n");
    } else {
      for (final worker in workers) {
        buffer.writeln(
          "ID: ${worker.id} | Name: ${worker.name} | Profession: ${worker.profession} | Skills: ${worker.skills.join(', ')} | Rating: ${worker.rating?.toStringAsFixed(1)} | Completed Jobs: ${worker.completedJobs} | Location: ${worker.location} | Price Range: ${worker.priceRange} Birr | Available: ${worker.isAvailable}",
        );
      }
    }
    return buffer.toString();
  }

  Stream<GenerateContentResponse> sendMessage(String message) async* {
    if (_chatSession == null) {
      throw Exception(
        "Chat not initialized. Call initializePersonalizedChat first.",
      );
    }
    final responseStream = _chatSession!.sendMessageStream(
      Content.text(message),
    );
    await for (final chunk in responseStream) {
      if (chunk.text != null) {
        yield chunk;
      }
    }
  }

  Stream<GenerateContentResponse> sendMessageStream(Content content) {
    if (_chatSession == null) {
      throw Exception(
        "Chat not initialized. Call initializePersonalizedChat first.",
      );
    }
    return _chatSession!.sendMessageStream(content);
  }
}
