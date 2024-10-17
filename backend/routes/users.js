// routes/users.js
const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Adjust the path if needed

// GET all users
router.get('/', async (req, res) => {
  try {
    const users = await User.find(); // Fetch all users from the database
    res.json(users); // Send the users data as JSON
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET mutual followers for a user
router.get('/mutual-followers/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const user = await User.findById(userId).populate('followers'); // Assuming 'followers' is an array of user IDs
    const mutualFollowers = [];

    // Check each follower to see if they follow back
    for (const follower of user.followers) {
      const followedUser = await User.findById(follower._id).populate('followers');
      if (followedUser.followers.some(f => f.equals(userId))) {
        mutualFollowers.push({
          userId: follower._id,
          username: follower.username, // Assuming there's a username field in your User model
          lastMessage: 'Last message placeholder', // Optional: Add logic to fetch the last message if needed
        });
      }
    }

    res.json(mutualFollowers);
  } catch (error) {
    console.error('Error fetching mutual followers:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Export the router
module.exports = router;
