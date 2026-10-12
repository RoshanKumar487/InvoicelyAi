import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/features/employees/data/aadhaar_ocr_scanner.dart';

void main() {
  group('AadhaarOcrScanner parser tests', () {
    test('extracts UID, DOB, Gender, and Name from front Aadhaar card text', () {
      const mockFrontText = '''
Government of India
Unique Identification Authority of India
Ramesh Kumar Sharma
DOB: 15/08/1992
Male
5489 2145 7890
मेरा आधार, मेरी पहचान
''';

      final data = AadhaarOcrScanner.parse(mockFrontText);

      expect(data.aadhaarNumber, equals('5489 2145 7890'));
      expect(data.dob, equals('15-08-1992'));
      expect(data.gender, equals('Male'));
      expect(data.fullName, equals('Ramesh Kumar Sharma'));

      final draft = data.toEmployeeDraft();
      expect(draft.fullName, equals('Ramesh Kumar Sharma'));
      expect(draft.aadhaarNumber, equals('5489 2145 7890'));
      expect(draft.gender, equals('Male'));
      expect(draft.dob, equals('15-08-1992'));
    });

    test('extracts father name, address, pincode, and state from back card text', () {
      const mockBackText = '''
Address:
S/O: Mohan Lal Sharma
House No 42, Sector 14
Gurugram, Haryana
122001
1947
help@uidai.gov.in
''';

      final data = AadhaarOcrScanner.parse(mockBackText);

      expect(data.fatherOrHusbandName, equals('Mohan Lal Sharma'));
      expect(data.pincode, equals('122001'));
      expect(data.state, equals('Haryana'));
    });

    test('formats continuous 12 digit Aadhaar UID with spaces', () {
      const mockText = '''
Sunita Devi
Year of Birth: 1988
Female
987654321098
''';

      final data = AadhaarOcrScanner.parse(mockText);

      expect(data.aadhaarNumber, equals('9876 5432 1098'));
      expect(data.gender, equals('Female'));
      expect(data.dob, equals('1988'));
    });
  });
}
