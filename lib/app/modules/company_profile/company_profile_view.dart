import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'company_profile_controller.dart';

class CompanyProfileView extends GetView<CompanyProfileController> {
  const CompanyProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile'), elevation: 0),
      body: Obx(() {
        final profile = controller.profile.value;
        if (controller.isLoading.value || profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Distributor Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                context,
                icon: Icons.business,
                label: 'Company Name',
                value: profile.name.isNotEmpty ? profile.name : 'Not Available',
              ),
              _buildInfoCard(
                context,
                icon: Icons.badge,
                label: 'License',
                value: profile.license.isNotEmpty
                    ? profile.license
                    : 'Not Available',
              ),
              _buildInfoCard(
                context,
                icon: Icons.location_on,
                label: 'Address',
                value: profile.address.isNotEmpty
                    ? profile.address
                    : 'Not Available',
              ),
              _buildInfoCard(
                context,
                icon: Icons.phone,
                label: 'Phone Number',
                value: profile.phone.isNotEmpty
                    ? profile.phone
                    : 'Not Available',
              ),
              _buildInfoCard(
                context,
                icon: Icons.email,
                label: 'Email',
                value: profile.email.isNotEmpty
                    ? profile.email
                    : 'Not Available',
              ),
              _buildInfoCard(
                context,
                icon: Icons.language,
                label: 'Website',
                value: (profile.website?.isNotEmpty ?? false)
                    ? profile.website!
                    : 'Not Available',
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
