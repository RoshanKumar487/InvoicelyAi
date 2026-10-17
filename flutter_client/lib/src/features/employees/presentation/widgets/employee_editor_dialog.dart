import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/aadhaar_ocr_scanner.dart';
import '../../data/employee.dart';

class EmployeeEditorDialog extends StatefulWidget {
  const EmployeeEditorDialog({
    this.employee,
    this.initialDraft,
    super.key,
  });

  final Employee? employee;
  final Employee? initialDraft;

  @override
  State<EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<EmployeeEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _employeeCode;
  late final TextEditingController _aadhaarNumber;
  late final TextEditingController _dob;
  late final TextEditingController _fatherOrHusbandName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _designation;
  late final TextEditingController _department;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _emergencyContactName;
  late final TextEditingController _emergencyContactPhone;
  late final TextEditingController _bloodGroup;
  late final TextEditingController _qualification;
  late final TextEditingController _joiningDate;
  late final TextEditingController _monthlySalary;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccountNumber;
  late final TextEditingController _ifscCode;
  late final TextEditingController _notes;

  String _gender = 'Male';
  String _maritalStatus = 'Single';
  String _status = 'ACTIVE';
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final source = widget.employee ?? widget.initialDraft;
    _fullName = TextEditingController(text: source?.fullName ?? '');
    _employeeCode = TextEditingController(text: source?.employeeCode ?? '');
    _aadhaarNumber = TextEditingController(text: source?.aadhaarNumber ?? '');
    _dob = TextEditingController(text: source?.dob ?? '');
    _fatherOrHusbandName = TextEditingController(text: source?.fatherOrHusbandName ?? '');
    _phone = TextEditingController(text: source?.phone ?? '');
    _email = TextEditingController(text: source?.email ?? '');
    _designation = TextEditingController(
        text: source?.designation.isNotEmpty == true ? source!.designation : 'Security Guard');
    _department = TextEditingController(
        text: source?.department.isNotEmpty == true ? source!.department : 'Security');
    _address = TextEditingController(text: source?.address ?? '');
    _city = TextEditingController(text: source?.city ?? '');
    _state = TextEditingController(text: source?.state ?? '');
    _pincode = TextEditingController(text: source?.pincode ?? '');
    _emergencyContactName = TextEditingController(text: source?.emergencyContactName ?? '');
    _emergencyContactPhone = TextEditingController(text: source?.emergencyContactPhone ?? '');
    _bloodGroup = TextEditingController(text: source?.bloodGroup ?? '');
    _qualification = TextEditingController(text: source?.qualification ?? '');
    _joiningDate = TextEditingController(
        text: source?.joiningDate.isNotEmpty == true
            ? source!.joiningDate
            : _todayDateString());
    _monthlySalary = TextEditingController(
        text: (source != null && source.monthlySalary > 0)
            ? source.monthlySalary.toStringAsFixed(0)
            : '');
    _bankName = TextEditingController(text: source?.bankName ?? '');
    _bankAccountNumber = TextEditingController(text: source?.bankAccountNumber ?? '');
    _ifscCode = TextEditingController(text: source?.ifscCode ?? '');
    _notes = TextEditingController(text: source?.notes ?? '');

