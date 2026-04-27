# Submission Guide — Employee Details App

This repository contains a Flutter + Firebase application for generating employee ID cards with Code128 barcodes.

## Contents
- Full Flutter source code (open in Android Studio)
- Security rules files:
  - `firestore.rules` (employees write = admin-only)
  - `storage.rules` (photo upload = admin-only)
- A release APK (path after build): `build/app/outputs/flutter-apk/app-release.apk`

## Prerequisites (for reviewers)
- Flutter SDK installed
- Android Studio / Android SDK installed
- Firebase project with:
  - Firebase Authentication enabled (Email/Password)
  - Cloud Firestore enabled
  - Firebase Storage enabled

## Setup
1) Open the project folder in Android Studio.
2) Run: `flutter pub get`
3) Ensure Firebase config is present:
   - Android: `android/app/google-services.json`

## Deploy security rules (recommended)
- Firestore Rules: copy/paste `firestore.rules` into Firebase Console → Firestore → Rules.
- Storage Rules: copy/paste `storage.rules` into Firebase Console → Storage → Rules.

## Firestore schema
### `users` collection
- Document ID: user email (lowercase)
- Fields:
  - `role`: `"admin"` or `"user"`

### `employees` collection (created by admins)
Common fields:
- `employeeId`, `name`, `role`, `email`, `phone`, `dob`
- `imageUrl` (optional)
- `createdAt` / `timestamp` (server timestamp)

## Test flow (recommended)
1) Install/run the app.
2) Create a test user from the login screen using **Create Account (User)**.
3) Promote to admin:
   - Firebase Console → Firestore → `users/<email>` → set `role = "admin"`.
4) Logout and login again to load the admin role.
5) Admin can:
   - Add Employee → Preview → Save to Firestore
   - Export the ID card image to gallery
   - Edit/Delete employees from the Employees list
6) Normal user can:
   - View/Search employees
   - Open a record and export the ID card image

## Build APK
- Release build: `flutter build apk --release`
- Output: `build/app/outputs/flutter-apk/app-release.apk`

