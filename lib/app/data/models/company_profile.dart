class CompanyProfile {
  String? id;
  String name;
  String license;
  String address;
  String phone;
  String email;
  String? website;

  CompanyProfile({
    this.id,
    required this.name,
    required this.license,
    required this.address,
    required this.phone,
    required this.email,
    this.website,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'license': license,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map, String id) {
    return CompanyProfile(
      id: id,
      name: map['name'] ?? '',
      license: map['license'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'],
    );
  }
}
