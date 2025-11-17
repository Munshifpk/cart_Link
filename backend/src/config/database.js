const mongoose = require('mongoose');
require('dotenv').config();

const uri = process.env.MONGODB_URI || 'mongodb+srv://cartLink_mongodb:CartLink123@cartlink.edvcqv6.mongodb.net/Cart_Link?appName=CartLink';

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