import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class ApiService {
  static Future<String> getAIResponse(String userMessage) async {
    final bool needsWebSearch = _needsWebSearch(userMessage);
    String webSearchResults = "";

    if (needsWebSearch) {
      webSearchResults = await _performWebSearch(userMessage);
    }

    return _callGeminiAPI(userMessage, webSearchResults);
  }

  static Future<String> getAIResponseWithImage(File imageFile) async {
    try {
      final deviceInfo = await _analyzeImage(imageFile);
      final String searchQuery = "recycling $deviceInfo e-waste components";
      final webSearchResults = await _performWebSearch(searchQuery);

      return _callGeminiAPIWithImage(
          "This is a photo of my electronic device. Can you identify it and provide recycling advice?",
          webSearchResults,
          imageFile);
    } catch (e) {
      print("Error processing image: $e");
      return "Sorry, I couldn't process that image. Please try again or describe the device to me.";
    }
  }

  static String getMimeType(File imageFile) {
    final String path = imageFile.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (path.endsWith('.png')) {
      return 'image/png';
    } else if (path.endsWith('.gif')) {
      return 'image/gif';
    } else if (path.endsWith('.bmp')) {
      return 'image/bmp';
    } else if (path.endsWith('.webp')) {
      return 'image/webp';
    } else {
      return 'image/jpeg';
    }
  }

  static Future<String> _analyzeImage(File imageFile) async {
    try {
      final Uri visionApiUrl = Uri.parse(
          "https://vision.googleapis.com/v1/images:annotate?key=${Secrets.googleApiKey}");

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        visionApiUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "LABEL_DETECTION", "maxResults": 10},
                {"type": "OBJECT_LOCALIZATION", "maxResults": 5}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> labels = [];
        if (data['responses'][0].containsKey('labelAnnotations')) {
          labels = (data['responses'][0]['labelAnnotations'] as List)
              .map((label) => label['description'] as String)
              .toList();
        }

        List<String> objects = [];
        if (data['responses'][0].containsKey('localizedObjectAnnotations')) {
          objects = (data['responses'][0]['localizedObjectAnnotations'] as List)
              .map((obj) => obj['name'] as String)
              .toList();
        }

        final allItems = [...objects, ...labels];
        final relevantItems =
            allItems.where((item) => _isElectronicDevice(item)).toList();

        if (relevantItems.isNotEmpty) {
          return relevantItems.join(", ");
        } else if (allItems.isNotEmpty) {
          return allItems.take(5).join(", ");
        } else {
          return "electronic device";
        }
      } else {
        print("Vision API Error: ${response.statusCode} - ${response.body}");
        return "electronic device";
      }
    } catch (e) {
      print("Image analysis error: $e");
      return "electronic device";
    }
  }

  static bool _isElectronicDevice(String item) {
    final electronicKeywords = [
      'phone',
      'smartphone',
      'iphone',
      'android',
      'samsung',
      'laptop',
      'computer',
      'monitor',
      'tv',
      'television',
      'screen',
      'tablet',
      'ipad',
      'keyboard',
      'mouse',
      'printer',
      'scanner',
      'camera',
      'headphone',
      'earphone',
      'speaker',
      'microphone',
      'charger',
      'adapter',
      'cable',
      'battery',
      'electronic',
      'device',
      'gadget',
      'appliance',
      'console',
      'playstation',
      'xbox',
      'nintendo',
      'wii',
      'router',
      'modem',
      'cpu',
      'processor',
      'circuit',
      'board',
      'motherboard',
      'hard drive',
      'ssd',
      'memory',
      'ram'
    ];
    return electronicKeywords
        .any((keyword) => item.toLowerCase().contains(keyword));
  }

  static bool _needsWebSearch(String userMessage) {
    final modelPatterns = RegExp(
        r'(iphone|samsung|galaxy|macbook|dell|hp|lenovo|acer|asus|model|XPS|thinkpad|pixel)',
        caseSensitive: false);
    final queryPatterns = RegExp(
        r'(how|where|what|when|which|recycling center|repair shop|toxic|components|trade-in|program)',
        caseSensitive: false);
    return modelPatterns.hasMatch(userMessage) ||
        queryPatterns.hasMatch(userMessage);
  }

  static Future<String> _performWebSearch(String query) async {
    try {
      final searchQuery = "$query e-waste recycling components repair";
      final Uri searchUrl = Uri.parse(
          "https://www.googleapis.com/customsearch/v1?key=${Secrets.googleApiKey}&cx=${Secrets.searchEngineId}&q=${Uri.encodeComponent(searchQuery)}");

      final response = await http.get(searchUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String results = "Web search results:\n\n";
        if (data.containsKey('items') &&
            data['items'] is List &&
            data['items'].isNotEmpty) {
          final items = data['items'].take(3);
          for (var item in items) {
            results += "Title: ${item['title']}\n";
            results += "Snippet: ${item['snippet']}\n";
            results += "URL: ${item['link']}\n\n";
          }
        } else {
          results += "No specific information found for this query.\n";
        }
        return results;
      } else {
        print("Search API Error: ${response.statusCode} - ${response.body}");
        return "Couldn't retrieve specific information from the web.";
      }
    } catch (e) {
      print("Web search exception: $e");
      return "Error performing web search.";
    }
  }

  static Future<String> _callGeminiAPI(
      String userMessage, String webSearchResults) async {
    final Uri url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${Secrets.apiKey}");

    String systemPrompt = """
You are an AI assistant integrated into the EcoByte app, developed by VioniX, to guide users in responsible e-waste management through repair, recycling, and proper disposal. Your responses must align with UN SDG 12: Responsible Consumption and Production, promoting sustainable practices to reduce waste.

LOCATION PRIORITY:
- By default, provide responses tailored to India (e.g., recycling centers, regulations, or programs in India) unless the user explicitly requests information for another region.
- If a different region is specified, adapt the response to that location and use relevant web search data if available.

GUIDELINES:
- Always keep responses structured, short, and easy to understand using bullet points (•) or dashes (-).
- Provide only necessary details in a concise and readable format.
- Match your response style to the query type - simple questions get simple answers.

RESPONSE TYPES:
1. BASIC DEFINITIONS/CONCEPTS:
   - Provide brief, direct definitions without repair/recycling advice
   - Include only relevant information to answer the specific question
   - Do not add repair steps or disposal information for simple definition questions

2. DEVICE-SPECIFIC QUERIES:
   - When user provides a specific device model:
     • Use web search results to find key components (batteries, circuit boards, metals, plastics)
     • Identify possible recyclable uses
     • Mention toxic chemicals released if improperly disposed
     • Structure response with only relevant details
   - Provide repair information first, then recycling/disposal options (India-focused unless specified)

3. REPAIR INQUIRIES:
   - If the user asks about repairs:
     • Suggest common fixes
     • Mention useful YouTube tutorials available
     • Reference official service centers with manufacturer website links when possible (India-specific unless otherwise stated)
     • Emphasize repair benefits before recycling

4. RECYCLING & DISPOSAL INQUIRIES:
   - When explicitly asked about recycling or disposal:
     • Suggest certified e-waste recycling centers or collection points in India (e.g., E-Waste Recyclers India, Attero, or local municipal programs)
     • Mention relevant trade-in programs (e.g., Apple India, Samsung India, etc.)
     • Explain safe disposal methods to prevent toxic waste release, per Indian regulations
     • Adapt to other regions only if specified

FORMATTING:
- Use bullet points for readability in complex responses
- Keep simple definitional responses as brief paragraphs without unnecessary bullet points
- Match response complexity to question complexity
- Only include repair, recycling AND disposal information together when the query is general and requires all three
""";

    if (webSearchResults.isNotEmpty) {
      systemPrompt +=
          "\n\nUSE THIS WEB SEARCH INFORMATION IN YOUR RESPONSE. IF HELPFUL, INCLUDE THE URLs TO RELEVANT SOURCES.";
      systemPrompt += "\n\n$webSearchResults";
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": systemPrompt},
                {"text": userMessage}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.2,
            "topP": 0.8,
            "topK": 40,
            "maxOutputTokens": 800,
          },
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          return data["candidates"][0]["content"]["parts"][0]["text"] ??
              "Sorry, I couldn't generate a response.";
        } catch (e) {
          print("JSON parsing error: $e");
          print("Response data: $data");
          return "Sorry, I couldn't process that response. Please try again.";
        }
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        return "Sorry, I'm having trouble connecting to my knowledge base. Please try again later.";
      }
    } catch (e) {
      print("Network exception: $e");
      return "Network error. Please check your connection and try again.";
    }
  }

  static Future<String> _callGeminiAPIWithImage(
      String userMessage, String webSearchResults, File imageFile) async {
    final Uri url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${Secrets.apiKey}");

    String systemPrompt = """
You are an AI assistant integrated into the EcoByte app, developed by VioniX, to guide users in responsible e-waste management through repair, recycling, and proper disposal. Your responses must align with UN SDG 12: Responsible Consumption and Production, promoting sustainable practices to reduce waste.

LOCATION PRIORITY:
- By default, provide responses tailored to India (e.g., recycling centers, regulations, or programs in India) unless the user explicitly requests information for another region.
- If a different region is specified, adapt the response to that location and use relevant web search data if available.

WHEN RESPONDING TO IMAGES:
- First identify the device or electronic component in the image
- Provide information about common components in this type of device
- Explain how to properly recycle or dispose of this specific item (India-focused unless specified)
- Highlight any hazardous materials that may be present
- Suggest repair options if applicable (India-specific unless otherwise stated)

GUIDELINES:
- Always keep responses structured, short, and easy to understand using bullet points (•) or dashes (-).
- Provide only necessary details in a concise and readable format.
- Match your response style to the query type - simple questions get simple answers.

FORMATTING:
- Use bullet points for readability in complex responses
- Keep simple definitional responses as brief paragraphs without unnecessary bullet points
- Match response complexity to question complexity
- Only include repair, recycling AND disposal information together when the query is general and requires all three
""";

    if (webSearchResults.isNotEmpty) {
      systemPrompt +=
          "\n\nUSE THIS WEB SEARCH INFORMATION IN YOUR RESPONSE. IF HELPFUL, INCLUDE THE URLs TO RELEVANT SOURCES.";
      systemPrompt += "\n\n$webSearchResults";
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = getMimeType(imageFile);

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": systemPrompt},
                {"text": userMessage},
                {
                  "inline_data": {"mime_type": mimeType, "data": base64Image}
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.2,
            "topP": 0.8,
            "topK": 40,
            "maxOutputTokens": 800,
          },
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          return data["candidates"][0]["content"]["parts"][0]["text"] ??
              "Sorry, I couldn't generate a response.";
        } catch (e) {
          print("JSON parsing error: $e");
          print("Response data: $data");
          return "Sorry, I couldn't process that response. Please try again.";
        }
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        return "Sorry, I'm having trouble analyzing the image. Please try again later.";
      }
    } catch (e) {
      print("Network exception: $e");
      return "Network error. Please check your connection and try again.";
    }
  }
}
