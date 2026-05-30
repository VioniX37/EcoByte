import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WebSearchService {
  static Future<String> performWebSearch(String query) async {
    try {
      final searchQuery = "$query e-waste recycling components repair";
      final Uri searchUrl = Uri.parse(
          "https://www.googleapis.com/customsearch/v1?key=${dotenv.get('GOOGLE_API_KEY')}&cx=${dotenv.get('SEARCH_ENGINE_ID')}&q=${Uri.encodeComponent(searchQuery)}");

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
}
