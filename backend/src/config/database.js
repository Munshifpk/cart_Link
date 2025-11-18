const mongoose = require('mongoose');
require('dotenv').config();

const uri = process.env.MONGODB_URI ||  'mongodb://cartLink_mongodb:CartLink123@ac-2xfhn13-shard-00-00.edvcqv6.mongodb.net:27017,ac-2xfhn13-shard-00-01.edvcqv6.mongodb.net:27017,ac-2xfhn13-shard-00-02.edvcqv6.mongodb.net:27017/Cart_Link?ssl=true&authSource=admin&appName=Cart_Link'

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