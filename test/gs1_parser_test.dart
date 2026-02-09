import 'package:flutter_test/flutter_test.dart';
import 'package:safedose/app/data/utils/gs1_parser.dart';

void main() {
  const gs = '\u001D';

  group('GS1Parser Tests', () {
    test('Parses full GS1 string correctly', () {
      // (01)01234567890128(17)251231(10)BATCH123(21)SER123
      final code = '01012345678901281725123110BATCH123${gs}21SER123';
      final result = GS1Parser.parse(code);

      expect(result['gtin'], '01234567890128');
      expect(result['expiry'], '251231');
      expect(result['batch'], 'BATCH123');
      expect(result['serial'], 'SER123');
    });

    test('Parses with different order if valid', () {
      // (01)GTIN(21)SER${gs}(10)BATCH
      final code = '010123456789012821SER123${gs}10BATCH123';
      final result = GS1Parser.parse(code);

      expect(result['gtin'], '01234567890128');
      expect(result['serial'], 'SER123');
      expect(result['batch'], 'BATCH123');
    });

    test('Parses only GTIN', () {
      final code = '0101234567890128';
      final result = GS1Parser.parse(code);
      expect(result['gtin'], '01234567890128');
      expect(result.length, 1);
    });

    test('Handles ]d2 prefix', () {
      final code = ']d20101234567890128';
      final result = GS1Parser.parse(code);
      expect(result['gtin'], '01234567890128');
    });

    test('Handles End of String for variable fields', () {
      // (01)GTIN(10)BATCH - no GS at end
      final code = '010123456789012810BATCH123';
      final result = GS1Parser.parse(code);
      expect(result['gtin'], '01234567890128');
      expect(result['batch'], 'BATCH123');
    });

    test('Returns empty for random string', () {
      final code = 'randomstring';
      final result = GS1Parser.parse(code);
      expect(result, isEmpty);
    });
  });
}
