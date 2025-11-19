const jwt = require('jsonwebtoken');
const Customer = require('../models/Customer');
require('dotenv').config();

const signToken = (customer) => {
    return jwt.sign({ customerId: customer._id }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

exports.register = async (req, res) => {
    try {
        const { customerName, mobile, email, password, location, } = req.body;

        // Validate required fields
        if (!customerName || !mobile || !password || !location) {
            return res.status(400).json({
                success: false,
                message: 'Name, mobile, password, and location are required'
            });
        }

        // Validate mobile format
        if (mobile.length < 7) {
            return res.status(400).json({
                success: false,
                message: 'Invalid mobile number format'
            });
        }

        // Validate password length
        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 6 characters'
            });
        }

        // Check if mobile already exists
        const existingMobile = await Customer.findOne({ mobile });
        if (existingMobile) {
            return res.status(400).json({
                success: false,
                message: 'Mobile number already registered'
            });
        }

        // Check if email already exists (if provided)
        if (email) {
            const existingEmail = await Customer.findOne({ email });
            if (existingEmail) {
                return res.status(400).json({
                    success: false,
                    message: 'Email already registered'
                });
            }
        }

        // Create new customer
        const customer = new Customer({
            customerName,
            mobile,
            email,
            password,
            address: location, // Use 'address' field as defined in the Customer model

        });

        await customer.save();
        console.log('✓ New Customer registered:', customerName);

        const token = signToken(customer);

        res.status(201).json({
            success: true,
            message: 'Customer registered successfully',
            token,
            customer: {
                _id: customer._id,
                customerName: customer.customerName,
                mobile: customer.mobile,
                email: customer.email,
                location: customer.location
            }
        });
    } catch (e) {
        console.error('Register error:', e);
        res.status(500).json({
            success: false,
            message: 'Server error during registration'
        });
    }
};

exports.verifyCredentials = async (req, res) => {
    try {
        const { mobile, password } = req.body;

        if (!mobile || !password) {
            return res.status(400).json({
                success: false,
                message: 'mobile and password are required'
            });
        }

        // Find shop owner by mobile
        const customer = await Customer.findOne({ mobile });

        if (!customer) {
            return res.status(404).json({
                success: false,
                message: 'Account not found for this mobile number'
            });
        }

        // Compare password using bcrypt
        const isValid = await customer.comparePassword(password);

        if (!isValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid password'
            });
        }

        // Generate token
        const token = signToken(customer);

        res.json({
            success: true,
            message: 'Login successful',
            token,
            owner: {
                _id: customer._id,
                customerName: customer.customerName,
                mobile: customer.mobile,
                email: customer.email,
                address: customer.location,
            }
        });
    } catch (e) {
        console.error('Verify credentials error:', e);
        res.status(500).json({
            success: false,
            message: 'Server error during authentication'
        });
    }
};

exports.checkMobileExists = async (req, res) => {
    try {
        const { mobile } = req.params;

        if (!mobile || mobile.length < 7) {
            return res.status(400).json({
                success: false,
                exists: false,
                message: 'Invalid mobile number'
            });
        }

        const customer = await Customer.findOne({ mobile });

        if (!customer) {
            return res.json({
                success: true,
                exists: false,
                message: `Mobile ${mobile} is available`
            });
        }

        res.json({
            success: true,
            exists: true,
            message: `Mobile ${mobile} is already registered`
        });
    } catch (e) {
        console.error('Check mobile error:', e);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
};

exports.checkEmailExists = async (req, res) => {
    try {
        const { email } = req.params;

        if (!email || !email.includes('@')) {
            return res.status(400).json({
                success: false,
                exists: false,
                message: 'Invalid email'
            });
        }

        const customer = await Customer.findOne({ email });

        if (!customer) {
            return res.json({
                success: true,
                exists: false,
                message: `Email ${email} is available`
            });
        }

        res.json({
            success: true,
            exists: true,
            message: `Email ${email} is already registered`
        });
    } catch (e) {
        console.error('Check email error:', e);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
};