const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');

router.post('/', cartController.addToCart);
router.get('/customer/:customerId', cartController.getByCustomer);

module.exports = router;
