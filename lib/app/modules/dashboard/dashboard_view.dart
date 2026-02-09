import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../home/home_view.dart' hide HomeController;
import '../home/home_controller.dart';
import '../add_medicine/add_medicine_view.dart';
import '../add_medicine/add_medicine_controller.dart';
import '../pharmacy_scan/pharmacy_scan_view.dart';
import '../pharmacy_scan/pharmacy_scan_controller.dart';
import '../pharmacy_sell/pharmacy_sell_view.dart';
import '../pharmacy_sell/pharmacy_sell_controller.dart';
import '../history/history_view.dart';
import '../history/history_controller.dart';
import '../../routes/app_pages.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Initialize layout based on role
      _ensureControllers();

      return Scaffold(
        appBar: AppBar(
          title: const Text('SafeDose'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 32),
              tooltip: 'Logout',
              onPressed: controller.logout,
            ),
          ],
        ),
        drawer: _buildDrawer(),
        // Only build the active screen to avoid camera conflicts
        body: _buildActiveScreen(),
        bottomNavigationBar: BottomNavigationBar(
          onTap: controller.changeTabIndex,
          currentIndex: controller.tabIndex.value,
          selectedFontSize: 16,
          unselectedFontSize: 14,
          iconSize: 32,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: controller.isPharmacy
              ? Colors.orange
              : Colors.blue,
          items: _buildNavItems(),
        ),
      );
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: controller.isPharmacy ? Colors.orange : Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'SafeDose',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.isPharmacy
                      ? 'Pharmacy Portal'
                      : (controller.isDistributor
                            ? 'Distributor Portal'
                            : 'User Portal'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.business, size: 32),
            title: const Text(
              'Company Profile',
              style: TextStyle(fontSize: 18),
            ),
            onTap: () {
              Get.back();
              Get.toNamed(Routes.COMPANY_PROFILE);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 32),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Get.back();
              controller.logout();
            },
          ),
        ],
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    if (controller.isPharmacy) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan Medicine',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'Mark as Sold',
        ),
      ];
    } else if (controller.isDistributor) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Verify Medicine',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box),
          label: 'Register New',
        ),
      ];
    } else {
      // Regular User
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Verify Medicine',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Scan History',
        ),
      ];
    }
  }

  // Build only the active screen to prevent camera conflicts
  Widget _buildActiveScreen() {
    if (controller.isPharmacy) {
      switch (controller.tabIndex.value) {
        case 0:
          return const PharmacyScanView();
        case 1:
          return const PharmacySellView();
        default:
          return const PharmacyScanView();
      }
    } else if (controller.isDistributor) {
      switch (controller.tabIndex.value) {
        case 0:
          return const HomeView();
        case 1:
          return const AddMedicineView();
        default:
          return const HomeView();
      }
    } else {
      // Regular User
      switch (controller.tabIndex.value) {
        case 0:
          return const HomeView();
        case 1:
          return const HistoryView(); // New History View
        default:
          return const HomeView();
      }
    }
  }

  void _ensureControllers() {
    if (controller.isPharmacy) {
      if (!Get.isRegistered<PharmacyScanController>()) {
        Get.put<PharmacyScanController>(PharmacyScanController());
      }
      if (!Get.isRegistered<PharmacySellController>()) {
        Get.put<PharmacySellController>(PharmacySellController());
      }
    } else {
      // Both User and Distributor need Home (Verifier)
      if (!Get.isRegistered<HomeController>()) {
        Get.put<HomeController>(HomeController());
      }

      if (controller.isDistributor) {
        if (!Get.isRegistered<AddMedicineController>()) {
          Get.put<AddMedicineController>(AddMedicineController());
        }
      } else {
        // Regular User needs History
        if (!Get.isRegistered<HistoryController>()) {
          Get.put<HistoryController>(HistoryController());
        }
      }
    }
  }
}
