import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/company_profile.dart';
import '../../routes/app_pages.dart';
import 'firestore_service.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // v7.x uses a singleton instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  late Rx<User?> currentUser;
  final Rxn<AppUser> currentAppUser = Rxn<AppUser>();

  FirestoreService get _firestoreService => Get.find<FirestoreService>();

  final Rxn<GoogleSignInAccount> googleAccount = Rxn<GoogleSignInAccount>();
  UserRole? _ongoingLoginRole;

  @override
  void onInit() {
    super.onInit();
    currentUser = Rx<User?>(_auth.currentUser);
    currentUser.bindStream(_auth.authStateChanges());

    _initGoogleSignIn();

    ever(currentUser, _handleAuthChanged);

    ever(currentAppUser, (AppUser? user) {
      if (user != null) {
        print(
          'DEBUG [AuthService]: currentAppUser changed - UID: ${user.uid}, Role: ${user.role}',
        );
      }
    });

    if (_auth.currentUser != null) {
      _handleAuthChanged(_auth.currentUser);
    }
  }

  Future<void> _initGoogleSignIn() async {
    try {
      // v7.x MUST be initialized before use
      await _googleSignIn.initialize();
      print('DEBUG [AuthService]: GoogleSignIn initialized (v7.x)');
    } catch (e) {
      print('GoogleSignIn initialize error: $e');
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    print('DEBUG [AuthService]: _handleAuthChanged called for ${user?.email}');
    if (user == null) {
      currentAppUser.value = null;
      googleAccount.value = null;
      return;
    }

    // Attempt to restore Google session pre-emptively
    if (googleAccount.value == null) {
      try {
        final account = await _googleSignIn.attemptLightweightAuthentication();
        if (account != null) {
          googleAccount.value = account;
          print('DEBUG [AuthService]: Google session restored pre-emptively');
        }
      } catch (e) {
        print('DEBUG [AuthService]: Pre-emptive silent restoration failed: $e');
      }
    }

    // 1. Explicit Regular User Login (Skip Firestore)
    if (_ongoingLoginRole == UserRole.user) {
      print(
        'DEBUG [AuthService]: Explicit Regular User Login. Skipping Firestore.',
      );
      currentAppUser.value = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: UserRole.user,
        companyId: null,
      );
      return;
    }

    // 2. Explicit Distributor/Pharmacy Login (Verify & Write)
    if (_ongoingLoginRole == UserRole.distributor ||
        _ongoingLoginRole == UserRole.pharmacy) {
      print(
        'DEBUG [AuthService]: Explicit Partner Login. Verifying $_ongoingLoginRole...',
      );

      // Check if user already exists in 'users' collection
      AppUser? existingUser = await _firestoreService.getUser(user.uid);

      if (existingUser != null) {
        // Enforce the requested role
        if (existingUser.role != _ongoingLoginRole) {
          // If the role in DB doesn't match the requested role, we might want to verify again.
          // For now, let's load what is in DB to maintain consistency.
          currentAppUser.value = existingUser;
          return;
        }
        currentAppUser.value = existingUser;
        return;
      }

      // If new, verify against the respective collection
      CompanyProfile? profile;
      if (_ongoingLoginRole == UserRole.distributor) {
        profile = await _firestoreService.getDistributorProfileByEmail(
          user.email ?? '',
        );
      } else {
        profile = await _firestoreService.getPharmacyProfileByEmail(
          user.email ?? '',
        );
      }

      if (profile != null) {
        print('DEBUG [AuthService]: Email verified in $profile list.');
        final newUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          role: _ongoingLoginRole!,
          companyId: profile.id,
        );
        await _firestoreService.saveUser(newUser);
        currentAppUser.value = newUser;
      } else {
        print(
          'DEBUG [AuthService]: NOT AUTHORIZED. Email not found for $_ongoingLoginRole.',
        );
        Get.snackbar(
          'Access Denied',
          'Your email is not registered as a ${_ongoingLoginRole.toString().split('.').last}.',
        );
        await signOut();
      }
      return;
    }

    // 3. Auto-Login (App Restart) - _ongoingLoginRole is null
    print(
      'DEBUG [AuthService]: Auto-login. Checking Firestore for existing partner...',
    );
    AppUser? appUser = await _firestoreService.getUser(user.uid);

    if (appUser != null) {
      print('DEBUG [AuthService]: Found existing user in Firestore.');
      currentAppUser.value = appUser;
    } else {
      print(
        'DEBUG [AuthService]: User not found in Firestore. Defaulting to Regular User (No Write).',
      );
      // Default to Regular User without saving to DB
      currentAppUser.value = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: UserRole.user,
        companyId: null,
      );
    }
  }

  Future<void> signInWithGoogle({UserRole? desiredRole}) async {
    _ongoingLoginRole = desiredRole;
    print('DEBUG [AuthService.signInWithGoogle]: Starting v7 authenticate...');

    try {
      // v7 uses authenticate() for interactive sign-in
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      if (googleUser != null) {
        googleAccount.value = googleUser;

        // Authentication properties are now synchronous on the account
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          // accessToken is often null in v7 unless scopes are authorized separately,
          // but identity (idToken) is sufficient for Firebase.
        );

        await _auth.signInWithCredential(credential);
        print('DEBUG [AuthService.signInWithGoogle]: Firebase complete');
      }
    } catch (e) {
      print('DEBUG [AuthService.signInWithGoogle]: ERROR: $e');
      if (e.toString().contains('canceled')) {
        print('User cancelled login');
      } else {
        Get.snackbar('Error', 'Sign in failed: $e');
      }
    }
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    // 1. Check if we already have the account
    GoogleSignInAccount? account = googleAccount.value;

    // 2. If not, attempt to restore it silently (lazy restoration)
    if (account == null) {
      try {
        account = await _googleSignIn.attemptLightweightAuthentication();
        if (account != null) {
          googleAccount.value = account;
        }
      } catch (e) {
        print(
          'DEBUG [AuthService.getAuthHeaders]: Silent restoration failed: $e',
        );
      }
    }

    if (account == null) {
      print(
        'DEBUG [AuthService.getAuthHeaders]: No account available even after restoration',
      );
      return null;
    }

    final scopes = [
      'email',
      'https://www.googleapis.com/auth/generative-language.peruserquota',
      'https://www.googleapis.com/auth/generative-language.retriever',
    ];

    try {
      // v7 uses authorizationClient to manage scopes and headers
      return await account.authorizationClient.authorizationHeaders(scopes);
    } catch (e) {
      print('DEBUG [AuthService.getAuthHeaders]: Error: $e');
      // If unauthorized, try to authorize (shows consent dialog)
      try {
        await account.authorizationClient.authorizeScopes(scopes);
        return await account.authorizationClient.authorizationHeaders(scopes);
      } catch (e2) {
        print('Double authorization failed: $e2');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Ensure initialized before signOut to avoid channel error
      await _googleSignIn.initialize();
      await _googleSignIn.signOut();
      await _auth.signOut();
      currentAppUser.value = null;
      googleAccount.value = null;
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      print('Sign out error: $e');
      await _auth.signOut();
      currentAppUser.value = null;
      googleAccount.value = null;
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
