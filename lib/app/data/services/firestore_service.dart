import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/medicine.dart';
import '../models/company_profile.dart';
import '../models/user_model.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ USER MANAGEMENT ============
  Future<void> saveUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // ============ COMPANY PROFILE ============
  Future<String> saveCompanyProfile(
    CompanyProfile profile,
    String userId,
  ) async {
    try {
      String companyId;
      if (profile.id != null && profile.id!.isNotEmpty) {
        // Update existing profile
        await _db
            .collection('distributors')
            .doc(profile.id)
            .set(profile.toMap(), SetOptions(merge: true));
        companyId = profile.id!;
      } else {
        // Create new profile and link to user
        DocumentReference docRef = await _db
            .collection('distributors')
            .add(profile.toMap());
        companyId = docRef.id;
        // Update user with companyId
        await _db.collection('users').doc(userId).update({
          'companyId': companyId,
        });
      }
      return companyId;
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  Future<CompanyProfile?> getDistributorProfile(String companyId) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('distributors')
          .doc(companyId)
          .get();
      if (doc.exists) {
        return CompanyProfile.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting distributor profile: $e');
      return null;
    }
  }

  Future<CompanyProfile?> getDistributorProfileByEmail(String email) async {
    try {
      QuerySnapshot query = await _db
          .collection('distributors')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return CompanyProfile.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting distributor profile by email: $e');
      return null;
    }
  }

  Future<CompanyProfile?> getPharmacyProfileByEmail(String email) async {
    try {
      QuerySnapshot query = await _db
          .collection('pharmacies')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return CompanyProfile.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting pharmacy profile by email: $e');
      return null;
    }
  }

  Future<CompanyProfile?> getPharmacyProfile(String companyId) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('pharmacies')
          .doc(companyId)
          .get();
      if (doc.exists) {
        return CompanyProfile.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting pharmacy profile: $e');
      return null;
    }
  }

  // ============ MEDICINE ============
  Future<void> addMedicine(Medicine medicine) async {
    try {
      String docId = medicine.gtin;
      await _db.collection('medicines').doc(docId).set(medicine.toMap());
    } catch (e) {
      print('Error adding medicine: $e');
      rethrow;
    }
  }

  Future<Medicine?> getMedicine(String gtin, String serialNumber) async {
    print(
      'DEBUG [FirestoreService]: Fetching medicine - GTIN: $gtin, Serial: $serialNumber',
    );
    try {
      String docId = gtin;
      print('DEBUG [FirestoreService]: Querying Firestore with docId: $docId');
      DocumentSnapshot doc = await _db.collection('medicines').doc(docId).get();
      if (doc.exists) {
        return Medicine.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting medicine: $e');
      return null;
    }
  }

  Future<void> updateMedicineStatus(
    String gtin,
    String serialNumber,
    String newStatus,
    String updatedByUserId,
  ) async {
    try {
      String docId = gtin;
      DocumentReference docRef = _db.collection('medicines').doc(docId);

      // Add to status history
      await docRef.update({
        'status': newStatus,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'timestamp': DateTime.now().toIso8601String(),
            'updatedBy': updatedByUserId,
          },
        ]),
      });
    } catch (e) {
      print('Error updating medicine status: $e');
      rethrow;
    }
  }

  Future<void> submitReport({
    required String? gtin,
    required String? serial,
    required String reason,
    required String description,
    required String? userId,
    required String? scanData,
    String? imageUrl, // In a real app we'd upload image and get URL
    Map<String, dynamic>? location, // New Location parameter
  }) async {
    await _db.collection('reports').add({
      'gtin': gtin,
      'serialNumber': serial,
      'reason': reason, // e.g., "Counterfeit", "Expired", "Suspicious"
      'description': description,
      'reportedBy': userId,
      'scanData': scanData,
      'location': location, // Store location data
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending', // Pending review by authorities
    });
  }

  Future<Medicine?> findMedicineByBatch(String gtin, String batch) async {
    try {
      QuerySnapshot query = await _db
          .collection('medicines')
          .where('gtin', isEqualTo: gtin)
          .where('batchNumber', isEqualTo: batch)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Medicine.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error finding medicine: $e');
      return null;
    }
  }
}
