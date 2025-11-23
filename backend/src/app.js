const express = require('express');
const cors = require('cors');
require('./config/database');
const authRoutes = require('./routes/authRoutes');
const shopRoutes = require('./routes/shopRoutes');
const customerAuthRoutes = require('./routes/customerAuthRoutes');
const productRoutes = require('./routes/productRoutes');

const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/auth', authRoutes);
app.use('/api/Shops', shopRoutes);
app.use('/api/customersAuth', customerAuthRoutes);
app.use('/api/products', productRoutes);

app.get('/api/health', (req, res) => {
    res.json({ status: 'Backend is running ✓', timestamp: new Date() });
});

module.exports = app;