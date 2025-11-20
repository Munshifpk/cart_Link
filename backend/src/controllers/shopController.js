const mongoose = require('mongoose');
const Shop = require('../models/Shop'); // adjust path if your model is elsewhere

exports.getAllShops = async (req, res) => {
    try {
        const shops = await Shop.find().lean();
        return res.json({ success: true, data: shops });
    } catch (err) {
        console.error('getAllShops error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.getShopById = async (req, res) => {
    try {
        const shop = await Shop.findById(req.params.id).lean();
        if (!shop) return res.status(404).json({ success: false, message: 'Not found' });
        return res.json({ success: true, data: shop });
    } catch (err) {
        console.error('getShopById error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
};

