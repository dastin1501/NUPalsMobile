// routes/notifications.js
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Notification = require('../models/Notification'); // Ensure correct path to your Notification model

// Get notifications for a specific user
router.get('/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    // Validate if userId is a valid MongoDB ObjectId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid User ID' });
    }

    // Fetch notifications for the user
    const notifications = await Notification.find({ userId });

    res.json(notifications);
  } catch (error) {
    console.error('Error fetching notifications:', error); // Log the error to the console
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
