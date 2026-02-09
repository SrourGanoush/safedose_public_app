enum UserRole { distributor, pharmacy, user }

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;
  final String? companyId; // Links to CompanyProfile for distributors

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    this.companyId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'companyId': companyId,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.user,
      ),
      companyId: map['companyId'],
    );
  }
}
