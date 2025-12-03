const mongoose = require('mongoose');
const Cart = require('../models/Cart');

exports.addToCart = async (req, res) => {
  try {
    // Support two payload shapes:
    // 1) Single product: { productId, quantity, shopId, customerId }
    // 2) Multiple items: { items: [{ productId, quantity }, ...], shopId, customerId }
    // Strategy: maintain ONE cart per customer+shop and merge items into it.

    const { productId, customerId, shopId, quantity, items: incomingItems } = req.body;

    if (!customerId || !shopId) {
      return res.status(400).json({ success: false, message: 'customerId and shopId are required' });
    }

    // Prepare items to add
    let itemsToAdd = [];
    if (Array.isArray(incomingItems) && incomingItems.length > 0) {
      itemsToAdd = incomingItems.map(it => ({
        productId: it.productId,
        quantity: Number(it.quantity || 1),
      }));
    } else if (productId) {
      // Single product case
      itemsToAdd = [{ productId: productId, quantity: Number(quantity || 1) }];
    } else {
      return res.status(400).json({ success: false, message: 'productId or items array required' });
    }

    // Find existing cart for this customer + shop
    let cart = await Cart.findOne({ customerId, shopId });

    if (cart) {
      // Merge items: sum quantities for duplicate products
      const productMap = new Map();
      
      // Add existing items to map
      if (Array.isArray(cart.items) && cart.items.length > 0) {
        cart.items.forEach(item => {
          const pid = item.productId?.toString() || item.productId;
          productMap.set(pid, (productMap.get(pid) || 0) + item.quantity);
        });
      }

      // Add incoming items to map (sums quantities)
      itemsToAdd.forEach(item => {
        const pid = item.productId?.toString() || item.productId;
        productMap.set(pid, (productMap.get(pid) || 0) + item.quantity);
      });

      // Rebuild items array from map
      cart.items = Array.from(productMap.entries()).map(([pid, qty]) => ({
        productId: pid,
        quantity: qty,
      }));

      // Update timestamp
      cart.updatedAt = new Date();
      await cart.save();

      return res.status(200).json({ success: true, message: 'Items merged into cart', data: cart });
    } else {
      // Create new cart
      const newCart = new Cart({
        customerId,
        shopId,
        items: itemsToAdd,
      });
      await newCart.save();
      return res.status(201).json({ success: true, message: 'Cart created', data: newCart });
    }
  } catch (err) {
    console.error('addToCart error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getByCustomer = async (req, res) => {
  try {
    const { customerId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(customerId)) {
      return res.status(400).json({ success: false, message: 'Invalid customerId' });
    }
    // Populate both legacy productId and items.productId
    const items = await Cart.find({ customerId }).populate('productId').populate('items.productId').lean();
    return res.json({ success: true, data: items });
  } catch (err) {
    console.error('getByCustomer error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};
