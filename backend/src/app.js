const express = require('express');
const cors = require('cors');
require('./config/database');
const authRoutes = require('./routes/authRoutes');
const shopRoutes = require('./routes/shopRoutes');
const customerAuthRoutes = require('./routes/customerAuthRoutes');
const customersRoutes = require('./routes/customerRoutes');
const productRoutes = require('./routes/productRoutes');
const cartRoutes = require('./routes/cartRoutes');

const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Set request timeout to 2 minutes
app.use((req, res, next) => {
    req.setTimeout(120000);
    res.setTimeout(120000);
    next();
});

app.use('/api/auth', authRoutes);
app.use('/api/Shops', shopRoutes);
app.use('/api/customersAuth', customerAuthRoutes);
app.use('/api/customers', customersRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);

app.get('/api/health', (req, res) => {
    res.json({ status: 'Backend is running ✓', timestamp: new Date() });
});

module.exports = app;