# Push Notifications Setup Guide

This app now supports push notifications using Firebase Cloud Messaging (FCM). Follow these steps to enable push notifications.

## Prerequisites

1. A Firebase project (create one at https://console.firebase.google.com)
2. Firebase CLI installed: `npm install -g firebase-tools`

## Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project" or select existing project
3. Enter project name (e.g., "Cart Link")
4. Follow the setup wizard

### 2. Add Android App to Firebase

1. In Firebase Console, click "Add app" → Select Android
2. Enter package name: `com.example.cart_link` (must match `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Replace the placeholder file at `android/app/google-services.json` with your downloaded file

### 3. Add iOS App to Firebase (Optional)

1. In Firebase Console, click "Add app" → Select iOS
2. Enter iOS bundle ID from `ios/Runner/Info.plist`
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/GoogleService-Info.plist`

### 4. Update Firebase Configuration

The placeholder `google-services.json` in this repo is just for demonstration. Replace it with your actual Firebase configuration file.

### 5. Enable Cloud Messaging

1. In Firebase Console, go to Project Settings → Cloud Messaging
2. Enable Cloud Messaging API
3. Note your Server Key (for backend notifications)

### 6. Install Dependencies

```bash
flutter pub get
```

### 7. Update Backend (Optional)

To send notifications from your backend server, update the backend to use Firebase Admin SDK:

```bash
npm install firebase-admin
```

Then initialize in your backend:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send notification
admin.messaging().send({
  token: userFcmToken,
  notification: {
    title: 'New Offer!',
    body: 'Check out this amazing deal'
  },
  data: {
    type: 'offer',
    productId: '123'
  }
});
```

## Testing Notifications

### Test from Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter your FCM token (printed in app logs on startup)
4. Send notification

### Test from Backend

Use the backend endpoint to send notifications:

```bash
POST /api/notifications/send
{
  "customerId": "user123",
  "title": "Test Notification",
  "body": "This is a test",
  "data": {
    "type": "offer"
  }
}
```

## Features Implemented

✅ Request notification permission with user-friendly dialog
✅ Display push notifications when app is in background
✅ Show in-app notification banner when app is in foreground
✅ Handle notification taps to navigate to relevant pages
✅ Save FCM token to backend for targeted notifications
✅ Topic-based subscriptions (e.g., subscribe to shop updates)
✅ Notification badge count on notification icon

## Notification Types

The app supports these notification types:

- **Offers**: New offers from followed shops
- **Orders**: Order status updates (confirmed, shipped, delivered)
- **Products**: New products from favorite shops
- **General**: App updates and announcements

## Running Without Firebase

The app gracefully handles missing Firebase configuration. If Firebase is not initialized, the app will still work but push notifications will be disabled.

## Troubleshooting

### Android

- Ensure `google-services.json` is placed in `android/app/`
- Check package name matches in Firebase Console and `build.gradle.kts`
- For Android 13+, ensure `POST_NOTIFICATIONS` permission is granted

### iOS

- Add `GoogleService-Info.plist` to Xcode project
- Enable Push Notifications capability in Xcode
- Ensure bundle ID matches Firebase configuration

### Permission Issues

If notifications don't work:
1. Check app permissions in device settings
2. Verify FCM token is printed in logs
3. Test with Firebase Console test message
4. Ensure internet connection is available

## Backend Integration

To integrate with your backend, update the customer model to include `fcmToken`:

```javascript
// Customer Schema
{
  _id: ObjectId,
  customerName: String,
  email: String,
  mobile: Number,
  fcmToken: String,  // Add this field
  // ... other fields
}
```

Add endpoint to update FCM token:

```javascript
PUT /api/customers/:id/fcm-token
{
  "fcmToken": "device-token-here"
}
```

## Notes

- FCM tokens can change; the app automatically updates the backend when token refreshes
- Notifications work on both Android and iOS
- Local notifications display when app is in foreground
- System notifications display when app is in background/terminated
