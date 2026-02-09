import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'add_medicine_controller.dart';
import 'package:intl/intl.dart';

class AddMedicineView extends GetView<AddMedicineController> {
  const AddMedicineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: ListView(
            children: [
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.scanBarcode,
                    icon: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 28),
                    label: Text(
                      controller.isLoading.value
                          ? 'Reading Package...'
                          : 'AUTO-FILL FROM PHOTO',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 4,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Extract GTIN, Batch, and Expiry automatically using Gemini AI.',
                  style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Or enter details manually:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller.gtinController,
                decoration: const InputDecoration(
                  labelText: 'Product Code (GTIN)',
                  hintText: 'Enter the 13 or 14 digit code',
                ),
                style: const TextStyle(fontSize: 18),
                validator: (v) =>
                    v!.isEmpty ? 'Product code is required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: controller.serialController,
                decoration: const InputDecoration(
                  labelText: 'Unique Serial Number',
                  hintText: 'Found on the package',
                ),
                style: const TextStyle(fontSize: 18),
                validator: (v) =>
                    v!.isEmpty ? 'Serial number is required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: controller.batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number',
                  hintText: 'Lot/Batch code',
                ),
                style: const TextStyle(fontSize: 18),
                validator: (v) =>
                    v!.isEmpty ? 'Batch number is required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: controller.manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Maker / Manufacturer Name',
                ),
                style: const TextStyle(fontSize: 18),
                validator: (v) =>
                    v!.isEmpty ? 'Manufacturer name is required' : null,
              ),
              const SizedBox(height: 20),
              Obx(
                () => ListTile(
                  title: const Text(
                    'Expiration Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd().format(controller.expiryDate.value),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.blueAccent,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 32),
                  onTap: () => controller.pickDate(context),
                  tileColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.saveMedicine,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 4,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE MEDICINE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