    _gender = source?.gender ?? 'Male';
    _maritalStatus = source?.maritalStatus ?? 'Single';
    _status = source?.status ?? 'ACTIVE';
  }

  static String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _employeeCode.dispose();
    _aadhaarNumber.dispose();
    _dob.dispose();
    _fatherOrHusbandName.dispose();
    _phone.dispose();
    _email.dispose();
    _designation.dispose();
    _department.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _emergencyContactName.dispose();
    _emergencyContactPhone.dispose();
    _bloodGroup.dispose();
    _qualification.dispose();
    _joiningDate.dispose();
    _monthlySalary.dispose();
    _bankName.dispose();
    _bankAccountNumber.dispose();
    _ifscCode.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _scanAadhaarCard() async {
    setState(() => _isScanning = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) {
        setState(() => _isScanning = false);
        return;
      }

      final scanned = await AadhaarOcrScanner.scan(imagePath: image.path);
      if (!mounted) return;

      setState(() {
        if (scanned.fullName.isNotEmpty) _fullName.text = scanned.fullName;
        if (scanned.aadhaarNumber.isNotEmpty) _aadhaarNumber.text = scanned.aadhaarNumber;
        if (scanned.dob.isNotEmpty) _dob.text = scanned.dob;
        if (scanned.gender.isNotEmpty) _gender = scanned.gender;
        if (scanned.fatherOrHusbandName.isNotEmpty) _fatherOrHusbandName.text = scanned.fatherOrHusbandName;
        if (scanned.address.isNotEmpty) _address.text = scanned.address;
        if (scanned.pincode.isNotEmpty) _pincode.text = scanned.pincode;
        if (scanned.state.isNotEmpty) _state.text = scanned.state;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('✓ Aadhaar card scanned & information auto-filled!'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not scan Aadhaar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initial = DateTime.now();
    if (controller.text.isNotEmpty) {
      final parts = controller.text.split('-');
      if (parts.length == 3) {
        initial = DateTime(int.tryParse(parts[0]) ?? 2000, int.tryParse(parts[1]) ?? 1, int.tryParse(parts[2]) ?? 1);
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      id: widget.employee?.id,
      companyId: widget.employee?.companyId,
      employeeCode: _employeeCode.text.trim(),
      fullName: _fullName.text.trim(),
      aadhaarNumber: _aadhaarNumber.text.trim(),
      aadhaarFrontUri: widget.employee?.aadhaarFrontUri ?? '',
      aadhaarBackUri: widget.employee?.aadhaarBackUri ?? '',
      photoUri: widget.employee?.photoUri ?? '',
      dob: _dob.text.trim(),
      gender: _gender,
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      designation: _designation.text.trim(),
      department: _department.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
      fatherOrHusbandName: _fatherOrHusbandName.text.trim(),
      emergencyContactName: _emergencyContactName.text.trim(),
      emergencyContactPhone: _emergencyContactPhone.text.trim(),
      bloodGroup: _bloodGroup.text.trim(),
      maritalStatus: _maritalStatus,
      qualification: _qualification.text.trim(),
      joiningDate: _joiningDate.text.trim(),
      monthlySalary: double.tryParse(_monthlySalary.text.trim()) ?? 0.0,
      bankName: _bankName.text.trim(),
      bankAccountNumber: _bankAccountNumber.text.trim(),
      ifscCode: _ifscCode.text.trim(),
      status: _status,
      notes: _notes.text.trim(),
    );

    Navigator.of(context).pop(employee);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.employee == null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Scaffold(
          appBar: AppBar(
            title: Text(isNew ? 'New Employee Onboarding' : 'Edit Employee Profile'),
            actions: [
              if (_isScanning)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _scanAadhaarCard,
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: const Text('Scan Aadhaar'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle(Icons.badge_outlined, 'Personal & Identity Information'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _fullName,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'e.g. Ramesh Kumar',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _aadhaarNumber,
                        decoration: const InputDecoration(
                          labelText: 'Aadhaar UID',
                          hintText: 'XXXX XXXX 1234',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dob,
                        readOnly: true,
                        onTap: () => _pickDate(_dob),
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _gender = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _maritalStatus,
                        decoration: const InputDecoration(
                          labelText: 'Marital Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Single', child: Text('Single')),
                          DropdownMenuItem(value: 'Married', child: Text('Married')),
                          DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _maritalStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _fatherOrHusbandName,
                        decoration: const InputDecoration(
                          labelText: "Father's / Husband's Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bloodGroup,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group',
                          hintText: 'O+, B+, etc.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _qualification,
                        decoration: const InputDecoration(
                          labelText: 'Qualification',
                          hintText: '10th, 12th, Graduate',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionTitle(Icons.work_outline, 'Designation, Salary & Employment Details'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _employeeCode,
                        decoration: const InputDecoration(
                          labelText: 'Employee Code',
                          hintText: 'EMP-001 (auto if empty)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _designation,
                        decoration: const InputDecoration(
                          labelText: 'Designation / Post *',
                          hintText: 'Security Guard, Gunman, etc.',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _department,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          hintText: 'Security, Ops, Accounts',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthlySalary,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Net Salary (₹)',
                          hintText: 'e.g. 21000',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _joiningDate,
                        readOnly: true,
                        onTap: () => _pickDate(_joiningDate),
                        decoration: const InputDecoration(
                          labelText: 'Date of Joining',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                          DropdownMenuItem(value: 'ON_LEAVE', child: Text('On Leave')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionTitle(Icons.contact_phone_outlined, 'Contact & Address Details'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone / Mobile',
                          hintText: '9876543210',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'employee@example.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _state,
                        decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pincode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emergencyContactName,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Contact Person',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emergencyContactPhone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Contact Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionTitle(Icons.account_balance_outlined, 'Bank Account Details (Salary Disbursement)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bankName,
                        decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bankAccountNumber,
                        decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ifscCode,
                        decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Verification Remarks',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(isNew ? 'Save & Register' : 'Update Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
