const mongoose = require('mongoose');

const multiWordKeywordSchema = new mongoose.Schema({
    keyword: { type: String, required: true, unique: true }
});

module.exports = mongoose.model('MultiWordKeyword', multiWordKeywordSchema);
