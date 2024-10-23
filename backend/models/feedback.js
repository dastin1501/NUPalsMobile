const mongoose = require('mongoose');

const FeedbackSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  message: { type: String, required: true },
  timestamp: { type: Date, required: true },
});

const Feedback = mongoose.model('Feedback', FeedbackSchema);
module.exports = Feedback;
