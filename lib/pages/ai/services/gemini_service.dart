import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/mime_type_util.dart';

class GeminiService {
  static Future<String> callGeminiAPI(
      String userMessage, String webSearchResults) async {
    final Uri url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${dotenv.get('GEMINI_API_KEY')}");

    String systemPrompt = GeminiPrompts.textPrompt(webSearchResults);

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

  static Future<String> callGeminiAPIWithImage(
      String userMessage, String webSearchResults, File imageFile) async {
    final Uri url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${dotenv.get('GEMINI_API_KEY')}");

    String systemPrompt = GeminiPrompts.imagePrompt(webSearchResults);

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

class GeminiPrompts {
  static String textPrompt(String webSearchResults) {
    String prompt = """
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
      prompt +=
          "\n\nUSE THIS WEB SEARCH INFORMATION IN YOUR RESPONSE. IF HELPFUL, INCLUDE THE URLs TO RELEVANT SOURCES.";
      prompt += "\n\n$webSearchResults";
    }
    return prompt;
  }

  static String imagePrompt(String webSearchResults) {
    String prompt = """
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
      prompt +=
          "\n\nUSE THIS WEB SEARCH INFORMATION IN YOUR RESPONSE. IF HELPFUL, INCLUDE THE URLs TO RELEVANT SOURCES.";
      prompt += "\n\n$webSearchResults";
    }
    return prompt;
  }
}
