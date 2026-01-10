# Price Comparison Feature - Visual Guide

## 📍 Feature Locations

### 1. App Bar (Top of Product Page)
```
┌─────────────────────────────────────────────────┐
│  < Product Name          [⚖️] [🛒]              │  ← App Bar Actions
│                          2   5                   │  ← Badge counts
└─────────────────────────────────────────────────┘

⚖️  = Compare Icon (green badge shows count)
🛒  = Shopping Cart Icon (coral badge shows count)
```

### 2. "Add to Compare" Button (Below Buy Now)

#### Before Adding to Compare:
```
┌─────────────────────────┬─────────────────────────┐
│  Add to Cart (Blue)     │  Buy Now (Green)        │
└─────────────────────────┴─────────────────────────┘
┌─────────────────────────────────────────────────┐
│  [⚖️] Add to Compare (Blue, Full Width)         │
└─────────────────────────────────────────────────┘
```

#### After Adding to Compare:
```
┌─────────────────────────┬─────────────────────────┐
│  Add to Cart (Blue)     │  Buy Now (Green)        │
└─────────────────────────┴─────────────────────────┘
┌─────────────────────────────────────────────────┐
│  [✓] Remove from Compare (Orange, Full Width)   │
└─────────────────────────────────────────────────┘
```

### 3. Comparison Modal (Dialog/Popup)

```
╔═══════════════════════════════════════════════════════════╗
║  Compare Products                                    [✕]  ║
║─────────────────────────────────────────────────────────── ║
║                                                           ║
║  Product  │ Shop    │ Price  │ MRP  │ Discount │ Stock │Rm║
║───────────┼─────────┼────────┼──────┼──────────┼───────┼──║
║ Product A │ Shop 1  │ ₹399   │ ₹599 │  -33%    │ Stock │🗑 ║
║ Product B │ Shop 2  │ ₹449   │ ₹599 │  -25%    │ Stock │🗑 ║
║ Product C │ Shop 3  │ ₹499   │ ₹599 │  -17%    │ Out   │🗑 ║
║                                                           ║
║                    [Close Comparison]                    ║
╚═══════════════════════════════════════════════════════════╝
```

## 🎯 User Flow

### Scenario 1: Adding Products to Compare

```
User Views Product Page
       ↓
[Click "Add to Compare"]
       ↓
✓ Button changes to "Remove from Compare" (Orange)
✓ Compare badge appears in app bar showing "1"
✓ SnackBar confirms: "Added to compare"
       ↓
[Click "Add to Compare" on second product]
       ↓
✓ Compare badge updates to "2"
       ↓
[Click Compare Icon in App Bar]
       ↓
╔════════════════════════════════════╗
║  Comparison Modal Opens            ║
║  Shows: Product A vs Product B     ║
║  With: Price, MRP, Discount, Stock ║
╚════════════════════════════════════╝
```

### Scenario 2: Reaching Maximum Limit

```
User has 3 products in comparison
       ↓
[Try to add 4th product]
       ↓
✗ SnackBar Error: "Maximum 3 products can be compared"
✗ Product NOT added
✓ Button remains "Add to Compare"
```

### Scenario 3: Removing from Comparison

```
User in Comparison Modal
       ↓
[Click 🗑 button next to a product]
       ↓
✓ Product removed
✓ Modal closes then reopens (auto-refresh)
✓ Only 2 products now visible
✓ Badge in app bar updates to "2"
```

## 🎨 Color Scheme

| Element | Color | Hex Code |
|---------|-------|----------|
| "Add to Compare" Button | Primary Blue | #1F6FEB |
| "Remove from Compare" Button | Orange | #FF9500 |
| Compare Badge | Success Green | #23B26D |
| Cart Badge | Coral/Accent | #FF6B5A |
| Price (in table) | Success Green | #23B26D |
| Out of Stock | Red | #FF0000 |
| MRP (strikethrough) | Gray | #808080 |

## 📊 Data Table Columns

| Column | Format | Example |
|--------|--------|---------|
| Product | Text (ellipsis if long) | "Samsung Galaxy..." |
| Shop | Text | "TechStore" |
| Price | Currency | "₹399" |
| MRP | Currency + strikethrough | "~~₹599~~" |
| Discount | Percentage or "No" | "-33%" or "No" |
| Stock | "In Stock" or "Out of Stock" | "In Stock" |
| Action | Delete Icon | 🗑️ |

## 🔔 Notifications & Feedback

### Success Messages
- ✓ "Added to compare" (1 second)
- ✓ "Removed from compare" (1 second)

### Error Messages
- ✗ "Maximum 3 products can be compared at once"
- ✗ "Please log in to use compare feature"
- ✗ "No products to compare" (when clicking empty compare icon)

## 📱 Responsive Behavior

### Mobile (< 600px)
- Full-width buttons
- Table scrolls horizontally in modal
- Smaller font sizes
- Touch-friendly (48px minimum height)

### Tablet (600px - 1000px)
- Side-by-side buttons (Add to Cart & Buy Now)
- "Add to Compare" below
- Table fits with horizontal scroll
- Comfortable spacing

### Desktop (> 1000px)
- All buttons visible and well-spaced
- Table fully visible or minimal scroll
- Larger fonts
- More whitespace

## 💾 Data Persistence

### When Comparison List is Saved
1. ✓ When product is added via "Add to Compare"
2. ✓ When product is removed via modal
3. ✓ When product is removed via page button

### What Gets Stored in Database
```javascript
{
  customerId: "user_123",
  items: [
    {
      productId: "prod_456",
      shopId: "shop_789",
      name: "Product Name",
      shopName: "Shop Name",
      price: 399.99,
      mrp: 599.99,
      discount: 33,
      stock: 10,
      inStock: true
    }
    // ... up to 3 items
  ],
  createdAt: "2026-01-10T...",
  updatedAt: "2026-01-10T..."
}
```

## ⚡ Performance Optimizations

1. **Lazy Loading**: Comparison list fetched on page init only
2. **Caching**: Compare list cached in `_compareList` variable
3. **Minimal Re-renders**: Only updates when list changes
4. **Efficient Checks**: Uses `.any()` to check product status
5. **Automatic Refresh**: Modal auto-closes and reopens after changes

## 🛡️ Validation Rules

| Check | Rule | Result |
|-------|------|--------|
| Max Products | 3 items max | Error if exceeding |
| Duplicates | Same (product + shop) | Skip if already exists |
| Login | Must be logged in | Error if not authenticated |
| Stock | Out of stock allowed | Button disabled but can compare |
| Product Exists | Valid productId required | Error if not found |

## 🔗 API Integration Points

### Frontend Makes These Calls:
1. `GET /api/compare?customerId=X` - Fetch list on page load
2. `POST /api/compare` - Add product (body: customerId, productId, shopId)
3. `DELETE /api/compare/:productId?customerId=X&shopId=Y` - Remove product

### Frontend Expects These Responses:
- Status 200/201 for success
- Status 400 for validation errors
- Status 404 for not found
- JSON with error message on failure

## ✅ Feature Checklist for Implementation

- [ ] Backend implements GET `/api/compare` endpoint
- [ ] Backend implements POST `/api/compare` endpoint  
- [ ] Backend implements DELETE `/api/compare/:productId` endpoint
- [ ] Database has Compare collection/model
- [ ] Max 3 products validation on backend
- [ ] Duplicate check on backend
- [ ] Test adding 1, 2, 3 products
- [ ] Test error when adding 4th product
- [ ] Test remove via modal
- [ ] Test remove via button
- [ ] Test page refresh (persistence)
- [ ] Test with multiple users
- [ ] Test with out-of-stock products
