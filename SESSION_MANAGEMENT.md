# Session Management Implementation

This document describes the persistent session management system implemented for Cart Link, allowing users to stay logged in until they explicitly log out.

## Overview

The session management system has been implemented on both the **frontend (Flutter)** and **backend (Node.js/Express)** to provide a seamless authentication experience across web and mobile platforms.

## Frontend (Flutter) - Client-Side Sessions

### New Files Created

#### 1. `lib/services/auth_storage.dart`
Persistent storage service using SharedPreferences to store authentication tokens and user data locally.

**Key Features:**
- Stores JWT tokens and user data persistently
- Separate storage for Customer and Shop sessions
- Auto-login capability on app restart
- Works across web, Android, iOS, and desktop platforms

**Main Methods:**
```dart
// Customer methods
AuthStorage.saveCustomerSession(token: String, customerData: Map)
AuthStorage.getCustomerToken() -> String?
AuthStorage.getCustomerData() -> Map?
AuthStorage.isCustomerLoggedIn() -> bool
AuthStorage.clearCustomerSession()

// Shop methods
AuthStorage.saveShopSession(token: String, shopData: Map)
AuthStorage.getShopToken() -> String?
AuthStorage.getShopData() -> Map?
AuthStorage.isShopLoggedIn() -> bool
AuthStorage.clearShopSession()

// General methods
AuthStorage.getCurrentUserType() -> String? // 'customer', 'shop', or null
AuthStorage.clearAllSessions()
```

### Modified Files

#### 1. `lib/services/auth_state.dart`
Enhanced to integrate with persistent storage:
- Now saves sessions to SharedPreferences automatically
- Loads sessions from storage on demand
- Provides logout methods that clear both memory and persistent storage

**New Methods:**
```dart
AuthState.setOwner(owner, {token}) // Now saves to persistent storage
AuthState.setCustomer(customer, {token}) // Now saves to persistent storage
AuthState.loadOwnerFromStorage() // Load shop session from storage
AuthState.loadCustomerFromStorage() // Load customer session from storage
AuthState.isOwnerLoggedIn() -> bool
AuthState.isCustomerLoggedIn() -> bool
AuthState.logoutOwner() // Clear shop session
AuthState.logoutCustomer() // Clear customer session
AuthState.clearAll() // Clear all sessions
```

#### 2. `lib/main.dart`
Added `SplashScreen` widget that:
- Checks for existing sessions on app start
- Automatically navigates to the appropriate home page if a valid session exists
- Shows a loading screen during session check
- Redirects to login page if no valid session

#### 3. Login & Signup Pages
Updated to save sessions on successful authentication:
- `lib/Customer/login.dart` - Saves customer session on login
- `lib/Shops/login-Shops.dart` - Saves shop session on login
- `lib/Customer/singup.dart` - Saves customer session on registration
- `lib/Shops/signUp-Shops.dart` - Saves shop session on registration

#### 4. Logout Implementation
Updated logout functionality to clear persistent sessions:
- `lib/Customer/bottom bar/profile_page.dart` - Customer logout
- `lib/Shops/settings.dart` - Shop logout via settings
- `lib/Shops/bottom bar/profile_tab.dart` - Shop logout via profile

## Backend (Node.js/Express) - Server-Side Sessions

### Dependencies Added
```json
{
  "express-session": "^1.18.0",
  "connect-mongo": "^5.1.0"
}
```

### New Files Created

#### 1. `backend/src/middleware/sessionMiddleware.js`
Session management middleware providing:
- `requireAuth()` - Require any authenticated user
- `requireShopAuth()` - Require shop owner authentication
- `requireCustomerAuth()` - Require customer authentication
- `getSessionInfo()` - Get current session information

### Modified Files

#### 1. `backend/src/app.js`
Added session middleware configuration:
- Uses MongoDB to store sessions (persists across server restarts)
- Session cookie expires after 30 days
- Secure cookies in production
- Sessions are saved in the database

**Configuration:**
```javascript
app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    store: MongoStore.create({
        mongoUrl: process.env.MONGO_URI,
        touchAfter: 24 * 3600, // Update once per day
    }),
    cookie: {
        maxAge: 1000 * 60 * 60 * 24 * 30, // 30 days
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax'
    }
}));
```

#### 2. `backend/src/controllers/authController.js`
Updated shop authentication to store session data:
- `register()` - Stores shop session on registration
- `verifyCredentials()` - Stores shop session on login
- `logout()` - Destroys session on logout

