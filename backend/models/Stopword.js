// models/Stopword.js
const mongoose = require('mongoose');

const StopwordSchema = new mongoose.Schema({
    word: { type: String, required: true, unique: true },
});

module.exports = mongoose.model('Stopword', StopwordSchema);
