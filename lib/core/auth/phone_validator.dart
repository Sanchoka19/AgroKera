/// Pure domain utility for Georgian phone number normalization and validation.
/// Strict typing, zero external dependencies, no UI logic.
abstract final class PhoneValidator {
  static const String defaultCountryCode = '+995';

  /// Extracts digits only from a raw input string.
  static String extractDigits(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  /// Validates whether the given string is a valid Georgian mobile number.
  /// Valid formats:
  /// - 9 digits starting with '5' (e.g. 599123456)
  /// - 12 digits starting with '9955' (e.g. 995599123456)
  static bool isValid(String? input) {
    if (input == null) return false;
    final digits = extractDigits(input);
    if (digits.length == 9 && digits.startsWith('5')) {
      return true;
    }
    if (digits.length == 12 && digits.startsWith('9955')) {
      return true;
    }
    return false;
  }

  /// Normalizes a valid phone number into standard formatted string: `+995 5XX XX XX XX`
  /// If input is invalid, returns the trimmed input as fallback.
  static String normalize(String input) {
    final digits = extractDigits(input);
    if (digits.length == 9 && digits.startsWith('5')) {
      return '+995 ${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    }
    if (digits.length == 12 && digits.startsWith('9955')) {
      final local = digits.substring(3);
      return '+995 ${local.substring(0, 3)} ${local.substring(3, 5)} ${local.substring(5, 7)} ${local.substring(7, 9)}';
    }
    return input.trim();
  }

  /// Converts a phone number to standard compact E.164 format: `+9955XXXXXXXX`
  static String toE164(String input) {
    final digits = extractDigits(input);
    if (digits.length == 9 && digits.startsWith('5')) {
      return '+995$digits';
    }
    if (digits.length == 12 && digits.startsWith('9955')) {
      return '+$digits';
    }
    return input.trim();
  }
}
