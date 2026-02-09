import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: () {
              Get.defaultDialog(
                title: 'Clear History',
                middleText: 'Are you sure you want to delete all scan records?',
                textConfirm: 'Delete',
                textCancel: 'Cancel',
                confirmTextColor: Colors.white,
                onConfirm: () {
                  controller.clearHistory();
                  Get.back();
                },
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No scan history yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.records.length,
          itemBuilder: (context, index) {
            final record = controller.records[index];
            final dateStr = DateFormat(
              'MMM d, h:mm a',
            ).format(record.timestamp);

            Color statusColor = Colors.grey;
            IconData icon = Icons.help_outline;

            if (record.verificationResult.contains('Verified') ||
                record.status == 'Received') {
              statusColor = Colors.green;
              icon = Icons.verified;
            } else if (record.verificationResult.contains('Not Found') ||
                record.verificationResult.contains('Warning')) {
              statusColor = Colors.red;
              icon = Icons.warning;
            } else if (record.status == 'Sold') {
              statusColor = Colors.orange;
              icon = Icons.shopping_bag;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(icon, color: statusColor),
                ),
                title: Text(
                  record.manufacturerName.isNotEmpty
                      ? record.manufacturerName
                      : 'Unknown Product',
                ),
                subtitle: Text('$dateStr • ${record.status}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow('GTIN', record.gtin),
                        _buildRow('Serial', record.serialNumber),
                        _buildRow('Status', record.status),
                        const Divider(),
                        _buildRow(
                          'Result',
                          record.verificationResult,
                          color: statusColor,
                        ),
                        if (record.aiSummary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'AI Summary:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            record.aiSummary,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
