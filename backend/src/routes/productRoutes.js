const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.post('/', productController.createProduct);
router.get('/', productController.getAllProducts);
router.get('/with-images', productController.getAllProductsWithImages);

router.get('/:id/images', productController.getProductImages);
router.delete('/:id', productController.deleteProduct);
router.put('/:id', productController.updateProduct);

module.exports = router;

