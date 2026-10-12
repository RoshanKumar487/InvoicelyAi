import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/features/employees/data/employee.dart';
import 'package:invoicely_flutter/src/features/employees/data/employee_biodata_export.dart';

void main() {
  group('Employee and Biodata Export Tests', () {
    const sampleEmployee = Employee(
      id: 101,
      companyId: 1,
      employeeCode: 'EMP-042',
      fullName: 'Vikram Singh',
      aadhaarNumber: '1234 5678 9012',
      designation: 'Senior Security Guard',
      department: 'Security Operations',
      dob: '1992-05-14',
      gender: 'Male',
      maritalStatus: 'Married',
      bloodGroup: 'B+',
      phone: '+91 98765 43210',
      email: 'vikram.singh@example.com',
      address: 'Plot 12, Industrial Area, Sector 62',
      city: 'Noida',
      state: 'Uttar Pradesh',
      pincode: '201301',
      monthlySalary: 22500.0,
      bankName: 'HDFC Bank',
      bankAccountNumber: '5010022334455',
      ifscCode: 'HDFC0001234',
      status: 'ACTIVE',
    );

    test('Employee model JSON serialization and deserialization works correctly', () {
      final json = sampleEmployee.toJson();
      expect(json['id'], equals(101));
      expect(json['employeeCode'], equals('EMP-042'));
      expect(json['fullName'], equals('Vikram Singh'));
      expect(json['monthlySalary'], equals(22500.0));
      expect(json['status'], equals('ACTIVE'));

      final parsed = Employee.fromJson(json);
      expect(parsed.id, equals(101));
      expect(parsed.employeeCode, equals('EMP-042'));
      expect(parsed.fullName, equals('Vikram Singh'));
      expect(parsed.monthlySalary, equals(22500.0));
    });

    test('builds classic formal Biodata PDF successfully with candidate and HR sign-off', () async {
      // 1x1 transparent PNG byte dummy for signature test
      final dummySignature = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );

      final pdfBytes = await EmployeeBiodataExport.build(
        sampleEmployee,
        companyName: 'Apex Nova Security Ltd',
        companyAddress: 'Corporate Tower A, Cyber City, Gurugram',
        templateStyle: 'classic',
        candidateSignatureBytes: dummySignature,
        candidateSignDate: '12/10/2026',
        includeCompanySeal: true,
        authorizedSignatureBytes: dummySignature,
        authorizedSignatoryName: 'Col. Rajesh Sharma (Retd.)',
        authorizedSignDate: '12/10/2026',
        place: 'Gurugram',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('builds executive style Biodata PDF with Aadhaar e-Sign mark', () async {
      final pdfBytes = await EmployeeBiodataExport.build(
        sampleEmployee,
        companyName: 'Apex Nova Security Ltd',
        templateStyle: 'executive',
        isCandidateDigitallySigned: true,
        candidateSignDate: '12/10/2026',
        includeCompanySeal: true,
        authorizedSignatoryName: 'HR Director',
        place: 'New Delhi',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('builds minimal clean style Biodata PDF without error', () async {
      final pdfBytes = await EmployeeBiodataExport.build(
        sampleEmployee,
        templateStyle: 'minimal',
        includeCompanySeal: false,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
