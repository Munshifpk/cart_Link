# Price Comparison Feature - Quick API Reference

## 📡 API Endpoints

### 1. GET /api/compare - Fetch Comparison List
**Purpose**: Retrieve all products in customer's comparison list

**Request**:
```
GET /api/compare?customerId=customer_123
```

**Response (Success - 200)**:
```json
{
  "items": [
    {
      "productId": "prod_001",
      "shopId": "shop_001",
      "name": "Samsung Galaxy S21",
      "shopName": "TechStore",
      "price": 44999,
      "mrp": 49999,
      "discount": 10,
      "stock": 15,
      "inStock": true
    },
    {
      "productId": "prod_002",
      "shopId": "shop_002",
      "name": "Samsung Galaxy S21",
      "shopName": "ElectroHub",
      "price": 45999,
      "mrp": 49999,
      "discount": 8,
      "stock": 5,
      "inStock": true
    }
  ]
}
```

**Response (Error - 400)**:
```json
{
  "error": "customerId required"
}
```

---

### 2. POST /api/compare - Add Product to Comparison
**Purpose**: Add a product to customer's comparison list (max 3)

**Request**:
```
POST /api/compare
Content-Type: application/json

{
  "customerId": "customer_123",
  "productId": "prod_003",
  "shopId": "shop_003"
}
```

**Response (Success - 201)**:
```json
{
  "success": true,
  "message": "Product added to comparison",
  "compareListLength": 2
}
```

**Response (Error - Max Limit - 400)**:
```json
{
  "error": "Maximum 3 products can be compared"
}
```

**Response (Error - Duplicate - 400)**:
```json
{
  "error": "Product already in comparison"
}
```

**Response (Error - Product Not Found - 404)**:
```json
{
  "error": "Product not found"
}
```

**Response (Error - Missing Fields - 400)**:
```json
{
  "error": "customerId, productId, and shopId required"
}
```

---

### 3. DELETE /api/compare/:productId - Remove from Comparison
**Purpose**: Remove a product from customer's comparison list

**Request**:
```
DELETE /api/compare/prod_002?customerId=customer_123&shopId=shop_002
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "Product removed from comparison",
  "compareListLength": 1
}
```

**Response (Error - 400)**:
```json
{
  "error": "customerId and shopId required"
}
```

**Response (Error - Not Found - 404)**:
```json
{
  "error": "Comparison list not found"
}
```

---

## 🔄 Complete Data Structure

### Comparison List Document (Database)
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439011"),
  customerId: "cust_123",
  items: [
    {
      productId: "prod_001",
      shopId: "shop_001",
      name: "Samsung Galaxy S21",
      shopName: "TechStore",
      price: 44999,
      offerPrice: 44999,
      mrp: 49999,
      discount: 10,
      stock: 15,
      inStock: true,
      addedAt: ISODate("2026-01-10T10:30:00Z")
    },
    {
      productId: "prod_002",
      shopId: "shop_002",
      name: "Samsung Galaxy S21",
      shopName: "ElectroHub",
      price: 45999,
      offerPrice: 45999,
      mrp: 49999,
      discount: 8,
      stock: 5,
      inStock: true,
      addedAt: ISODate("2026-01-10T10:35:00Z")
    }
  ],
  createdAt: ISODate("2026-01-10T10:25:00Z"),
  updatedAt: ISODate("2026-01-10T10:35:00Z")
}
```

---

## 🧪 Test Cases

### Test 1: Add First Product
```
POST /api/compare
{
  "customerId": "test_user_1",
  "productId": "prod_a",
  "shopId": "shop_1"
}

✓ Expected: 201, compareListLength: 1
```

### Test 2: Add Duplicate Product
```
POST /api/compare
{
  "customerId": "test_user_1",
  "productId": "prod_a",
  "shopId": "shop_1"
}

✓ Expected: 400, error: "Product already in comparison"
```

### Test 3: Add Fourth Product
```
POST /api/compare
{
  "customerId": "test_user_1",
  "productId": "prod_d",
  "shopId": "shop_4"
}

✓ Expected: 400, error: "Maximum 3 products can be compared"
```

### Test 4: Get Comparison List
```
GET /api/compare?customerId=test_user_1

✓ Expected: 200, items array with 3 products
```

### Test 5: Remove Product
```
DELETE /api/compare/prod_a?customerId=test_user_1&shopId=shop_1

✓ Expected: 200, compareListLength: 2
```

### Test 6: Cross-Customer Isolation
```
User A: compareList = [prod_a, prod_b]
User B: compareList = [prod_c, prod_d]

GET /api/compare?customerId=user_a → Should return user_a's list
GET /api/compare?customerId=user_b → Should return user_b's list

✓ Expected: Each user sees only their comparison list
```

---

## 💡 Implementation Notes

### Required Database Indexes
```javascript
db.compares.createIndex({ customerId: 1 })
db.compares.createIndex({ customerId: 1, "items.productId": 1, "items.shopId": 1 })
```

### Validation Rules to Implement
1. **Max Limit**: Enforce max 3 items in array before saving
2. **Duplicates**: Check if (productId, shopId) combination exists
3. **Product Existence**: Verify product exists before adding
4. **Customer ID**: Required in all requests
5. **Shop ID**: Required in all requests

### Edge Cases to Handle
1. Empty comparison list (no items array) → Return empty array
2. Product deleted → Should handle gracefully
3. Shop closed → Should handle gracefully
4. Concurrent requests → Last write wins
5. Large dataset → Index customerId for performance

---

## 🚀 Implementation Checklist

### Mongoose Model
- [ ] Create Compare schema with customerId, items array, timestamps
- [ ] Add validation to limit items to 3
- [ ] Create indexes for performance

### Route Handlers
- [ ] GET endpoint with customerId validation
- [ ] POST endpoint with max limit check
- [ ] POST endpoint with duplicate detection
- [ ] DELETE endpoint with proper cleanup
- [ ] Error handling for all cases

### Error Handling
- [ ] Return 400 for validation errors
- [ ] Return 404 for not found
- [ ] Return 201 for successful create
- [ ] Return 200 for successful update/delete
- [ ] Include error message in response

### Testing
- [ ] Test all CRUD operations
- [ ] Test max limit enforcement
- [ ] Test duplicate prevention
- [ ] Test cross-user isolation
- [ ] Test concurrent requests

---

## 📋 HTTP Status Codes Used

| Code | Meaning | Example |
|------|---------|---------|
| 200 | OK / Success | DELETE, GET successful |
| 201 | Created | POST successful add |
| 400 | Bad Request | Missing fields, max limit exceeded |
| 404 | Not Found | Product not found, list not found |
| 500 | Server Error | Database error, etc |

---

## 🔐 Security Considerations

1. **Always validate customerId**: Ensure user owns the comparison list
2. **Authenticate requests**: Use JWT or session tokens
3. **Rate limiting**: Prevent abuse (add/remove spam)
4. **Input validation**: Sanitize productId and shopId
5. **CORS**: Configure for frontend domain only

---

## ⚡ Performance Tips

1. **Use indexes on customerId**
2. **Limit items array to 3** (prevents bloating)
3. **Use findOneAndUpdate** for atomic operations
4. **Cache comparison list on frontend** (reduces API calls)
5. **Don't fetch full product details** (store only necessary fields)

---

## 🎯 Frontend Integration Points

The Flutter app expects these responses:
- GET returns: `{ items: [...] }`
- POST returns: `{ success: true, message: "...", compareListLength: N }`
- DELETE returns: `{ success: true, message: "...", compareListLength: N }`

All with proper HTTP status codes.
