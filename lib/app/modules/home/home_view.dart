import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'home_controller.dart';
import '../../data/models/user_model.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          switch (controller.currentStep.value) {
            case VerificationStep.scanCode:
              return const Text('Step 1: Scan Barcode');
            case VerificationStep.capturePackage:
              return const Text('Step 2: Take Photo');
            case VerificationStep.result:
              return const Text('Step 3: Final Results');
            default:
              return const Text('Verification');
          }
        }),
        centerTitle: true,
      ),
      body: Obx(() {
        switch (controller.currentStep.value) {
          case VerificationStep.scanCode:
            return _buildScanStep(context);
          case VerificationStep.capturePackage:
            return _buildCaptureStep(context);
          case VerificationStep.result:
            return _buildResultStep(context);
          default:
            return const Center(child: CircularProgressIndicator());
        }
      }),
    );
  }

  Widget _buildScanStep(BuildContext context) {
    return Column(
      children: [
        // Camera View area
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Obx(
                () => MobileScanner(
                  key: ValueKey(controller.scannerKey.value),
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
              ),
              // Scan Overlay (Frame)
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
                      color: controller.scanResult.value.isNotEmpty
                          ? Colors.green.withOpacity(0.9)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.scanResult.value.isNotEmpty
                          ? 'Code detected: ${controller.scanResult.value.substring(0, controller.scanResult.value.length > 20 ? 20 : controller.scanResult.value.length)}...'
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
        // Instructions area
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
                'Step 1 of 2: Scan Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Point camera at the 2D DataMatrix or QR code',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.scanResult.value.isNotEmpty
                        ? controller.performScan
                        : null,
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      'SCAN CODE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
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

  Widget _buildCaptureStep(BuildContext context) {
    return Column(
      children: [
        // Camera View area (Preview only)
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Obx(
                () =>
                    controller.isCameraInitialized.value &&
                        controller.cameraController != null
                    ? SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                (controller
                                            .cameraController!
                                            .value
                                            .previewSize
                                            ?.height ??
                                        720)
                                    .toDouble(),
                            height:
                                (controller
                                            .cameraController!
                                            .value
                                            .previewSize
                                            ?.width ??
                                        1280)
                                    .toDouble(),
                            child: CameraPreview(controller.cameraController!),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              // Package Frame
              Center(
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Instructions area
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
                'VERIFY PACKAGE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Center the whole medicine package in the frame and tap the button below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.isCapturing.value
                        ? null
                        : controller.capturePackagePhoto,
                    icon: controller.isCapturing.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 28),
                    label: Text(
                      controller.isCapturing.value
                          ? 'CAPTURING...'
                          : 'TAKE VERIFICATION PHOTO',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ),
              Obx(
                () => TextButton(
                  onPressed: controller.isCapturing.value
                      ? null
                      : controller.resetScan,
                  child: const Text('Go back to Step 1'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context),
          const SizedBox(height: 24),
          Text(
            'Official Ledger Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Medicine Details Card
          Obx(() {
            if (controller.foundMedicine.value != null) {
              final med = controller.foundMedicine.value!;
              return Card(
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
                      _buildDetailRow(Icons.qr_code, 'Batch', med.batchNumber),
                      const Divider(),
                      Obx(() {
                        Color expiryColor = Colors.black;
                        String label = 'Expiry';
                        if (controller.expiryStatus.value == 'Expired') {
                          expiryColor = Colors.red;
                          label = 'Expiry (EXPIRED)';
                        } else if (controller.expiryStatus.value ==
                            'Expiring Soon') {
                          expiryColor = Colors.orange;
                          label = 'Expiry (SOON)';
                        }
                        return _buildDetailRow(
                          Icons.calendar_today,
                          label,
                          med.expiryDate.toIso8601String().split('T')[0],
                          textColor: expiryColor,
                        );
                      }),
                      const Divider(),
                      _buildDetailRow(Icons.info_outline, 'Status', med.status),
                    ],
                  ),
                ),
              );
            }
            return Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'NOT REGISTERED: This medicine was not found in the official safety ledger.',
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
            );
          }),
          const SizedBox(height: 24),

          // --- Smart AI Actions ---
          Text(
            'Smart Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.explainMedicine(),
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text('Explain'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade50,
                    foregroundColor: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.translateLabel(
                    'English',
                  ), // Defaulting to English or Arabic? Let's assume English for now or flip based on locale.
                  icon: const Icon(Icons.translate),
                  label: const Text('Translate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade50,
                    foregroundColor: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.isExplaining.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.medicineExplanation.value.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Text(
                          "AI Assistant",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up,
                            color: Colors.purple,
                          ),
                          onPressed: () => controller.speakText(
                            controller.medicineExplanation.value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.medicineExplanation.value,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 24),
          // Pharmacy Actions
          Obx(() {
            if (controller.currentUserRole == UserRole.pharmacy &&
                controller.foundMedicine.value != null) {
              return Card(
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Medicine Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusButton('Received', Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatusButton('Sold', Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatusButton('Returned', Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 24),
          Text(
            'Visual AI Verification',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final isMismatch = controller.isVisualMismatch;
            final color = isMismatch ? Colors.red : Colors.green;
            final bgColor = isMismatch
                ? Colors.red.shade50
                : Colors.green.shade50;
            final borderColor = isMismatch
                ? Colors.red.shade200
                : Colors.green.shade100;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Column(
                children: [
                  if (isMismatch) ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'POTENTIAL COUNTERFEIT DETECTED',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.red.shade200),
                  ],
                  Text(
                    controller.geminiAnalysis.value.isEmpty
                        ? 'Wait for AI verdict...'
                        : controller.verificationVerdict,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // --- Report Button (Visible only if issues found) ---
          Obx(() {
            bool hasIssues =
                controller.isVisualMismatch ||
                controller.expiryStatus.value == 'Expired' ||
                controller.foundMedicine.value == null;

            if (hasIssues) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.reportToAuthorities,
                    icon: const Icon(Icons.report_problem),
                    label: const Text('REPORT TO AUTHORITIES'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.resetScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: const Text(
                'START NEW SCAN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color textColor = Colors.black,
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
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, Color color) {
    return Obx(
      () => ElevatedButton(
        onPressed: controller.isUpdatingStatus.value
            ? null
            : () => controller.updateMedicineStatus(status),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 14),
        ),
        child: controller.isUpdatingStatus.value
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(status),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;
    String status = controller.verificationStatus.value;

    if (status.contains('Authenticated')) {
      color = Colors.green;
      icon = Icons.verified;
    } else if (status.contains('Not Found')) {
      color = Colors.red;
      icon = Icons.warning;
    } else if (status.contains('Verifying')) {
      color = Colors.orange;
      icon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
