import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'pharmacy_scan_controller.dart';

class PharmacyScanView extends GetView<PharmacyScanController> {
  const PharmacyScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Medicine'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        switch (controller.currentStep.value) {
          case 0:
            return _buildCameraView(context);
          case 1:
            return _buildVerifyingView(context);
          case 2:
            return _buildResultsView(context);
          default:
            return _buildCameraView(context);
        }
      }),
    );
  }

  // Step 0: Camera preview with SCAN button
  Widget _buildCameraView(BuildContext context) {
    return Column(
      children: [
        // Camera Preview
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MobileScanner(
                controller: controller.scannerController,
                onDetect: controller.onScan,
                errorBuilder: (context, error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text('Camera Error: ${error.errorCode}'),
                      ],
                    ),
                  );
                },
              ),
              // Scan Frame Overlay
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Code detected indicator
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: controller.lastDetectedCode.value.isNotEmpty
                          ? Colors.green.withOpacity(0.9)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.lastDetectedCode.value.isNotEmpty
                          ? 'Code detected: ${controller.lastDetectedCode.value.substring(0, controller.lastDetectedCode.value.length > 20 ? 20 : controller.lastDetectedCode.value.length)}...'
                          : 'Point camera at barcode',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Scan Button Area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'VERIFY MEDICINE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Point camera at barcode, then tap SCAN',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.lastDetectedCode.value.isNotEmpty
                        ? controller.performScan
                        : null,
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      'SCAN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 1: Verifying (loading screen)
  Widget _buildVerifyingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 4),
          const SizedBox(height: 24),
          Obx(
            () => Text(
              controller.verificationStatus.value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Results screen
  Widget _buildResultsView(BuildContext context) {
    final med = controller.foundMedicine.value;

    if (med == null) {
      // Medicine not found
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Medicine Not Found',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This barcode is not registered in the system',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.resetScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'SCAN ANOTHER',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Medicine found
    final isExpired = med.expiryDate.isBefore(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 48),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Medicine Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Medicine Details Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.business,
                    'Manufacturer',
                    med.manufacturerName,
                  ),
                  const Divider(),
                  _buildDetailRow(Icons.qr_code, 'GTIN', med.gtin),
                  const Divider(),
                  _buildDetailRow(Icons.numbers, 'Batch', med.batchNumber),
                  const Divider(),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Expiry',
                    med.expiryDate.toIso8601String().split('T')[0],
                    valueColor: isExpired ? Colors.red : null,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.info_outline,
                    'Status',
                    med.status,
                    valueColor: med.status == 'Sold'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),
            ),
          ),

          // Expiry Warning
          if (isExpired) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'WARNING: This medicine has expired!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.resetScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('SCAN ANOTHER', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
