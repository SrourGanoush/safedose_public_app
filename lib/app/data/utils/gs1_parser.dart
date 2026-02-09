class GS1Parser {
  // Application Identifiers
  static const String AI_GTIN = '01';
  static const String AI_BATCH = '10';
  static const String AI_EXPIRY = '17';
  static const String AI_SERIAL = '21';
  static const String GROUP_SEPARATOR = '\u001D'; // ASCII 29

  static Map<String, String> parse(String code) {
    // Remove potential leading FNC1 equivalents if present in raw string (like ]d2)
    // Some scanners might strip this, others might not.
    // For this implementation, we assume the string starts with the first AI.
    // We can clean up common prefixes if needed.
    var processingCode = code;
    if (processingCode.startsWith(']d2')) {
      processingCode = processingCode.substring(3);
    }

    // Also handle commonly used "human readable" separators if passed manually,
    // but the scanner usually gives raw control codes.
    // If the string contains no group separators but has keys, it might be tricky.

    // Simple state machine parsing
    final result = <String, String>{};
    int index = 0;

    while (index < processingCode.length) {
      if (processingCode.startsWith(AI_GTIN, index)) {
        index += 2; // Skip AI
        // GTIN is fixed 14 digits
        if (index + 14 <= processingCode.length) {
          result['gtin'] = processingCode.substring(index, index + 14);
          index += 14;
        } else {
          // Malformed
          break;
        }
      } else if (processingCode.startsWith(AI_EXPIRY, index)) {
        index += 2;
        // Expiry is fixed 6 digits YYMMDD
        if (index + 6 <= processingCode.length) {
          result['expiry'] = processingCode.substring(index, index + 6);
          index += 6;
        } else {
          break;
        }
      } else if (processingCode.startsWith(AI_BATCH, index)) {
        index += 2;
        // Batch is variable length (up to 20), ended by GS or EOS
        final nextGS = processingCode.indexOf(GROUP_SEPARATOR, index);
        if (nextGS == -1) {
          // No more separators, take until end
          result['batch'] = processingCode.substring(index);
          index = processingCode.length;
        } else {
          result['batch'] = processingCode.substring(index, nextGS);
          index = nextGS + 1; // Skip GS
        }
      } else if (processingCode.startsWith(AI_SERIAL, index)) {
        index += 2;
        // Serial is variable length (up to 20), ended by GS or EOS
        final nextGS = processingCode.indexOf(GROUP_SEPARATOR, index);
        if (nextGS == -1) {
          result['serial'] = processingCode.substring(index);
          index = processingCode.length;
        } else {
          result['serial'] = processingCode.substring(index, nextGS);
          index = nextGS + 1; // Skip GS
        }
      } else {
        // Unknown AI or dead zone.
        // For robustness, if we can't parse, we might break to avoid infinite loop
        // or just increment index to try to find next known pattern (risky).
        // Let's assume we stop if we hit something unknown to avoid garbage.
        // Or if we are at a separator, skip it.
        if (processingCode.startsWith(GROUP_SEPARATOR, index)) {
          index++;
          continue;
        }
        break;
      }
    }

    return result;
  }
}
