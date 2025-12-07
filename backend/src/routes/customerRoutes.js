const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

// Public: list all customers
router.get('/', customerController.listAll);

// Follow/Unfollow shop
router.post('/follow-shop', customerController.followShop);

// Get followed shops for a customer
router.get('/:id/following', customerController.getFollowing);

module.exports = router;
