# SafeDose 💊

**SafeDose** is a three-tier pharmaceutical security platform that combats counterfeit medicine using a secure role-based database ledger and **Gemini Vision AI** for visual verification.

## Features

- **Distributor Portal**: Register medicine batches to an immutable Firestore ledger
- **Pharmacy Dashboard**: Verify shipments and mark medicines as "Sold" to prevent reuse
- **Patient Verification**: Scan barcodes + AI-powered visual analysis to detect counterfeits
- **Accessibility**: Text-to-Speech announcements and label translation for elderly users

## Built With

**Dart, Flutter, GetX, Firebase (Firestore, Auth), Google Gemini 2.5 Flash API, GS1 DataMatrix**

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
- A Google Cloud / Firebase project
- A Gemini API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd safedose
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   
   Run the FlutterFire CLI to generate your own Firebase configuration files:
   ```bash
   flutterfire configure
   ```
   This will create:
   - `android/app/google-services.json`
   - `lib/firebase_options.dart`

4. **Add your Gemini API Key**
   
   Get a free API key from [Google AI Studio](https://aistudio.google.com/app/apikey).
   
   Open `lib/app/data/services/gemini_service.dart` and replace the placeholder:
   ```dart
   static const _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```

5. **Set up Firestore Collections**
   
   In your Firebase Console, create the following collections:
   - `users` - Stores authenticated user profiles
   - `distributors` - Verified distributor company profiles
   - `pharmacies` - Verified pharmacy company profiles
   - `medicines` - The medicine ledger (document ID = GTIN)

6. **Deploy Firestore Security Rules**
   
   The repository includes `firestore.rules` with role-based access control. Deploy them:
   ```bash
   firebase deploy --only firestore:rules
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 User Roles

| Role | Access |
|------|--------|
| **Distributor** | Register medicine, View company profile |
| **Pharmacy** | Verify & sell medicine, View company profile |
| **Regular User** | Verify medicine, View scan history |

---

## 🔐 Security Notes

The following files contain sensitive data and are **excluded from version control** via `.gitignore`:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

If you fork this repo, you **must** generate your own Firebase configuration using `flutterfire configure`.

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
