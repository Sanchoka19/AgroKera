import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/phone_validator.dart';

void main() {
  group('PhoneValidator', () {
    test('extractDigits strips formatting and non-digits', () {
      expect(PhoneValidator.extractDigits('+995 599 12 34 56'), '995599123456');
      expect(PhoneValidator.extractDigits('599-12-34-56'), '599123456');
    });

    test('validates 9-digit local Georgian numbers', () {
      expect(PhoneValidator.isValid('599123456'), isTrue);
      expect(PhoneValidator.isValid('577 98 76 54'), isTrue);
      expect(PhoneValidator.isValid('555-11-22-33'), isTrue);
      expect(PhoneValidator.isValid('499123456'), isFalse);
      expect(PhoneValidator.isValid('59912345'), isFalse);
      expect(PhoneValidator.isValid(''), isFalse);
      expect(PhoneValidator.isValid(null), isFalse);
    });

    test('validates 12-digit international Georgian numbers', () {
      expect(PhoneValidator.isValid('+995599123456'), isTrue);
      expect(PhoneValidator.isValid('+995 599 12 34 56'), isTrue);
      expect(PhoneValidator.isValid('995577001122'), isTrue);
      expect(PhoneValidator.isValid('+995499123456'), isFalse);
    });

    test('normalizes numbers to standard formatted format', () {
      expect(PhoneValidator.normalize('599123456'), '+995 599 12 34 56');
      expect(PhoneValidator.normalize('+995 577 11 22 33'), '+995 577 11 22 33');
      expect(PhoneValidator.normalize('995555443322'), '+995 555 44 33 22');
    });

    test('converts to compact E164 format', () {
      expect(PhoneValidator.toE164('599123456'), '+995599123456');
      expect(PhoneValidator.toE164('+995 599 12 34 56'), '+995599123456');
    });
  });
}

