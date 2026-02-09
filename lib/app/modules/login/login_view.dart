import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                'SafeDose',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Protecting your health by verifying your medicine',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              Obx(
                () => controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Partner Login Button (Distributor or Pharmacy)
                            ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Select Partner Type',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Get.back(); // Close sheet
                                            controller.loginAsDistributor();
                                          },
                                          icon: const Icon(
                                            Icons.business,
                                            size: 28,
                                          ),
                                          label: const Text(
                                            'I am a Distributor',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            minimumSize: const Size(
                                              double.infinity,
                                              50,
                                            ),
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Get.back(); // Close sheet
                                            controller.loginAsPharmacy();
                                          },
                                          icon: const Icon(
                                            Icons.local_pharmacy,
                                            size: 28,
                                          ),
                                          label: const Text('I am a Pharmacy'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            minimumSize: const Size(
                                              double.infinity,
                                              50,
                                            ),
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.store, size: 28),
                              label: const Text('LOGIN AS PARTNER'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                minimumSize: const Size(double.infinity, 60),
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 2. Regular User Login Button
                            OutlinedButton.icon(
                              onPressed: controller.loginAsRegularUser,
                              icon: const Icon(Icons.person, size: 28),
                              label: const Text('LOGIN AS REGULAR USER'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                minimumSize: const Size(double.infinity, 60),
                                side: const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                                foregroundColor: Colors.green,
                              ),
                            ),
                          ],
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
