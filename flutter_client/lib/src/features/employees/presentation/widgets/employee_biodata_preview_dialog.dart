import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../shared/widgets/signature_pad_dialog.dart';
import '../../data/employee.dart';
import '../../data/employee_biodata_export.dart';

class EmployeeBiodataPreviewDialog extends StatefulWidget {
  const EmployeeBiodataPreviewDialog({
    required this.employee,
    this.companyName = '',
    this.companyAddress = '',
    super.key,
  });

  final Employee employee;
  final String companyName;
  final String companyAddress;

  @override
  State<EmployeeBiodataPreviewDialog> createState() => _EmployeeBiodataPreviewDialogState();
}

class _EmployeeBiodataPreviewDialogState extends State<EmployeeBiodataPreviewDialog> {
  String _selectedTemplate = 'classic'; // 'classic', 'executive', 'minimal'
  Uint8List? _candidateSignatureBytes;
  bool _isCandidateDigitallySigned = false;
  String? _candidateSignDate;

  bool _includeCompanySeal = true;
  Uint8List? _authorizedSignatureBytes;
  String _authorizedSignatoryName = 'Authorized HR Officer';
  String? _authorizedSignDate;
  final String _place = 'Head Office';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _candidateSignDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _authorizedSignDate = _candidateSignDate;
  }

  Future<Uint8List> _generatePdf() {
    return EmployeeBiodataExport.build(
      widget.employee,
      companyName: widget.companyName.isNotEmpty ? widget.companyName : 'Invoicely Enterprise',
      companyAddress: widget.companyAddress,
      templateStyle: _selectedTemplate,
      candidateSignatureBytes: _candidateSignatureBytes,
      candidateSignDate: _candidateSignDate,
      isCandidateDigitallySigned: _isCandidateDigitallySigned,
      includeCompanySeal: _includeCompanySeal,
      authorizedSignatureBytes: _authorizedSignatureBytes,
      authorizedSignatoryName: _authorizedSignatoryName,
      authorizedSignDate: _authorizedSignDate,
      place: _place,
    );
  }

  Future<void> _openCandidateSignOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Candidate Signature & Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select how ${widget.employee.fullName} should sign the Biodata verification form.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.draw_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Draw or Type Digital Signature', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sign smoothly on screen or choose calligraphy typeface'),
                  onTap: () => Navigator.pop(ctx, 'draw'),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.verified_user_rounded, color: Color(0xFF15803D)),
                  ),
                  title: const Text('Aadhaar e-Sign Endorsement', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Affix digital verification badge linked to Aadhaar UID'),
                  onTap: () => Navigator.pop(ctx, 'esign'),
                ),
                if (_candidateSignatureBytes != null || _isCandidateDigitallySigned)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Remove Current Signature', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(ctx, 'clear'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    if (choice == 'draw') {
      final res = await SignaturePadDialog.show(
        context,
        initialSigneeName: widget.employee.fullName,
        initialSigneeTitle: widget.employee.designation,
      );
      if (res != null && mounted) {
        setState(() {
          _candidateSignatureBytes = base64Decode(res.base64Png);
          _isCandidateDigitallySigned = false;
        });
      }
    } else if (choice == 'esign') {
      setState(() {
        _isCandidateDigitallySigned = true;
        _candidateSignatureBytes = null;
      });
    } else if (choice == 'clear') {
      setState(() {
        _isCandidateDigitallySigned = false;
        _candidateSignatureBytes = null;
      });
    }
  }

  Future<void> _openAuthorizedSignModal() async {
    final res = await SignaturePadDialog.show(
      context,
      initialSigneeName: _authorizedSignatoryName,
      initialSigneeTitle: 'HR & Administrative Officer',
    );
    if (res != null && mounted) {
      setState(() {
        _authorizedSignatureBytes = base64Decode(res.base64Png);
        if (res.signeeName != null && res.signeeName!.isNotEmpty) {
          _authorizedSignatoryName = res.signeeName!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidateSigned = _candidateSignatureBytes != null || _isCandidateDigitallySigned;

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 950),
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biodata — ${widget.employee.fullName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.employee.designation} · ${widget.employee.employeeCode.isNotEmpty ? widget.employee.employeeCode : "STAFF"}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              // Template Selector
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTemplate,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'classic', child: Text('Classic Formal', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'executive', child: Text('Executive Navy', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'minimal', child: Text('Minimal Clean', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTemplate = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Share Biodata PDF',
                icon: const Icon(Icons.share_outlined),
                onPressed: () async {
                  final bytes = await _generatePdf();
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: '${widget.employee.fullName.replaceAll(' ', '_')}_Biodata.pdf',
                  );
                },
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Column(
            children: [
              // PDF Preview Canvas
              Expanded(
                child: PdfPreview(
                  build: (format) => _generatePdf(),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  pdfFileName: '${widget.employee.fullName.replaceAll(' ', '_')}_Biodata.pdf',
                ),
              ),

              // Bottom Sign-off & Verification Bar (Sign in options)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Candidate Sign Button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _openCandidateSignOptions,
                            style: FilledButton.styleFrom(
                              backgroundColor: candidateSigned ? const Color(0xFFDCFCE7) : null,
                              foregroundColor: candidateSigned ? const Color(0xFF15803D) : null,
                            ),
                            icon: Icon(
                              candidateSigned ? Icons.check_circle_rounded : Icons.edit_document,
                              size: 18,
                            ),
                            label: Text(
                              candidateSigned ? 'Candidate Signed' : 'Sign as Candidate',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (candidateSigned)
                            IconButton(
                              tooltip: 'Clear Candidate Signature',
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _candidateSignatureBytes = null;
                                  _isCandidateDigitallySigned = false;
                                });
                              },
                            ),
                        ],
                      ),

                      // Authorized HR Signatory
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _openAuthorizedSignModal,
                            icon: Icon(
                              _authorizedSignatureBytes != null ? Icons.verified : Icons.draw_outlined,
                              size: 18,
                              color: _authorizedSignatureBytes != null ? const Color(0xFF1E3A8A) : null,
                            ),
                            label: Text(
                              _authorizedSignatureBytes != null ? 'HR Signed' : 'Sign as HR Signatory',
                            ),
                          ),
                          if (_authorizedSignatureBytes != null)
                            IconButton(
                              tooltip: 'Clear HR Signature',
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onPressed: () => setState(() => _authorizedSignatureBytes = null),
                            ),
                        ],
                      ),

                      // Company Seal Toggle
                      FilterChip(
                        selected: _includeCompanySeal,
                        label: const Text('Company Seal Stamp'),
                        avatar: const Icon(Icons.verified_outlined, size: 16),
                        onSelected: (val) => setState(() => _includeCompanySeal = val),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
