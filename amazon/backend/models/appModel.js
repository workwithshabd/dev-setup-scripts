const mongoose = require('mongoose');

const appSchema = new mongoose.Schema({
  message: { type: String, required: true }
}, { timestamps: true });

module.exports = mongoose.model('App', appSchema);
