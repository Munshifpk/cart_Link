const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Create a new order (checkout)
router.post('/', orderController.createOrder);

// Get orders by customer ID
router.get('/customer/:customerId', orderController.getByCustomer);

// Get order by ID
router.get('/:orderId', orderController.getById);

// Update order status
router.patch('/:orderId/status', orderController.updateStatus);

module.exports = router;
