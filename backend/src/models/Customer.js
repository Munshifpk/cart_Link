const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const CustomerSchema = new mongoose.Schema({
    customerName: { type: String, required: true },
    email: { type: String, required: false, lowercase: true },
    mobile: { type: Number, required: true, unique: true },
    password: { type: String, required: true },
    address: { type: String, required: false },
    following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Shop' }],
    createdAt: { type: Date, default: Date.now }

}
    , { collection: 'customers' }); // explicit collection name);

CustomerSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    this.password = await bcrypt.hash(this.password, 10);
    next();
});

CustomerSchema.methods.comparePassword = function (candidate) {
    return bcrypt.compare(candidate, this.password);
};

module.exports = mongoose.model('Customers', CustomerSchema);