**Session Data Stored:**
```javascript
req.session.userId = owner._id;
req.session.userType = 'shop';
req.session.shopName = owner.shopName;
```

#### 3. `backend/src/controllers/customerController.js`
Updated customer authentication to store session data:
- `register()` - Stores customer session on registration
- `verifyCredentials()` - Stores customer session on login
- `logout()` - Destroys session on logout

**Session Data Stored:**
```javascript
req.session.userId = customer._id;
req.session.userType = 'customer';
req.session.customerName = customer.customerName;
```

#### 4. Route Files
Added logout endpoints:
- `backend/src/routes/authRoutes.js` - Shop logout route
- `backend/src/routes/customerAuthRoutes.js` - Customer logout route

**New Endpoints:**
```
POST /api/auth/logout - Shop owner logout
POST /api/customersAuth/logout - Customer logout
GET /api/auth/session - Check shop session status
GET /api/customersAuth/session - Check customer session status
```

## How It Works

### On Login/Registration:
1. User enters credentials in the Flutter app
2. App sends request to backend
3. Backend validates credentials and creates JWT token
4. Backend stores user info in MongoDB session store
5. Backend returns token and user data to app
6. App saves token and user data to SharedPreferences
7. User is redirected to home page

### On App Restart:
1. App shows splash screen
2. App checks SharedPreferences for stored session
3. If valid session found:
   - Loads user data from storage
   - Automatically navigates to appropriate home page
4. If no session found:
   - Shows login selection page

### On Logout:
1. User clicks logout button
2. App clears data from SharedPreferences
3. App sends logout request to backend (optional)
4. Backend destroys session in MongoDB
5. User is redirected to login page

## Session Security

### Client-Side (Flutter)
- JWT tokens stored in SharedPreferences (encrypted on iOS)
- Session data only accessible to the app
- Cleared immediately on logout

### Server-Side (Node.js)
- Sessions stored in MongoDB (persistent across restarts)
- Session cookies are httpOnly (prevents XSS)
- Secure cookies in production (HTTPS only)
- Sessions expire after 30 days of inactivity
- CSRF protection via sameSite: 'lax'

## Testing Session Persistence

### For Mobile/Desktop:
1. Login to the app
2. Close the app completely (swipe away/force quit)
3. Reopen the app
4. ✅ Should automatically login and show home page

### For Web:
1. Login to the web app
2. Refresh the page or close and reopen the browser tab
3. ✅ Should automatically login and show home page

### Test Logout:
1. Login to the app
2. Navigate to Profile/Settings
3. Click "Logout"
4. ✅ Should return to login page
5. Close and reopen app
6. ✅ Should show login page (not auto-login)

## Environment Variables

Add to `backend/.env`:
```env
SESSION_SECRET=your-secret-key-here-change-in-production
MONGO_URI=mongodb://localhost:27017/cart_link
NODE_ENV=development
```

## Benefits

1. **Better User Experience**: Users don't need to login every time they open the app
2. **Cross-Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux
3. **Secure**: Uses industry-standard practices for session management
4. **Persistent**: Sessions survive app restarts and even phone reboots
5. **Server-Side Tracking**: Backend can track active sessions and user activity
6. **Easy Logout**: Users can logout from any device, clearing sessions immediately

## Future Enhancements

Potential improvements for production:
1. Add token refresh mechanism for expired tokens
2. Implement "Remember Me" option for extended sessions
3. Add multi-device session management (view/revoke active sessions)
4. Implement biometric authentication for mobile
5. Add session activity logging for security auditing
6. Implement automatic logout after period of inactivity
7. Add push notifications for suspicious login attempts

## Troubleshooting

### Sessions not persisting on Flutter Web:
- Check browser settings - ensure cookies are enabled
- Check if SharedPreferences is working in web context
- Verify CORS settings include credentials: true

### Sessions not persisting on Mobile:
- Ensure app has storage permissions
- Check if SharedPreferences is properly initialized
- Verify data is being saved (check with debug prints)

### Backend sessions not working:
- Verify MongoDB is running and accessible
- Check MONGO_URI environment variable
- Ensure express-session and connect-mongo are installed
- Check browser cookies are being set (inspect Network tab)

## Support

For issues or questions about session management, please check:
1. Browser/device console logs for errors
2. Backend server logs for session creation/destruction
3. MongoDB for stored sessions (sessions collection)
