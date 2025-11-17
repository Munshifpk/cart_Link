const express = require('express');
const cors = require('cors');
require('./config/database'); // establish DB connection
const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/auth', authRoutes);

app.get('/api/health', (req, res) => res.json({ status: 'ok', time: new Date() }));

module.exports = app;