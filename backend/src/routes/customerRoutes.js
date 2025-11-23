const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

// Public: list all customers
router.get('/', customerController.listAll);

module.exports = router;
