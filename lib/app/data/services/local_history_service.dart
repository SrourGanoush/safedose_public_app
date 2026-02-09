import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

class ScanRecord {
  final String gtin;
  final String serialNumber;
  final String manufacturerName;
  final String status;
  final String verificationResult; // e.g. "Verified", "Warning"
  final DateTime timestamp;
  final String aiSummary;

  ScanRecord({
    required this.gtin,
    required this.serialNumber,
    required this.manufacturerName,
    required this.status,
    required this.verificationResult,
    required this.timestamp,
    required this.aiSummary,
  });

  Map<String, dynamic> toJson() => {
    'gtin': gtin,
    'serialNumber': serialNumber,
    'manufacturerName': manufacturerName,
    'status': status,
    'verificationResult': verificationResult,
    'timestamp': timestamp.toIso8601String(),
    'aiSummary': aiSummary,
  };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
    gtin: json['gtin'] ?? '',
    serialNumber: json['serialNumber'] ?? '',
    manufacturerName: json['manufacturerName'] ?? '',
    status: json['status'] ?? '',
    verificationResult: json['verificationResult'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    aiSummary: json['aiSummary'] ?? '',
  );
}

class LocalHistoryService extends GetxService {
  late SharedPreferences _prefs;
  final _records = <ScanRecord>[].obs;
  List<ScanRecord> get records => _records;

  Future<LocalHistoryService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadRecords();
    return this;
  }

  void _loadRecords() {
    final String? data = _prefs.getString('scan_history');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _records.value = jsonList.map((e) => ScanRecord.fromJson(e)).toList();
    }
  }

  Future<void> addRecord(
    Medicine? medicine,
    String verificationResult,
    String aiSummary,
  ) async {
    final record = ScanRecord(
      gtin: medicine?.gtin ?? 'Unknown',
      serialNumber: medicine?.serialNumber ?? 'Unknown',
      manufacturerName: medicine?.manufacturerName ?? 'Unknown',
      status: medicine?.status ?? 'Not Found',
      verificationResult: verificationResult,
      timestamp: DateTime.now(),
      aiSummary: aiSummary,
    );

    _records.insert(0, record); // Add to top
    if (_records.length > 50) {
      _records.removeLast(); // Keep limit
    }
    await _saveRecords();
  }

  Future<void> _saveRecords() async {
    final String data = jsonEncode(_records.map((e) => e.toJson()).toList());
    await _prefs.setString('scan_history', data);
  }

  Future<void> clearHistory() async {
    _records.clear();
    await _prefs.remove('scan_history');
  }
}
