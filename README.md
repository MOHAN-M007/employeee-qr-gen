# SSS Smart Employee ID Generator
### She Software Solutions

Flutter + Firebase app to generate premium employee ID cards with Code128 barcodes.

## Features
- Email/password login (Firebase Auth)
- Role-based access from Firestore `users` collection
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
  imageBase64 // optional
  createdAt   // server timestamp
}
```

## Project structure
```
lib/
  core/
  screens/
  services/
  widgets/
```

