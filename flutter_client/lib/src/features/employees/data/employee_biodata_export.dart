import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/storage/local_preferences.dart';
import '../../templates/data/company_letterhead.dart';
import 'employee.dart';

class EmployeeBiodataExport {
  EmployeeBiodataExport._();

  static Future<Uint8List> build(
    Employee employee, {
    String companyName = 'Invoicely Enterprise',
    String companyAddress = '',
    String companyPhone = '',
    String companyEmail = '',
    String templateStyle = 'classic', // classic, executive, minimal
    Uint8List? candidateSignatureBytes,
    String? candidateSignDate,
    bool isCandidateDigitallySigned = false,
    bool includeCompanySeal = true,
    Uint8List? authorizedSignatureBytes,
    String? authorizedSignatoryName,
    String? authorizedSignDate,
    String? place,
  }) async {
    final pdf = pw.Document();

    // Load default Company Letterhead settings from template_studio LocalPreferences
    final studioPrefs = LocalPreferences(scope: 'template_studio');
    final savedSettings = <String, Object?>{};
    for (final k in const [
      'letterhead_enabled',
      'letterhead_style_id',
      'letterhead_company_name',
      'letterhead_tagline',
      'letterhead_phone',
      'letterhead_email',
      'letterhead_website',
      'letterhead_address',
      'letterhead_gstin',
      'letterhead_pan',
      'letterhead_cin',
      'studio_primary_color',
      'invoiceLogo',
    ]) {
      final v = await studioPrefs.readString(k);
      if (v != null && v.isNotEmpty) {
        savedSettings[k] = v;
      }
    }

    final letterheadConfig = CompanyLetterheadConfig.fromSettings(
      localSettings: savedSettings,
      fallbackCompanyName: companyName.isNotEmpty ? companyName : null,
      fallbackAddress: companyAddress.isNotEmpty ? companyAddress : null,
      fallbackPhone: companyPhone.isNotEmpty ? companyPhone : null,
      fallbackEmail: companyEmail.isNotEmpty ? companyEmail : null,
    );

    final isExecutive = templateStyle.toLowerCase() == 'executive';
    final isMinimal = templateStyle.toLowerCase() == 'minimal';

    final primaryColor = isExecutive
        ? const PdfColor.fromInt(0xFF1E3A8A)
        : isMinimal
            ? const PdfColor.fromInt(0xFF0F172A)
            : const PdfColor.fromInt(0xFF1E40AF);

    final sectionBg = isExecutive
        ? const PdfColor.fromInt(0xFFEFF6FF)
        : isMinimal
            ? const PdfColor.fromInt(0xFFF8FAFC)
            : const PdfColor.fromInt(0xFFF1F5F9);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Official Company Letterhead Header (or Classic Header)
              if (letterheadConfig.isLetterheadActive) ...[
                CompanyLetterheadPdf.buildPdfHeader(
                  config: letterheadConfig,
                  overridePrimary: primaryColor,
                  scale: 0.95,
                  showGstBadges: true,
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'STAFF BIODATA & EMPLOYMENT VERIFICATION FORM',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Employee Code: ${employee.employeeCode.isNotEmpty ? employee.employeeCode : "STAFF"}  |  Designation: ${employee.designation}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      width: 60,
                      height: 68,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'PASSPORT\nPHOTO',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (isExecutive)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName.isNotEmpty ? companyName.toUpperCase() : 'INVOICELY ENTERPRISE',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          if (companyAddress.isNotEmpty)
                            pw.Text(
                              companyAddress,
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300),
                            ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'EXECUTIVE BIODATA & VERIFICATION RECORD',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF93C5FD),
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        width: 65,
                        height: 75,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.white),
                          color: const PdfColor.fromInt(0xFF1E293B),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'PASSPORT\nPHOTO',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey300),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              companyName.isNotEmpty ? companyName.toUpperCase() : 'ENTERPRISE EMPLOYEE RECORD',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            if (companyAddress.isNotEmpty)
                              pw.Text(
                                companyAddress,
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                              ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'STAFF BIODATA & EMPLOYMENT VERIFICATION FORM',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 70,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          color: PdfColors.grey100,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'AFFIX\nPASSPORT\nPHOTO',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 8),

              // 2. Personal Details
              _sectionHeader('1. PERSONAL & IDENTITY PROFILE', primaryColor, sectionBg),
              _keyValueTable([
                ['Full Name', employee.fullName],
                ["Father / Husband's Name", employee.fatherOrHusbandName.isNotEmpty ? employee.fatherOrHusbandName : 'N/A'],
                ['Date of Birth', employee.dob.isNotEmpty ? employee.dob : 'N/A'],
                ['Gender', employee.gender],
                ['Marital Status', employee.maritalStatus],
                ['Blood Group', employee.bloodGroup.isNotEmpty ? employee.bloodGroup : 'N/A'],
                ['Aadhaar Card UID', employee.aadhaarNumber.isNotEmpty ? employee.aadhaarNumber : 'N/A'],
                ['Qualification', employee.qualification.isNotEmpty ? employee.qualification : 'N/A'],
              ]),
              pw.SizedBox(height: 8),

              // 3. Employment Details
              _sectionHeader('2. EMPLOYMENT & POSITION SPECIFICATIONS', primaryColor, sectionBg),
              _keyValueTable([
                ['Employee Code', employee.employeeCode.isNotEmpty ? employee.employeeCode : 'N/A'],
                ['Designation / Post', employee.designation],
                ['Department', employee.department],
                ['Date of Joining', employee.joiningDate.isNotEmpty ? employee.joiningDate : 'N/A'],
                ['Monthly Net Salary', employee.monthlySalary > 0 ? 'Rs. ${employee.monthlySalary.toStringAsFixed(2)}' : 'N/A'],
                ['Current Status', employee.status],
              ]),
              pw.SizedBox(height: 8),

