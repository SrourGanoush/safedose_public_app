import 'package:get/get.dart';
import '../modules/home/home_view.dart';
import '../modules/home/home_controller.dart';
import '../modules/add_medicine/add_medicine_view.dart';
import '../modules/add_medicine/add_medicine_controller.dart';

import '../modules/dashboard/dashboard_binding.dart';
import '../modules/dashboard/dashboard_view.dart';
import '../modules/login/login_view.dart';
import '../modules/login/login_binding.dart';
import '../modules/login/auth_middleware.dart';
import '../modules/company_profile/company_profile_binding.dart';
import '../modules/company_profile/company_profile_view.dart';
import '../modules/role_selection/role_selection_binding.dart';
import '../modules/role_selection/role_selection_view.dart';

part 'app_routes.dart';

class AppPages {
  // Ensure the app starts at Login screen.
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.ROLE_SELECTION,
      page: () => const RoleSelectionView(),
      binding: RoleSelectionBinding(),
    ),
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.put<HomeController>(HomeController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.ADD_MEDICINE,
      page: () => const AddMedicineView(),
      binding: BindingsBuilder(() {
        Get.put<AddMedicineController>(AddMedicineController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.COMPANY_PROFILE,
      page: () => const CompanyProfileView(),
      binding: CompanyProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
