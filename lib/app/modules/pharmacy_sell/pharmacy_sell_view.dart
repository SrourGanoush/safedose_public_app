import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'pharmacy_sell_controller.dart';

class PharmacySellView extends GetView<PharmacySellController> {
  const PharmacySellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark as Sold'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        switch (controller.currentStep.value) {
          case 0:
            return _buildCameraView(context);
          case 1:
            return _buildLoadingView(context);
          case 2:
            return _buildSellView(context);
          default:
            return _buildCameraView(context);
        }
      }),
    );
  }

  // Step 0: Camera with Scan Button
  Widget _buildCameraView(BuildContext context) {
    return Column(
      children: [
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
                        Text('Scanner Error: ${error.errorCode}'),
                      ],
                    ),
                  );
                },
              ),
              // Scan Overlay Frame
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 3),
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
                          ? Colors.orange.withOpacity(0.9)
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
        // Instructions & Button
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
              const Icon(Icons.point_of_sale, size: 40, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                'Ready to Sell',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
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
                      'SCAN FOR SALE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
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

  // Step 1: Loading
  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            strokeWidth: 4,
          ),
          const SizedBox(height: 24),
          Obx(
            () => Text(
              controller.statusMessage.value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Sell Screen
  Widget _buildSellView(BuildContext context) {
    if (controller.foundMedicine.value == null) {
      // Not found view
      return _buildNotFoundView(context);
    }

    final med = controller.foundMedicine.value!;
    final alreadySold = med.status == 'Sold';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: controller.saleCompleted.value
                    ? Colors.green.withOpacity(0.1)
                    : alreadySold
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                border: Border.all(
                  color: controller.saleCompleted.value
                      ? Colors.green
                      : alreadySold
                      ? Colors.orange
                      : Colors.blue,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.saleCompleted.value
                        ? Icons.check_circle
                        : alreadySold
                        ? Icons.warning
                        : Icons.shopping_cart,
                    color: controller.saleCompleted.value
                        ? Colors.green
                        : alreadySold
                        ? Colors.orange
                        : Colors.blue,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      controller.statusMessage.value,
                      style: TextStyle(
                        color: controller.saleCompleted.value
                            ? Colors.green
                            : alreadySold
                            ? Colors.orange
                            : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Medicine Details
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
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.info_outline,
                    'Current Status',
                    med.status,
                    valueColor: med.status == 'Sold'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          if (!alreadySold && !controller.saleCompleted.value)
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isUpdating.value
                      ? null
                      : controller.markAsSold,
                  icon: controller.isUpdating.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sell, size: 28),
                  label: Text(
                    controller.isUpdating.value
                        ? 'PROCESSING...'
                        : 'MARK AS SOLD',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.resetScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(
                'SCAN NEXT ITEM',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
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
