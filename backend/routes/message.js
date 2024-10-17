const express = require('express');
const router = express.Router();
const Message = require('../models/Message'); // Your Message model

// GET messages between two users
router.get('/:senderId/:receiverId', async (req, res) => {
  const { senderId, receiverId } = req.params;
  try {
    const messages = await Message.find({
      $or: [
        { senderId, receiverId },
        { senderId: receiverId, receiverId: senderId },
      ],
    }).sort({ createdAt: 1 }); // Sort messages by creation time
    res.json(messages);
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// POST a new message
router.post('/', async (req, res) => {
  const { senderId, receiverId, content } = req.body;
  try {
    const newMessage = new Message({ senderId, receiverId, content });
    await newMessage.save();
    res.status(201).json(newMessage);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;
