const Order = require('../models/Order');
const Cart = require('../models/Cart');

// Create a new order from cart items (one customer, one shop)
exports.createOrder = async (req, res) => {
    try {
        const { customerId, shopId, products } = req.body;

        if (!customerId) {
            return res.status(400).json({
                success: false,
                message: 'Customer ID is required',
            });
        }

        if (!shopId) {
            return res.status(400).json({
                success: false,
                message: 'Shop ID is required',
            });
        }

        if (!products || !Array.isArray(products) || products.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'At least one product is required',
            });
        }

        // Validate products and calculate total
        let totalAmount = 0;
        const processedProducts = [];

        for (const product of products) {
            if (!product.productId || !product.quantity || !product.price) {
                return res.status(400).json({
                    success: false,
                    message: 'Each product must have productId, quantity, and price',
                });
            }

            const lineTotal = product.price * product.quantity;
            totalAmount += lineTotal;

            processedProducts.push({
                productId: product.productId,
                quantity: product.quantity,
                price: product.price,
                mrp: product.mrp || product.price,
            });
        }

        // Generate a 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Create the order
        const newOrder = new Order({
            customerId,
            shopId,
            products: processedProducts,
            totalAmount,
            orderStatus: 'pending',
            deliveryOtp: otp,
        });

        const savedOrder = await newOrder.save();

        // Delete cart items for this customer and shop
        await Cart.deleteMany({ customerId, shopId });

        return res.status(201).json({
            success: true,
            message: 'Order created successfully',
            data: savedOrder,
        });
    } catch (error) {
        console.error('Error creating order:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Error creating order',
        });
    }
};

// Get orders by customer ID
exports.getByCustomer = async (req, res) => {
    try {
        const { customerId } = req.params;

        const orders = await Order.find({ customerId })
            .populate('customerId', 'customerName name email mobile phone')
            .populate('shopId', 'shopName name contact phone mobile')
            .populate('products.productId', 'name price mrp')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            data: orders,
        });
    } catch (error) {
        console.error('Error fetching orders:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Error fetching orders',
        });
    }
};

// Get orders by shop ID
exports.getByShop = async (req, res) => {
    try {
        const { shopId } = req.params;

        const orders = await Order.find({ shopId })
            .populate('customerId', 'customerName name email mobile phone')
            .populate('shopId', 'shopName name contact phone mobile')
            .populate('products.productId', 'name price mrp')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            data: orders,
        });
    } catch (error) {
        console.error('Error fetching orders:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Error fetching orders',
        });
    }
};

// Get order by ID
exports.getById = async (req, res) => {
    try {
        const { orderId } = req.params;

        const order = await Order.findById(orderId)
            .populate('customerId', 'customerName name email mobile phone')
            .populate('shopId', 'shopName name contact phone mobile')
            .populate('products.productId', 'name price mrp');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        return res.status(200).json({
            success: true,
            data: order,
        });
    } catch (error) {
        console.error('Error fetching order:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Error fetching order',
        });
    }
};

// Update order status
exports.updateStatus = async (req, res) => {
    try {
        const { orderId } = req.params;
        const { orderStatus } = req.body;

        const validStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
        if (!validStatuses.includes(orderStatus)) {
            return res.status(400).json({
                success: false,
                message: `Invalid status. Allowed values: ${validStatuses.join(', ')}`,
            });
        }

        const updatedOrder = await Order.findByIdAndUpdate(
            orderId,
            { orderStatus, updatedAt: Date.now() },
            { new: true },
        );

        if (!updatedOrder) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Order status updated',
            data: updatedOrder,
        });
    } catch (error) {
        console.error('Error updating order status:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Error updating order status',
        });
    }
};

// Verify OTP and update order status to delivered
exports.verifyOtpAndDeliver = async (req, res) => {
    try {
        const { orderId } = req.params;
        const { otp } = req.body;

        if (!otp) {
            return res.status(400).json({
                success: false,
                message: 'OTP is required',
            });
        }

        const order = await Order.findById(orderId);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Verify OTP
        if (order.deliveryOtp !== otp) {
            return res.status(400).json({
                success: false,
                message: 'Invalid OTP',
            });
        }

        // Update order status to delivered
        order.orderStatus = 'delivered';
        order.updatedAt = Date.now();
        const updatedOrder = await order.save();

        return res.status(200).json({
            success: true,
            message: 'Order marked as delivered',
            data: updatedOrder,
        });
    } catch (error) {
        console.error('Error verifying OTP:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Error verifying OTP',
        });
    }
};

