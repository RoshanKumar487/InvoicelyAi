class Employee {
  const Employee({
    this.id,
    this.companyId,
    this.employeeCode = '',
    required this.fullName,
    this.aadhaarNumber = '',
    this.aadhaarFrontUri = '',
    this.aadhaarBackUri = '',
    this.photoUri = '',
    this.dob = '',
    this.gender = 'Male',
    this.phone = '',
    this.email = '',
    this.designation = 'Security Guard',
    this.department = 'Security',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.fatherOrHusbandName = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.bloodGroup = '',
    this.maritalStatus = 'Single',
    this.qualification = '',
    this.joiningDate = '',
    this.monthlySalary = 0.0,
    this.bankName = '',
    this.bankAccountNumber = '',
    this.ifscCode = '',
    this.status = 'ACTIVE',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? companyId;
  final String employeeCode;
  final String fullName;
  final String aadhaarNumber;
  final String aadhaarFrontUri;
  final String aadhaarBackUri;
  final String photoUri;
  final String dob;
  final String gender;
  final String phone;
  final String email;
  final String designation;
  final String department;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String fatherOrHusbandName;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;
  final String maritalStatus;
  final String qualification;
  final String joiningDate;
  final double monthlySalary;
  final String bankName;
  final String bankAccountNumber;
  final String ifscCode;
  final String status; // ACTIVE, INACTIVE, ON_LEAVE
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['id'] as num?)?.toInt(),
      companyId: (json['companyId'] as num?)?.toInt(),
      employeeCode: json['employeeCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      aadhaarNumber: json['aadhaarNumber']?.toString() ?? '',
      aadhaarFrontUri: json['aadhaarFrontUri']?.toString() ?? '',
      aadhaarBackUri: json['aadhaarBackUri']?.toString() ?? '',
      photoUri: json['photoUri']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Male',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      fatherOrHusbandName: json['fatherOrHusbandName']?.toString() ?? '',
      emergencyContactName: json['emergencyContactName']?.toString() ?? '',
      emergencyContactPhone: json['emergencyContactPhone']?.toString() ?? '',
      bloodGroup: json['bloodGroup']?.toString() ?? '',
      maritalStatus: json['maritalStatus']?.toString() ?? 'Single',
      qualification: json['qualification']?.toString() ?? '',
      joiningDate: json['joiningDate']?.toString() ?? '',
      monthlySalary: (json['monthlySalary'] as num?)?.toDouble() ?? 0.0,
      bankName: json['bankName']?.toString() ?? '',
      bankAccountNumber: json['bankAccountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'companyId': companyId,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarFrontUri': aadhaarFrontUri,
      'aadhaarBackUri': aadhaarBackUri,
      'photoUri': photoUri,
      'dob': dob,
      'gender': gender,
      'phone': phone,
      'email': email,
      'designation': designation,
      'department': department,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'fatherOrHusbandName': fatherOrHusbandName,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'bloodGroup': bloodGroup,
      'maritalStatus': maritalStatus,
      'qualification': qualification,
      'joiningDate': joiningDate,
      'monthlySalary': monthlySalary,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'status': status,
      'notes': notes,
    };
  }

  Employee copyWith({
    int? id,
    int? companyId,
    String? employeeCode,
    String? fullName,
    String? aadhaarNumber,
    String? aadhaarFrontUri,
    String? aadhaarBackUri,
    String? photoUri,
    String? dob,
    String? gender,
    String? phone,
    String? email,
    String? designation,
    String? department,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? fatherOrHusbandName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? maritalStatus,
    String? qualification,
    String? joiningDate,
    double? monthlySalary,
    String? bankName,
    String? bankAccountNumber,
    String? ifscCode,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarFrontUri: aadhaarFrontUri ?? this.aadhaarFrontUri,
      aadhaarBackUri: aadhaarBackUri ?? this.aadhaarBackUri,
      photoUri: photoUri ?? this.photoUri,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      fatherOrHusbandName: fatherOrHusbandName ?? this.fatherOrHusbandName,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      qualification: qualification ?? this.qualification,
      joiningDate: joiningDate ?? this.joiningDate,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
