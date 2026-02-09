import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../home/home_controller.dart';
import '../add_medicine/add_medicine_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<AddMedicineController>(() => AddMedicineController());
  }
}
