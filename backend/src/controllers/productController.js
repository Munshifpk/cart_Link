const mongoose = require('mongoose');
const Product = require('../models/Product');

exports.createProduct = async (req, res) => {
    try {
        const { name, description, price, mrp, stock, sku, category, isActive, isFeatured, images, ownerId } = req.body;

        if (!name || !description || price == null || stock == null) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const product = new Product({
            name,
            description,
            price: Number(price),
            mrp: mrp != null ? Number(mrp) : undefined,
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

        // Exclude images field to reduce payload size (images bloat response with base64)
        const products = await Product.find(filter).select('-images').lean();
        return res.json({ success: true, data: products });
    } catch (err) {
        console.error('getAllProducts error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getAllProductsWithImages = async (req, res) => {
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

        // Include images (for customer pages that need them)
        const products = await Product.find(filter).lean();
        return res.json({ success: true, data: products });
    } catch (err) {
        console.error('getAllProductsWithImages error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ success: false, message: 'Invalid product ID' });
        }

        const result = await Product.findByIdAndDelete(id);
        if (!result) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        return res.json({ success: true, message: 'Product deleted successfully' });
    } catch (err) {
        console.error('deleteProduct error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ success: false, message: 'Invalid product ID' });
        }

        const { name, description, price, mrp, stock, sku, category, isActive, isFeatured, images } = req.body;

        const update = {};
        if (name !== undefined) update.name = name;
        if (description !== undefined) update.description = description;
        if (price !== undefined) update.price = Number(price);
        if (mrp !== undefined) update.mrp = Number(mrp);
        if (stock !== undefined) update.stock = Number(stock);
        if (sku !== undefined) update.sku = sku;
        if (category !== undefined) update.category = category;
        if (isActive !== undefined) update.isActive = !!isActive;
        if (isFeatured !== undefined) update.isFeatured = !!isFeatured;
        if (images !== undefined && Array.isArray(images)) update.images = images;

        const updated = await Product.findByIdAndUpdate(id, update, { new: true });
        if (!updated) return res.status(404).json({ success: false, message: 'Product not found' });

        return res.json({ success: true, message: 'Product updated', data: updated });
    } catch (err) {
        console.error('updateProduct error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getProductImages = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ success: false, message: 'Invalid product ID' });
        }

        const product = await Product.findById(id).select('images').lean();
        if (!product) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        return res.json({ success: true, data: product.images || [] });
    } catch (err) {
        console.error('getProductImages error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};
