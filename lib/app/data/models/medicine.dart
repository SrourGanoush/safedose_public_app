class Medicine {
  final String gtin;
  final String batchNumber;
  final String serialNumber;
  final DateTime expiryDate;
  final String companyId;
  final String manufacturerName;
  final DateTime createdAt;
  final String distributorId; // UID of the distributor who created this
  final String status; // e.g., "Created", "Shipped", "Received", "Sold"
  final String codeType; // e.g., "EAN-13", "GS1 DataMatrix"
  final List<Map<String, dynamic>> statusHistory;

  Medicine({
    required this.gtin,
    required this.batchNumber,
    required this.serialNumber,
    required this.expiryDate,
    required this.companyId,
    required this.manufacturerName,
    required this.createdAt,
    this.distributorId = '',
    this.status = 'Created',
    this.codeType = '',
    this.statusHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'gtin': gtin,
      'batchNumber': batchNumber,
      'serialNumber': serialNumber,
      'expiryDate': expiryDate.toIso8601String(),
      'companyId': companyId,
      'manufacturerName': manufacturerName,
      'createdAt': createdAt.toIso8601String(),
      'distributorId': distributorId,
      'status': status,
      'codeType': codeType,
      'statusHistory': statusHistory,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      gtin: map['gtin'] ?? '',
      batchNumber: map['batchNumber'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      expiryDate: DateTime.tryParse(map['expiryDate'] ?? '') ?? DateTime.now(),
      companyId: map['companyId'] ?? '',
      manufacturerName: map['manufacturerName'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      distributorId: map['distributorId'] ?? '',
      status: map['status'] ?? 'Created',
      codeType: map['codeType'] ?? '',
      statusHistory: List<Map<String, dynamic>>.from(
        map['statusHistory'] ?? [],
      ),
    );
  }

  Medicine copyWith({
    String? status,
    String? codeType,
    List<Map<String, dynamic>>? statusHistory,
  }) {
    return Medicine(
      gtin: gtin,
      batchNumber: batchNumber,
      serialNumber: serialNumber,
      expiryDate: expiryDate,
      companyId: companyId,
      manufacturerName: manufacturerName,
      createdAt: createdAt,
      distributorId: distributorId,
      status: status ?? this.status,
      codeType: codeType ?? this.codeType,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}
