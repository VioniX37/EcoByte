import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/device_keywords.dart';

class VisionService {
  static Future<String> analyzeImage(File imageFile) async {
    try {
      final Uri visionApiUrl = Uri.parse(
          "https://vision.googleapis.com/v1/images:annotate?key=${dotenv.get('GOOGLE_API_KEY')}");

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
            allItems.where((item) => DeviceKeywords.isElectronicDevice(item)).toList();

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
}
