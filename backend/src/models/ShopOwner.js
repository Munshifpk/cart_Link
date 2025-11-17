const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const ShopOwnerSchema = new mongoose.Schema({
    shopName: { type: String, required: true },
    ownerName: { type: String, required: true },
    email: { type: String, required: false, lowercase: true },
    mobile: { type: Number, required: true, unique: true },
    password: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
}
    , { collection: 'Shops' }); // explicit collection name);

ShopOwnerSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    this.password = await bcrypt.hash(this.password, 10);
    next();
});

ShopOwnerSchema.methods.comparePassword = function (candidate) {
    return bcrypt.compare(candidate, this.password);
};

module.exports = mongoose.model('Shops', ShopOwnerSchema);