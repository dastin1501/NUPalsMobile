// routes/admin.js
const express = require('express');
const Post = require('../models/Post'); // Assuming you have a Post model
const Notification = require('../models/Notification'); // Import the Notification model
const router = express.Router();

// Admin creates a new post
router.post('/post', async (req, res) => {
  const { title, content } = req.body; // Get post details from the request

  try {
    // Step 1: Create the new post
    const newPost = new Post({ title, content });
    await newPost.save(); // Save the post to the database

    // Step 2: Notify all users about the new post
    const users = await User.find({}); // Get all users from the database
    users.forEach(async (user) => {
      const message = `Admin posted: ${newPost.title}`; // Create notification message
      await Notification.create({ userId: user._id, type: 'post', message }); // Create notification
    });

    res.status(201).json(newPost); // Respond with the created post
  } catch (error) {
    res.status(500).json({ error: error.message }); // Handle errors
  }
});

module.exports = router;
