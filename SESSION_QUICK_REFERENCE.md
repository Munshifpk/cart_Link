# Session Management - Quick Start Guide

## For Developers

### To Use Sessions in Your Code

#### Check if User is Logged In (Flutter)
```dart
// Check customer login
bool isLoggedIn = await AuthState.isCustomerLoggedIn();

// Check shop owner login
bool isLoggedIn = await AuthState.isOwnerLoggedIn();

// Get current user type
String? userType = await AuthStorage.getCurrentUserType(); // 'customer', 'shop', or null
```

#### Get Current User Data (Flutter)
```dart
// Get customer data
await AuthState.loadCustomerFromStorage();
Map<String, dynamic>? customer = AuthState.currentCustomer;

// Get shop owner data
await AuthState.loadOwnerFromStorage();
Map<String, dynamic>? owner = AuthState.currentOwner;

// Get just the token
String? token = await AuthStorage.getCustomerToken();
String? token = await AuthStorage.getShopToken();
```

#### Save Session After Login (Flutter)
```dart
// After successful login/registration
await AuthState.setCustomer(customerData, token: jwtToken);
// or
await AuthState.setOwner(shopData, token: jwtToken);
```

#### Logout User (Flutter)
```dart
// Logout customer
await AuthState.logoutCustomer();

// Logout shop owner
await AuthState.logoutOwner();

// Then navigate to login page
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const HomePage()),
  (route) => false,
);
```

### Backend Protected Routes

#### Require Authentication (Node.js)
```javascript
const sessionMiddleware = require('../middleware/sessionMiddleware');

// Require any authenticated user
router.get('/protected', sessionMiddleware.requireAuth, controller.method);

// Require shop owner
router.post('/shop-only', sessionMiddleware.requireShopAuth, controller.method);

// Require customer
router.post('/customer-only', sessionMiddleware.requireCustomerAuth, controller.method);
```

#### Access Session Data in Controller (Node.js)
```javascript
exports.someController = async (req, res) => {
    // Access session data
    const userId = req.session.userId;
    const userType = req.session.userType; // 'shop' or 'customer'
    const shopName = req.session.shopName;
    const customerName = req.session.customerName;
    
    // Use the data
    console.log(`User ${userId} (${userType}) is accessing this endpoint`);
};
```

#### Create Session on Login (Node.js)
```javascript
// After validating credentials
req.session.userId = user._id;
req.session.userType = 'shop'; // or 'customer'
req.session.shopName = user.shopName; // optional

// Session is automatically saved to MongoDB
res.json({ success: true, token, user });
```

#### Destroy Session on Logout (Node.js)
```javascript
req.session.destroy((err) => {
    if (err) {
        return res.status(500).json({ success: false, message: 'Logout failed' });
    }
    res.clearCookie('connect.sid');
    res.json({ success: true, message: 'Logged out' });
});
```

## Testing Checklist

### Manual Testing
- [ ] Login as customer → Close app → Reopen → Should stay logged in
- [ ] Login as shop → Close app → Reopen → Should stay logged in
- [ ] Login → Logout → Close app → Reopen → Should show login page
- [ ] Web: Login → Refresh page → Should stay logged in
- [ ] Web: Login → Close browser → Reopen → Should stay logged in (if within 30 days)

### Backend Testing
- [ ] Check MongoDB `sessions` collection for stored sessions
- [ ] Verify session expires after 30 days
- [ ] Test protected endpoints require authentication
- [ ] Test logout clears session from database

## Common Issues & Solutions

### Issue: Sessions not persisting on Flutter
**Solution:** 
1. Ensure `shared_preferences` is in pubspec.yaml
2. Check if `await` is used when calling AuthState methods
3. Verify SharedPreferences is initialized

### Issue: Backend session not created
**Solution:**
1. Verify MongoDB is running
2. Check `MONGO_URI` in .env file
3. Ensure `express-session` middleware is before routes
4. Check if cookies are enabled in browser

### Issue: Auto-login not working
**Solution:**
1. Check `main.dart` has SplashScreen as initial route
2. Verify session data is being loaded in SplashScreen
3. Check console logs for errors during session check

### Issue: Token expired errors
**Solution:**
1. Current implementation uses JWT with 7-day expiry
2. SharedPreferences session persists until logout
3. Consider implementing token refresh mechanism

## Best Practices

1. **Always use await** when calling AuthState/AuthStorage methods
2. **Check mounted** before navigation after async operations
3. **Clear sessions on logout** to prevent stale data
4. **Test on multiple platforms** (Android, iOS, Web)
5. **Handle errors gracefully** when loading sessions
6. **Don't store sensitive data** beyond what's necessary
7. **Use HTTPS in production** for secure cookies

## API Endpoints

### Shop Authentication
```
POST /api/auth/register          - Register shop owner
POST /api/auth/verify-credentials - Login shop owner
POST /api/auth/logout            - Logout shop owner
GET  /api/auth/session           - Check shop session
```

### Customer Authentication
```
POST /api/customersAuth/register          - Register customer
POST /api/customersAuth/verify-credentials - Login customer
POST /api/customersAuth/logout            - Logout customer
GET  /api/customersAuth/session           - Check customer session
```

## Session Data Structure

### Stored in SharedPreferences (Flutter)
```dart
{
  'customer_token': 'JWT_TOKEN_HERE',
  'customer_data': '{
    "_id": "...",
    "customerName": "John Doe",
    "mobile": 1234567890,
    "email": "john@example.com",
    ...
  }'
}
```

### Stored in MongoDB (Backend)
```javascript
{
  _id: 'session_id',
  expires: ISODate("2024-01-30T..."),
  session: {
    cookie: { ... },
    userId: 'user_object_id',
    userType: 'customer', // or 'shop'
    customerName: 'John Doe', // or shopName
  }
}
```

## Need Help?

1. Check [SESSION_MANAGEMENT.md](./SESSION_MANAGEMENT.md) for detailed documentation
2. Review code in `lib/services/auth_storage.dart` and `lib/services/auth_state.dart`
3. Check backend middleware in `backend/src/middleware/sessionMiddleware.js`
4. Look at login implementations in `lib/Customer/login.dart` and `lib/Shops/login-Shops.dart`
