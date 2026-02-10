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
- A Google Cloud / Firebase project with the **Generative Language API** enabled

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

4. **Enable the Generative Language API**
   
   SafeDose uses **per-user OAuth quota** for Gemini — no API key is needed in the code.
   Each user's Gemini usage is billed to their own Google account.
   
   In your [Google Cloud Console](https://console.cloud.google.com/apis/library), enable:
   - **Generative Language API**
   
   Ensure your Firebase project's OAuth client ID is configured for Android (this is done automatically by `flutterfire configure`).

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

## 🔑 What Happens on Login

When a user signs in with Google, they will see a **consent screen** requesting the following permissions:
- **Google Sign-In** — For authentication and profile access
- **Generative Language API (Gemini)** — To allow the app to use Gemini AI on behalf of the user

This is expected behavior. The app uses **per-user OAuth quota**, meaning each user's AI requests are counted against their own free Google API quota rather than a shared API key. No API key is stored in the app.

---

## 🔐 Security Notes

The following files contain sensitive data and are **excluded from version control** via `.gitignore`:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

If you fork this repo, you **must** generate your own Firebase configuration using `flutterfire configure`.

