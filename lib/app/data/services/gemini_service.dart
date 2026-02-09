import 'dart:typed_data';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:get/get.dart';
import '../models/medicine.dart';

class GeminiService extends GetxService {
  // TODO: Replace with your own Gemini API key from https://aistudio.google.com/app/apikey
  static const _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  late final GenerativeModel _model;

  @override
  void onInit() {
    super.onInit();
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }

  Future<String> analyzeMedicine(
    String scannedData,
    Medicine? ledgerData, [
    List<int>? imageBytes,
  ]) async {
    print('DEBUG [GeminiService]: analyzeMedicine called');
    print('DEBUG [GeminiService]: scannedData = $scannedData');
    print('DEBUG [GeminiService]: ledgerData = ${ledgerData?.toMap()}');
    print(
      'DEBUG [GeminiService]: imageBytes length = ${imageBytes?.length ?? 0}',
    );

    try {
      final prompt =
          '''
      You are an expert pharmaceutical analyst. 
      Input Scanned Data: "$scannedData".
      Ledger Data Found: ${ledgerData != null ? ledgerData.toMap().toString() : "No record found in official ledger"}.
      
      TASK:
      1. ANALYZE IMAGE: Look at the provided medicine photo. Identify the product name, physical markings, and dosage form. 
      2. VERIFY: Compare the physical package in the photo with the scanned Ledger Data.
      3. SEARCH: Mentally cross-reference with official product images (internet knowledge).
      4. VERDICT: Provide a clear, definitive verdict.
      
      STRUCTURE:
      - If the image looks different from what is expected for this product (fake, wrong packaging, or mismatch with internet images), start with "VERDICT: VISUAL MISMATCH".
      - If it matches well, start with "VERDICT: MATCH".
      - Follow with a concise explanation (max 2 sentences) suitable for an elderly user.
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          if (imageBytes != null)
            DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ];

      print('DEBUG [GeminiService]: Calling generateContent...');
      final stopwatch = Stopwatch()..start();

      final response = await _model.generateContent(content);

      stopwatch.stop();
      print(
        'DEBUG [GeminiService]: Completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      print('DEBUG [GeminiService]: response.text = ${response.text}');

      return response.text ?? 'Unable to generate analysis.';
    } catch (e, stackTrace) {
      print('DEBUG [GeminiService]: ERROR: $e');
      print('DEBUG [GeminiService]: Stack: $stackTrace');
      return 'AI Verification Error: $e';
    }
  }

  Future<Map<String, String>> extractMedicineDetails(
    List<int> imageBytes,
  ) async {
    try {
      final prompt = '''
      You are an expert pharmaceutical analyst. From the provided image of a medicine package, extract the following details precisely:
      1. GTIN (13 or 14 digits barcode number).
      2. Batch Number / Lot Number (often labeled as Batch, Lot, or (10)).
      3. Expiry Date (Format: YYYY-MM-DD). If only MM/YYYY is present, use the last day of that month.
      4. Manufacturer / Medicine Name.
      5. Serial Number (SN) - Look for labels like "SN", "S/N", "Ser", or "(21)". 
      6. Code Type (e.g., "EAN-13", "GS1 DataMatrix", "QR Code").

      Return ONLY a JSON object with keys: "gtin", "batch", "expiry", "name", "serial", "codeType".
      Example: {"gtin": "1234567890123", "batch": "B123", "expiry": "2025-12-31", "name": "Panadol", "serial": "SN456", "codeType": "EAN-13"}
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';

      final cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      print(cleanJson);
      final Map<String, dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('AI Extraction Error: $e');
      return {};
    }
  }

  Future<String> explainMedicine(
    String medicineName,
    String contextInfo,
  ) async {
    try {
      final prompt =
          '''
      You are a helpful pharmacist assistant for the elderly.
      Based on the medicine name "$medicineName" and context "$contextInfo":
      1. Explain simply what this medicine is used for.
      2. Provide 1-2 key safety tips (e.g., take with food, causes drowsiness).
      
      Keep it very short (max 3 sentences). Simple language.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Could not explain this medicine.';
    } catch (e) {
      return 'Error explaining medicine: $e';
    }
  }

  Future<String> translateLabel(String text, String targetLang) async {
    try {
      final prompt =
          '''
      Translate the following medicine label text to $targetLang:
      "$text"
      
      Keep the translation accurate but easy to understand.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Translation failed.';
    } catch (e) {
      return 'Error translating: $e';
    }
  }
}
