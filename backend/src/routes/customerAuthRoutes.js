const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

// Auth endpoints
router.post('/register', customerController.register);
router.post('/verify-credentials', customerController.verifyCredentials);
router.get('/check-mobile/:mobile', customerController.checkMobileExists);
router.get('/check-email/:email', customerController.checkEmailExists);

module.exports = router;