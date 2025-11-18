const mongoose = require('mongoose');
require('dotenv').config();

const uri = process.env.MONGODB_URI || MONGODB_URI;

mongoose.set('strictQuery', true);

mongoose.connect(uri, {
    autoIndex: true
})
    .then(() => console.log('✓ MongoDB connected'))
    .catch(err => {
        console.error('❌ MongoDB connection error:', err);
        process.exit(1);
    });

module.exports = mongoose;