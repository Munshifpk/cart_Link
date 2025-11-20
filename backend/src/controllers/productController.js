const mongoose = require('mongoose');
const Product = require('../models/Product');

exports.createProduct = async (req, res) => {
    try {
        const { name, description, price, stock, sku, category, isActive, isFeatured, images, ownerId } = req.body;

        if (!name || !description || price == null || stock == null) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const product = new Product({
            name,
            description,
            price: Number(price),
            stock: Number(stock),
            sku,
            category,
            ownerId: ownerId || null,
            isActive: !!isActive,
            isFeatured: !!isFeatured,
            images: Array.isArray(images) ? images : [],
        });

        await product.save();
        return res.status(201).json({ success: true, message: 'Product created', data: product });
    } catch (err) {
        console.error('createProduct error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getAllProducts = async (req, res) => {
    try {
        const { ownerId } = req.query || {};

        let filter = {};
        if (ownerId) {
            // validate ownerId
            if (!mongoose.Types.ObjectId.isValid(ownerId)) {
                return res.status(400).json({ success: false, message: 'Invalid ownerId' });
            }
            filter.ownerId = ownerId;
        }

        const products = await Product.find(filter).lean();
        return res.json({ success: true, data: products });
    } catch (err) {
        console.error('getAllProducts error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};
