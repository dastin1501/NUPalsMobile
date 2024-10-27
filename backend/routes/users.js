const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Adjust the path if needed
const Notification = require('../models/Notification'); // Import the Notification model
const Message = require('../models/Message');

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
      .select('firstName lastName email username age college bio customInterests categorizedInterests followers following profileImage'); // Include interests in the select statement

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
    const mutualFollowers = new Set(); // Use a Set to avoid duplicates

    // Check each follower to see if they follow back
    for (const follower of user.followers) {
      const followedUser = await User.findById(follower._id).populate('followers');

      // Only add if they still follow each other
      if (followedUser.followers.some(f => f.equals(userId))) {
        // Fetch the last message between the user and the mutual follower
        const lastMessage = await Message.findOne({
          $or: [
            { senderId: userId, receiverId: follower._id.toString() },
            { senderId: follower._id.toString(), receiverId: userId }
          ]
        }).sort({ createdAt: -1 }); // Sort to get the latest message

        // Add to the Set to avoid duplicates
        mutualFollowers.add({
          userId: follower._id,
          username: follower.username,
          profilePicture: follower.profilePicture || null, // Include profile picture
          lastMessage: lastMessage ? lastMessage.content : 'No messages exchanged',
          timestamp: lastMessage ? lastMessage.createdAt : null, // Include timestamp for last message
        });
      }
    }

    // Convert the Set back to an array
    res.json(Array.from(mutualFollowers));
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
