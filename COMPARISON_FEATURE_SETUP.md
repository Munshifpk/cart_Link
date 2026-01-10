# Price Comparison Feature - Backend Setup Guide

## Overview
The frontend product purchase page now includes a complete price comparison feature that allows customers to compare up to 3 products side-by-side with detailed pricing information.

## Frontend Implementation (COMPLETED ✅)

### Features Implemented:
1. **"Add to Compare" Button** - Located below "Buy Now" button on product detail page
   - Shows "Add to Compare" when product not in comparison list
   - Shows "Remove from Compare" when product is in comparison list
   - Displays warning if max 3 products limit reached
   - Disabled when product is out of stock

2. **Compare Icon in App Bar** - Balance scale icon in top-right corner
   - Shows count badge with number of products in comparison list
   - Opens comparison modal when tapped
   - Green color for the badge (success color)

3. **Comparison Modal/Popup** - Full-screen dialog with:
   - Side-by-side price comparison table
   - Columns: Product Name, Shop, Price, MRP, Discount %, Stock Status
   - Remove buttons for each product
   - Close comparison button

4. **State Management**:
   - Tracks comparison list in `_compareList` variable
   - Tracks if current product is in comparison with `_isInCompare` boolean
   - Updates automatically when products are added/removed

## Backend Implementation Required

### 1. Database Schema - Create `Compare` Collection/Model

```javascript
// compareModel.js
const compareSchema = {
  customerId: {
    type: String,
    required: true,
    index: true
  },
  items: [{
    productId: {
      type: String,
      required: true
    },
    shopId: {
      type: String,
      required: true
    },
    name: String,
    product: String,
    productName: String,
    shopName: String,
    price: Number,
    offerPrice: Number,
    mrp: Number,
    discount: Number,
    stock: Number,
    inStock: Boolean,
    addedAt: {
      type: Date,
      default: Date.now
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
};
```

### 2. Create API Endpoints

#### GET `/api/compare` - Fetch comparison list
**Query Parameters:**
- `customerId` (required): Customer's ID

**Response:**
```json
{
  "success": true,
  "items": [
    {
      "productId": "prod_123",
      "shopId": "shop_456",
      "name": "Product Name",
      "shopName": "Shop Name",
      "price": 499.99,
      "offerPrice": 399.99,
      "mrp": 599.99,
      "discount": 33,
      "stock": 10,
      "inStock": true
    }
  ]
}
```

#### POST `/api/compare` - Add product to comparison
**Request Body:**
```json
{
  "customerId": "customer_123",
  "productId": "product_456",
  "shopId": "shop_789"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Product added to comparison",
  "compareListLength": 2
}
```

**Validation:**
- Check if customer exists
- Check if product exists with that shop ID
- Validate max 3 items limit
- Prevent duplicates (same product + shop combination)

#### DELETE `/api/compare/:productId` - Remove product from comparison
**Query Parameters:**
- `customerId` (required): Customer's ID
- `shopId` (required): Shop's ID

**Response:**
```json
{
  "success": true,
  "message": "Product removed from comparison",
  "compareListLength": 1
}
```

### 3. Implementation Steps

#### Step 1: Create Compare Model
```javascript
// models/Compare.js
const mongoose = require('mongoose');

const compareSchema = new mongoose.Schema({
  customerId: {
    type: String,
    required: true,
    index: true
  },
  items: [{
    productId: String,
    shopId: String,
    name: String,
    shopName: String,
    price: Number,
    offerPrice: Number,
    mrp: Number,
    discount: Number,
    stock: Number,
    inStock: Boolean,
    addedAt: { type: Date, default: Date.now }
  }],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Compare', compareSchema);
```

