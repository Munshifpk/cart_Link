# Product Cancellation Feature - Complete Setup

## Overview
This document outlines the complete product cancellation feature implementation that allows customers to cancel individual products from their orders with quantity-wise selection.

## Changes Made

### Backend Changes

#### 1. Order Model (`backend/src/models/Order.js`)
- Added `cancelledProducts` array field to track cancelled products
- Stores: productId, productName, quantity, price, cancelledAt, customerId
- Maintains history of all product cancellations for each order

#### 2. Order Routes (`backend/src/routes/orderRoutes.js`)
- Added new POST route: `/api/orders/:orderId/cancel-product`
- Maps to `orderController.cancelProduct` method

#### 3. Order Controller (`backend/src/controllers/orderController.js`)
- Added new `cancelProduct` method that:
  - Validates order and product existence
  - Validates cancellation quantity
  - Removes product from order (if all quantity cancelled) OR reduces quantity
  - Maintains cancellation history
  - Recalculates order total
  - Returns updated order with all populated fields

### Frontend Changes

#### 1. Order Detail Page (`lib/Customer/order_detail_page.dart`)
- **Cancel Product Dialog**: Shows quantity selector with +/- buttons
- **Quantity Validation**: Prevents cancelling more than available quantity
- **API Integration**: Calls backend endpoint with product details
- **Data Refresh**: Automatically fetches updated order data after cancellation
- **User Feedback**: Shows success/error messages with details

## API Endpoint

### POST `/api/orders/:orderId/cancel-product`

**Request Body:**
```json
{
  "productId": "product_id_here",
  "productName": "Product Name",
  "quantityToCancel": 2,
  "customerId": "customer_id_here",
  "cancelledAt": "2025-12-11T10:30:00.000Z"
}
```

**Success Response (200/201):**
```json
{
  "success": true,
  "message": "Successfully cancelled 2 items from order",
  "data": {
    "_id": "order_id",
    "customerId": { /* customer details */ },
    "shopId": { /* shop details */ },
    "products": [ /* remaining products */ ],
    "cancelledProducts": [
      {
        "productId": "product_id",
        "productName": "Product Name",
        "quantity": 2,
        "price": 500,
        "cancelledAt": "2025-12-11T10:30:00.000Z",
        "customerId": "customer_id"
      }
    ],
    "totalAmount": 1500,
    "orderStatus": "pending",
    "createdAt": "2025-12-10T...",
    "updatedAt": "2025-12-11T10:30:00.000Z"
  }
}
```

**Error Responses:**
- 400: Invalid quantity or product not found
- 404: Order or product not found
- 500: Server error

## Feature Functionality

### User Flow:
1. Customer opens order details page
2. Clicks "Cancel Product" button on any item
3. Dialog shows:
   - Product name
   - Available quantity
   - Quantity selector (with +/- buttons)
   - Confirmation message
4. Customer selects quantity to cancel
5. Clicks "Yes, Cancel" button
6. Request sent to backend
7. Product removed/quantity reduced in database
8. Cancelled product added to cancellation history
9. Order total recalculated
10. UI refreshes to show updated order
11. Success message displayed

### Data Handling:
- **Cancelled Products**: Maintained separately from active products
- **Price Recalculation**: Automatic based on remaining products
- **History**: Complete audit trail of all cancellations
- **Validation**: Server-side validation prevents invalid cancellations

## Testing Checklist

- [ ] Cancel 1 item from multi-quantity product
- [ ] Cancel all items (product should be removed)
- [ ] Verify order total is recalculated
- [ ] Verify cancellation history is saved
- [ ] Test error handling (invalid quantity)
- [ ] Verify UI refreshes with updated data
- [ ] Check database shows correct cancelled products
- [ ] Test with different order statuses

## Notes

- Cancelled products are removed from the active `products` array but kept in `cancelledProducts` for history
- Order status is not automatically changed during product cancellation (remains pending/confirmed)
- Total amount is recalculated based on remaining products only
- Each cancellation is timestamped and linked to customer ID for audit purposes
