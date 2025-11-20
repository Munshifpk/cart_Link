const mongoose = require('mongoose');

const ShopSchema = new mongoose.Schema({
    shopName: { type: String, required: true },
    ownerName: { type: String, required: true },
    location: { type: String, required: true },
    contact: { type: String, required: true },
    email: { type: String },
    businessType: String,
    address: String,
    isActive: { type: Boolean, default: true },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
}, { collection: 'shops' }); // <-- Map to existing 'shops' collection

module.exports = mongoose.model('Shop', ShopSchema, 'shops'); // <-- Pass collection name here too