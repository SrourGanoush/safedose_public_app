import 'package:get/get.dart';
import 'role_selection_controller.dart';

class RoleSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<RoleSelectionController>(RoleSelectionController());
  }
}
