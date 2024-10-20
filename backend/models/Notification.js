const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['follow'],  // You can expand this for other notification types in the future
    required: true,
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,  // The user who performed the action (e.g., the follower)
    ref: 'User',
    required: true,
  },
  receiverId: {
    type: mongoose.Schema.Types.ObjectId,  // The user who receives the notification (e.g., the one being followed)
    ref: 'User',
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  read: {
    type: Boolean,
    default: false,  // Track if the notification has been read
  },
  timestamp: {
    type: Date,
    default: Date.now,  
  },
});

const Notification = mongoose.model('Notification', notificationSchema);
module.exports = Notification;
