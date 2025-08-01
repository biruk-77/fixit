import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Make sure this key is correct and has the Vertex AI API enabled in your Google Cloud project.
  static const String _apiKey = 'AIzaSyD6xWiEtZiq3rD0-gb7-VefOm3VlFz0ecg';

  // Public getter for the API key (to be used by AiChatService)
  String get apiKey => _apiKey; // <-- NEW: Public getter for API key

  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Initialize the GenerativeModel with tools directly here
  final GenerativeModel _model = GenerativeModel(
    model: 'models/gemini-2.5-flash',
    apiKey: _apiKey,
    safetySettings: [
      // Add back safety settings if you removed them
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
    ],
  );

  GenerativeModel get model => _model;

  Future<String?> generateText(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print("GeminiService Error: $e");
      return "An error occurred while connecting to the AI.";
    }
  }
}
