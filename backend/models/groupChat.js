
const mongoose = require('mongoose');
const Schema = mongoose.Schema;

// Group Chat Schema
const groupChatSchema = new Schema({
  title: { type: String, required: true, unique: true  }, 
}, { timestamps: true });

// Group Chat Message Schema
const GroupChatMessageSchema = new Schema({
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'GroupChat', required: true }, // Reference to GroupChat
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Reference to sender
  content: { type: String, required: true },
}, { timestamps: true });

// Create models
const GroupChat = mongoose.models.GroupChat || mongoose.model('GroupChat', groupChatSchema);
const GroupChatMessage = mongoose.models.GroupChatMessage || mongoose.model('GroupChatMessage', GroupChatMessageSchema);

// Export models
module.exports = {
  GroupChat,
  GroupChatMessage,
};
