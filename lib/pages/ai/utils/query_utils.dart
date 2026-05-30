class QueryUtils {
  static bool needsWebSearch(String userMessage) {
    final modelPatterns = RegExp(
        r'(iphone|samsung|galaxy|macbook|dell|hp|lenovo|acer|asus|model|XPS|thinkpad|pixel)',
        caseSensitive: false);
    final queryPatterns = RegExp(
        r'(how|where|what|when|which|recycling center|repair shop|toxic|components|trade-in|program)',
        caseSensitive: false);
    return modelPatterns.hasMatch(userMessage) ||
        queryPatterns.hasMatch(userMessage);
  }
}
