# Cloudinary Integration Guide

## Setup Instructions

### 1. Backend Setup

#### Install Cloudinary Package
```bash
cd backend
npm install cloudinary
```

#### Update `.env` File
Add these lines to `backend/.env`:
```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

#### Get Cloudinary Credentials
1. Go to https://cloudinary.com/
2. Sign up for a free account
3. Go to Dashboard → Settings → API Keys
4. Copy your Cloud Name, API Key, and API Secret

### 2. Files Created/Modified

**Backend:**
- `backend/src/config/cloudinary.js` - Cloudinary configuration
- `backend/src/controllers/uploadController.js` - Upload/delete endpoints
- `backend/src/routes/uploadRoutes.js` - Upload routes
- `backend/src/app.js` - Added upload routes registration

**Frontend:**
- `lib/services/upload_service.dart` - Upload service for Cloudinary
- `lib/Customer/search_page.dart` - Removed base64 image handling

### 3. Database Schema

Products are stored with image URLs instead of base64:
```javascript
{
  name: "Product Name",
  price: 100,
  images: [
    "https://res.cloudinary.com/your_cloud/image/upload/v123/path/image.jpg"
  ],
  // ... other fields
}
```

### 4. API Endpoints

**Upload Image:**
```
POST /api/upload/upload
Body: { "image": "data:image/jpeg;base64,..." }
Response: { "success": true, "url": "...", "public_id": "..." }
```

**Delete Image:**
```
POST /api/upload/delete
Body: { "public_id": "folder/image_id" }
Response: { "success": true }
```

### 5. Usage in Flutter

#### Upload Image
```dart
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'services/upload_service.dart';

// Pick and upload image
Future<String?> pickAndUploadImage() async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    final bytes = await File(pickedFile.path).readAsBytes();
    final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    
    // Upload to Cloudinary
    final result = await UploadService.uploadImage(base64Image);
    
    if (result['success'] == true) {
      return result['url']; // This is the Cloudinary URL
    }
  }
  return null;
}
```

#### Display Image
```dart
Widget _buildProductImage(String imageUrl) {
  if (imageUrl.isEmpty) {
    return Icon(Icons.image_not_supported);
  }
  
  return Image.network(
    imageUrl,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
  );
}
```

### 6. Benefits

✅ **Free Tier**: 25 GB storage, 25 GB bandwidth/month
✅ **No Base64 Overhead**: Smaller database, faster queries
✅ **CDN Delivery**: Fast global image delivery
✅ **Auto-Optimization**: Images automatically optimized for web/mobile
✅ **Transformations**: Resize, crop, format conversion on-the-fly
✅ **Responsive**: Serve different sizes for different devices

### 7. Free Plan Limits

- 25 GB storage
- 25 GB bandwidth/month
- Automatic format optimization
- Basic transformations

Upgrade to paid plans for higher limits.

### 8. Image URL Format

Cloudinary URLs follow this pattern:
```
https://res.cloudinary.com/{CLOUD_NAME}/image/upload/v{VERSION}/{PUBLIC_ID}.{FORMAT}
```

Example:
```
https://res.cloudinary.com/demo/image/upload/v1234567890/cart_link/products/sample.jpg
```
