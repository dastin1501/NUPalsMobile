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

// GET a specific user's profile
router.get('/profile/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const user = await User.findById(userId)
      .select('firstName lastName email username age college yearLevel bio customInterests categorizedInterests followers follows profileImage'); // Include interests in the select statement

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json(user); // Return the user profile
  } catch (error) {
    console.error('Error fetching user profile:', error);
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

// POST update user interests
router.post('/update-interests/:userId', async (req, res) => {
  const { userId } = req.params;
  const { customInterests, categorizedInterests } = req.body; // Expecting interests to be sent in the body

  try {
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $set: { customInterests, categorizedInterests } }, // Update both interests fields
      { new: true } // Return the updated user
    );

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'Interests updated successfully', updatedUser });
  } catch (error) {
    console.error('Error updating interests:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Export the router
module.exports = router;
