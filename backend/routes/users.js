const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Adjust the path if needed
const Notification = require('../models/Notification'); // Import the Notification model

// GET all users with student role
router.get('/', async (req, res) => {
  try {
    // Fetch all users with role 'student' from the database
    const users = await User.find({ role: 'student' }); // Adjust the field name if your role field is named differently
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

// POST send a follow request
router.post('/follow', async (req, res) => {
  const { followerId, followeeId } = req.body; // Get follower and followee IDs from the request

  try {
    // Step 1: Add follower to the followee's followers (Assuming followee has a followers array)
    const followee = await User.findById(followeeId);
    followee.followers.push(followerId); // Add the followerId to the followee's followers array
    await followee.save(); // Save the followee

    // Step 2: Create a notification for the follow request
    const message = `${followerId} sent you a follow request.`; // Create notification message
    await Notification.create({ userId: followeeId, type: 'follow_request', message }); // Create notification

    res.status(200).json({ message: 'Follow request sent.' }); // Respond to the client
  } catch (error) {
    console.error('Error sending follow request:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// POST create a notification for admin posts
router.post('/notify-post', async (req, res) => {
  const { postId, adminId } = req.body; // Assuming postId and adminId are provided

  try {
    // Step 1: Get the admin's post details (if needed)
    const message = `Admin has posted a new update: ${postId}`; // Create notification message

    // Step 2: Fetch all users
    const users = await User.find({});
    users.forEach(async (user) => {
      await Notification.create({ userId: user._id, type: 'post', message }); // Create notification for each user
    });

    res.status(200).json({ message: 'Notifications sent for admin post.' });
  } catch (error) {
    console.error('Error sending notifications for admin post:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Export the router
module.exports = router;
