// routes/notifications.js
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Notification = require('../models/Notification'); // Ensure correct path to your Notification model

// GET notifications for a user
router.get('/:userId/notifications', async (req, res) => {
  try {
    const notifications = await Notification.find({ receiverId: req.params.userId })
      .sort({ timestamp: -1 }) // Sort by latest notifications
      .populate('senderId', 'firstName lastName'); // Populate sender info if needed

    res.json(notifications);
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ message: 'Server Error' });
  }
});

module.exports = router;
