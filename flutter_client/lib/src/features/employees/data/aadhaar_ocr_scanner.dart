import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'employee.dart';

class ScannedAadhaarData {
  const ScannedAadhaarData({
    required this.aadhaarNumber,
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.fatherOrHusbandName,
    required this.address,
    required this.pincode,
    required this.state,
    required this.rawText,
  });

  final String aadhaarNumber;
  final String fullName;
  final String dob;
  final String gender;
  final String fatherOrHusbandName;
  final String address;
  final String pincode;
  final String state;
  final String rawText;

  Employee toEmployeeDraft({
    String? frontImageUri,
    String? backImageUri,
  }) {
    return Employee(
      fullName: fullName.isNotEmpty ? fullName : 'New Employee',
      aadhaarNumber: aadhaarNumber,
      aadhaarFrontUri: frontImageUri ?? '',
      aadhaarBackUri: backImageUri ?? '',
      dob: dob,
      gender: gender.isNotEmpty ? gender : 'Male',
      fatherOrHusbandName: fatherOrHusbandName,
      address: address,
      pincode: pincode,
      state: state,
    );
  }
}

class AadhaarOcrScanner {
  const AadhaarOcrScanner();

  static Future<ScannedAadhaarData> scan({
    required String imagePath,
  }) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return parse(recognizedText.text);
    } finally {
      await textRecognizer.close();
    }
  }

  static ScannedAadhaarData parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    final aadhaarNumber = _extractAadhaarNumber(rawText);
    final dob = _extractDob(rawText);
    final gender = _extractGender(rawText);
    final fatherOrHusband = _extractFatherOrHusband(lines, rawText);
    final (address, pincode, state) = _extractAddressDetails(lines, rawText);
    final fullName = _extractName(lines, dob, gender, aadhaarNumber);

    return ScannedAadhaarData(
      aadhaarNumber: aadhaarNumber,
      fullName: fullName,
      dob: dob,
      gender: gender,
      fatherOrHusbandName: fatherOrHusband,
      address: address,
      pincode: pincode,
      state: state,
      rawText: rawText,
    );
  }

  static String _extractAadhaarNumber(String text) {
    // 4 digits space 4 digits space 4 digits e.g. "1234 5678 9012"
    final spacedMatch = RegExp(r'\b(\d{4})\s+(\d{4})\s+(\d{4})\b').firstMatch(text);
    if (spacedMatch != null) {
      return '${spacedMatch.group(1)} ${spacedMatch.group(2)} ${spacedMatch.group(3)}';
    }
    // 12 continuous digits
    final continuousMatch = RegExp(r'\b(\d{12})\b').firstMatch(text);
    if (continuousMatch != null) {
      final num = continuousMatch.group(1)!;
      return '${num.substring(0, 4)} ${num.substring(4, 8)} ${num.substring(8, 12)}';
    }
    return '';
  }

  static String _extractDob(String text) {
    // DOB: 15/08/1995 or 15-08-1995
    final dobRegex = RegExp(
      r'(?:DOB|D\.O\.B|Date\s+of\s+Birth|Year\s+of\s+Birth|जन्म\s*तिथि)\s*[:\s]*(\d{2}[/-]\d{2}[/-]\d{4}|\d{4})',
      caseSensitive: false,
    );
    final match = dobRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)!.replaceAll('/', '-');
    }

    // Fallback date pattern
    final fallbackDate = RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{4})\b').firstMatch(text);
    if (fallbackDate != null) {
      return fallbackDate.group(1)!.replaceAll('/', '-');
    }
    return '';
  }

  static String _extractGender(String text) {
    if (RegExp(r'\b(FEMALE|Female|महिला)\b').hasMatch(text)) return 'Female';
    if (RegExp(r'\b(MALE|Male|पुरुष)\b').hasMatch(text)) return 'Male';
    if (RegExp(r'\b(TRANSGENDER|Transgender)\b').hasMatch(text)) return 'Other';
    return 'Male';
  }

  static String _extractFatherOrHusband(List<String> lines, String rawText) {
    final coRegex = RegExp(r'(?:C/O|S/O|D/O|W/O|Care\s+of|Son\s+of|Daughter\s+of|Wife\s+of)\s*[:\s]+([^\r\n,]+)', caseSensitive: false);
    final match = coRegex.firstMatch(rawText);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return '';
  }

  static (String address, String pincode, String state) _extractAddressDetails(List<String> lines, String rawText) {
    String pincode = '';
    final pinMatch = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(rawText);
    if (pinMatch != null) {
      pincode = pinMatch.group(1)!;
    }

    String state = '';
    final states = [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
      'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
      'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
      'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi'
    ];
    for (final s in states) {
      if (rawText.toLowerCase().contains(s.toLowerCase())) {
        state = s;
        break;
      }
    }

    // Extract address lines after "Address:"
    final addressIndex = lines.indexWhere((l) => l.toLowerCase().contains('address') || l.contains('पता'));
    String address = '';
    if (addressIndex != -1) {
      final relevant = lines.skip(addressIndex).take(4).toList();
      address = relevant.join(', ').replaceAll(RegExp(r'address\s*[:\s]*', caseSensitive: false), '').trim();
    }

    return (address, pincode, state);
  }

  static String _extractName(List<String> lines, String dob, String gender, String aadhaar) {
    final ignoredKeywords = [
      'government of india', 'govt of india', 'bharat sarkar', 'unique identification',
      'authority of india', 'aadhaar', 'uidai', 'enrollment', 'help@uidai', 'www.uidai',
      'mera aadhaar', 'meri pehchan', 'dob', 'date of birth', 'male', 'female', 'year',
      'address', 'father', 'husband', 'son of', 'daughter of', 'care of'
    ];

    for (final line in lines) {
      final cleaned = line.trim();
      if (cleaned.length < 3 || cleaned.length > 40) continue;
      final lower = cleaned.toLowerCase();

      bool isIgnored = false;
      for (final kw in ignoredKeywords) {
        if (lower.contains(kw)) {
          isIgnored = true;
          break;
        }
      }
      if (isIgnored) continue;

      // Ensure line is primarily alphabetic
      if (RegExp(r'^[A-Za-z\s\.]+$').hasMatch(cleaned) && cleaned.split(' ').length >= 2) {
        return cleaned;
      }
    }

    return '';
  }
}
