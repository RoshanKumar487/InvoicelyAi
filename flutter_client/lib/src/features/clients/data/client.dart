class Client {
  const Client({
    this.id,
    this.companyId,
    required this.name,
    this.companyName = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.taxId = '',
    this.preferredCurrency = 'USD',
    this.defaultPaymentTerms = 'Net 30',
    this.notes = '',
    this.createdAt,
  });

  final int? id;
  final int? companyId;
  final String name;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String taxId;
  final String preferredCurrency;
  final String defaultPaymentTerms;
  final String notes;
  final int? createdAt;

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: _readInt(json['id']),
      companyId: _readInt(json['companyId']),
      name: _readString(json['name']),
      companyName: _readString(json['companyName']),
      email: _readString(json['email']),
      phone: _readString(json['phone']),
      address: _readString(json['address']),
      taxId: _readString(json['taxId']),
      preferredCurrency: _readString(json['preferredCurrency'], fallback: 'USD'),
      defaultPaymentTerms:
          _readString(json['defaultPaymentTerms'], fallback: 'Net 30'),
      notes: _readString(json['notes']),
      createdAt: _readInt(json['createdAt']),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'name': name,
        'companyName': companyName,
        'email': email,
        'phone': phone,
        'address': address,
        'taxId': taxId,
        'preferredCurrency': preferredCurrency,
        'defaultPaymentTerms': defaultPaymentTerms,
        'notes': notes,
        'createdAt': createdAt,
      };
}

String _readString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

int? _readInt(Object? value) => value is num ? value.toInt() : null;