              // 4. Contact & Residential Address
              _sectionHeader('3. RESIDENTIAL & EMERGENCY CONTACT DETAILS', primaryColor, sectionBg),
              _keyValueTable([
                ['Contact Mobile', employee.phone.isNotEmpty ? employee.phone : 'N/A'],
                ['Email Address', employee.email.isNotEmpty ? employee.email : 'N/A'],
                ['Permanent Address', employee.address.isNotEmpty ? employee.address : 'N/A'],
                ['City / State / Pincode', '${employee.city} ${employee.state} ${employee.pincode}'.trim().isNotEmpty ? '${employee.city}, ${employee.state} - ${employee.pincode}' : 'N/A'],
                ['Emergency Contact', employee.emergencyContactName.isNotEmpty ? employee.emergencyContactName : 'N/A'],
                ['Emergency Phone', employee.emergencyContactPhone.isNotEmpty ? employee.emergencyContactPhone : 'N/A'],
              ]),
              pw.SizedBox(height: 8),

              // 5. Bank Account Information
              _sectionHeader('4. BANK ACCOUNT DETAILS (SALARY DISBURSEMENT)', primaryColor, sectionBg),
              _keyValueTable([
                ['Bank Name', employee.bankName.isNotEmpty ? employee.bankName : 'N/A'],
                ['Account Number', employee.bankAccountNumber.isNotEmpty ? employee.bankAccountNumber : 'N/A'],
                ['IFSC Code', employee.ifscCode.isNotEmpty ? employee.ifscCode : 'N/A'],
              ]),
              pw.SizedBox(height: 10),

              // 6. Declaration
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: sectionBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Text(
                  'DECLARATION: I hereby confirm that all information furnished above is true, complete and correct. I also authorize the organization to verify my Aadhaar credentials, background, and identity as per applicable regulations.',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                ),
              ),
              pw.Spacer(),

              // 7. Sign-off / Signature Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Candidate Signature
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (candidateSignatureBytes != null)
                        pw.Container(
                          height: 38,
                          width: 120,
                          alignment: pw.Alignment.bottomLeft,
                          child: pw.Image(pw.MemoryImage(candidateSignatureBytes), fit: pw.BoxFit.contain),
                        )
                      else if (isCandidateDigitallySigned)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFF15803D), width: 1),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                            color: const PdfColor.fromInt(0xFFDCFCE7),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('[DIGITALLY SIGNED & VERIFIED]', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF166534))),
                              pw.Text('UID: ${employee.aadhaarNumber.isNotEmpty ? employee.aadhaarNumber : "VERIFIED"}', style: const pw.TextStyle(fontSize: 6, color: PdfColor.fromInt(0xFF15803D))),
                            ],
                          ),
                        )
                      else
                        pw.SizedBox(height: 38),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 1)),
                        ),
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            'Candidate / Employee Signature\n(${employee.fullName})',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Date: ${candidateSignDate ?? "____________"}', style: const pw.TextStyle(fontSize: 7)),
                      pw.Text('Place: ${place ?? "____________"}', style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),

                  // Center Seal
                  if (includeCompanySeal)
                    pw.Container(
                      width: 72,
                      height: 72,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: primaryColor, width: 1.5),
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('OFFICIAL SEAL', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Text(
                              companyName.isNotEmpty ? (companyName.length > 14 ? companyName.substring(0, 14) : companyName) : 'INVOICELY',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                            pw.Text('HR VERIFIED', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
                            if (authorizedSignDate != null && authorizedSignDate.isNotEmpty)
                              pw.Text(authorizedSignDate, style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),

                  // Authorized Signatory
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (authorizedSignatureBytes != null)
                        pw.Container(
                          height: 38,
                          width: 120,
                          alignment: pw.Alignment.bottomRight,
                          child: pw.Image(pw.MemoryImage(authorizedSignatureBytes), fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 38),
                      pw.Container(
                        width: 160,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 1)),
                        ),
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            authorizedSignatoryName ?? 'Authorized HR / Signatory',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Date: ${authorizedSignDate ?? "____________"}', style: const pw.TextStyle(fontSize: 7)),
                      pw.Text('Company Seal & Stamp', style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ],
              ),
              if (letterheadConfig.isLetterheadActive) ...[
                pw.SizedBox(height: 6),
                CompanyLetterheadPdf.buildPdfFooter(
                  config: letterheadConfig,
                  overridePrimary: primaryColor,
                  scale: 0.92,
                  pageLabel: 'Biodata • Page 1 of 1',
                ),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _sectionHeader(String title, PdfColor color, PdfColor bgColor) {
    return pw.Container(
      width: double.infinity,
      color: bgColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      margin: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _keyValueTable(List<List<String>> pairs) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        for (int i = 0; i < pairs.length; i += 2)
          pw.TableRow(
            children: [
              _cell(pairs[i][0], isLabel: true),
              _cell(pairs[i][1]),
              if (i + 1 < pairs.length) ...[
                _cell(pairs[i + 1][0], isLabel: true),
                _cell(pairs[i + 1][1]),
              ] else ...[
                _cell(''),
                _cell(''),
              ],
            ],
          ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isLabel = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: isLabel ? PdfColors.grey50 : PdfColors.white,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isLabel ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }
}