#### Step 2: Create Compare Routes
```javascript
// routes/compareRoutes.js
const express = require('express');
const router = express.Router();
const Compare = require('../models/Compare');
const Product = require('../models/Product'); // Adjust based on your setup

// Get comparison list
router.get('/', async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) {
      return res.status(400).json({ error: 'customerId required' });
    }

    let compareList = await Compare.findOne({ customerId });
    if (!compareList) {
      return res.json({ items: [] });
    }

    res.json({ items: compareList.items });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add product to comparison
router.post('/', async (req, res) => {
  try {
    const { customerId, productId, shopId } = req.body;
    
    if (!customerId || !productId || !shopId) {
      return res.status(400).json({ 
        error: 'customerId, productId, and shopId required' 
      });
    }

    let compareList = await Compare.findOne({ customerId });
    
    if (!compareList) {
      compareList = new Compare({ customerId, items: [] });
    }

    // Check max limit (3 products)
    if (compareList.items.length >= 3) {
      return res.status(400).json({ 
        error: 'Maximum 3 products can be compared' 
      });
    }

    // Check if product already in list
    const exists = compareList.items.some(
      item => item.productId == productId && item.shopId == shopId
    );
    
    if (exists) {
      return res.status(400).json({ 
        error: 'Product already in comparison' 
      });
    }

    // Fetch product details
    const product = await Product.findOne({ 
      _id: productId, 
      $or: [{ shopId }, { ownerId: shopId }] 
    });
    
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    // Add to comparison list
    compareList.items.push({
      productId,
      shopId,
      name: product.name || product.product,
      shopName: product.shopName || 'Shop',
      price: product.offerPrice || product.price,
      offerPrice: product.offerPrice || product.price,
      mrp: product.mrp,
      discount: product.discount || 0,
      stock: product.stock || 0,
      inStock: product.inStock !== false
    });

    await compareList.save();
    res.status(201).json({ 
      success: true,
      message: 'Product added to comparison',
      compareListLength: compareList.items.length
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Remove product from comparison
router.delete('/:productId', async (req, res) => {
  try {
    const { customerId, shopId } = req.query;
    const { productId } = req.params;

    if (!customerId || !shopId) {
      return res.status(400).json({ 
        error: 'customerId and shopId required' 
      });
    }

    const compareList = await Compare.findOne({ customerId });
    if (!compareList) {
      return res.status(404).json({ error: 'Comparison list not found' });
    }

    compareList.items = compareList.items.filter(
      item => !(item.productId == productId && item.shopId == shopId)
    );

    await compareList.save();
    res.json({ 
      success: true,
      message: 'Product removed from comparison',
      compareListLength: compareList.items.length
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

#### Step 3: Register Routes in Main App
```javascript
// app.js or server.js
const compareRoutes = require('./routes/compareRoutes');

app.use('/api/compare', compareRoutes);
```

### 4. API Endpoints Summary

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| GET | `/api/compare?customerId=...` | Fetch comparison list | Optional |
| POST | `/api/compare` | Add product to compare | Optional |
| DELETE | `/api/compare/:productId?customerId=...&shopId=...` | Remove from compare | Optional |

## Frontend Configuration

The frontend is already configured with:
- API constant: `kApiCompare = '/api/compare'` in `constant.dart`
- All necessary state management and UI components
- Auto-refresh on add/remove operations
- Max 3 products validation

## Testing Checklist

- [ ] Add first product to compare → Show "Remove from Compare" button
- [ ] Add second product → Compare icon shows badge with "2"
- [ ] Add third product → Compare icon shows badge with "3"
- [ ] Try to add 4th product → Should show error "Maximum 3 products"
- [ ] Click compare icon → Modal opens with 3 products in table format
- [ ] Remove product from modal → Updates immediately
- [ ] Remove product via button on page → Updates modal
- [ ] Refresh page → Compare list persists in database
- [ ] Multiple customers → Each has separate compare list
- [ ] Out of stock product → "Add to Compare" button disabled

## Notes

- Compare list is persisted in database per customer
- Maximum 3 products can be compared at once
- Products are identified by both productId and shopId combination
- Comparison modal shows: Product Name, Shop, Price, MRP, Discount %, Stock Status
- All API calls include customerId for security
