import 'dart:io';
import 'services/gemini_service.dart';
import 'services/vision_service.dart';
import 'services/web_search_service.dart';
import 'utils/mime_type_util.dart' as mime;
import 'utils/query_utils.dart';

class ApiService {
  static Future<String> getAIResponse(String userMessage) async {
    final bool needsWebSearch = QueryUtils.needsWebSearch(userMessage);
    String webSearchResults = "";
    if (needsWebSearch) {
      webSearchResults = await WebSearchService.performWebSearch(userMessage);
    }

    return GeminiService.callGeminiAPI(userMessage, webSearchResults);
  }

  static Future<String> getAIResponseWithImage(File imageFile) async {
    try {
      final deviceInfo = await VisionService.analyzeImage(imageFile);
      final String searchQuery = "recycling $deviceInfo e-waste components";
      final webSearchResults =
          await WebSearchService.performWebSearch(searchQuery);

      return GeminiService.callGeminiAPIWithImage(
        "This is a photo of my electronic device. Can you identify it and provide recycling advice?",
        webSearchResults,
        imageFile,
      );
    } catch (e) {
      print("Error processing image: $e");
      return "Sorry, I couldn't process that image. Please try again or describe the device to me.";
    }
  }

  static String getMimeType(File imageFile) {
    return mime.getMimeType(imageFile);
  }
}
