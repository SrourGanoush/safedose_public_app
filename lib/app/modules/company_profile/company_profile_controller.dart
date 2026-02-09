import 'package:get/get.dart';

import '../../data/services/firestore_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/company_profile.dart'; // Assuming CompanyProfile model is here
import '../../data/models/user_model.dart';

class CompanyProfileController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();

  final isLoading = false.obs;
  final profile = Rxn<CompanyProfile>();

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      isLoading.value = true;
      final user = _authService.currentAppUser.value;
      print('loading profile: ${user!.companyId}');

      if (user?.companyId != null) {
        print('loading profile: ${user!.companyId}');
        CompanyProfile? fetchedProfile;

        if (user.role == UserRole.pharmacy) {
          fetchedProfile = await _firestoreService.getPharmacyProfile(
            user.companyId!,
          );
        } else {
          // Default to distributor for now (or explicitly check)
          fetchedProfile = await _firestoreService.getDistributorProfile(
            user.companyId!,
          );
        }

        if (fetchedProfile != null) {
          profile.value = fetchedProfile;
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
