# SSS Smart Employee ID Generator
### She Software Solutions

Flutter + Firebase app to generate premium employee ID cards with Code128 barcodes.

## Features
- Email/password login (Firebase Auth)
- Role-based access from Firestore `users` collection
- Optional in-app account creation (for testing)
- Admin: add employees, edit/delete records
- User: read-only employee list
- Premium vertical ID card preview + export to gallery

## Firestore schema
### `users` collection
- Document ID: user email (lowercase)
- Fields: `{ role: "admin" | "user" }`

### `employees` collection
Stores employee records as `Map<String, dynamic>`:
```
{
  id,
  employeeId,
  name,
  role,
  email,
  phone,
  dob,        // ISO-8601 string
  imageBase64 // optional (photo stored in Firestore for Spark/free plan)
  imageUrl,   // optional (legacy/optional if Storage is enabled)
  createdAt   // server timestamp
}
```

## Security rules
- Firestore rules: `firestore.rules` (employees write = admin-only)
- Storage rules: `storage.rules` (only needed if you enable Firebase Storage)

## Firebase setup notes
- Android config is included: `android/app/google-services.json`
- If you need iOS/macOS builds, add:
  - `ios/Runner/GoogleService-Info.plist`
  - `macos/Runner/GoogleService-Info.plist`

## Project structure
```
lib/
  core/
  screens/
  services/
  widgets/
```
