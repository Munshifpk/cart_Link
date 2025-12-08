const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true },
  mrp: { type: Number },
  stock: { type: Number },
  inStock: { type: Boolean, default: true },
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: false },
  sku: { type: String },
  category: { type: String },
  images: { type: [String], default: [] },
  isActive: { type: Boolean, default: true },
  isFeatured: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
}, { collection: 'products' });

module.exports = mongoose.model('Product', ProductSchema);
