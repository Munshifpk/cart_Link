const express = require('express');
const router = express.Router();
const shopController = require('../controllers/shopController');

// Read-only routes: only GETs retained
router.get('/', shopController.getAllShops);
router.get('/:id', shopController.getShopById);
module.exports = router;