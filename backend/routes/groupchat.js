const express = require('express');
const User = require('../models/User');
const { GroupChat, GroupChatMessage } = require('../models/GroupChat');
const router = express.Router();

// 1. Fetch all group chats for a user
router.get('/chat/:userId', async (req, res) => {
    try {
      const userId = req.params.userId;
  
      // Fetch group chats based on user's categorized interests
      const user = await User.findById(userId).select('customInterests');
      const groupChats = await GroupChat.find({
        title: { $in: user.customInterests }, // Match group chat titles with user's interests
      });
  
      return res.status(200).json(groupChats);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Failed to load group chats.' });
    }
  });
  
  // 2. Fetch messages for a specific group chat
  router.get('/message/:groupChatId', async (req, res) => {
    try {
        const groupChatId = req.params.groupChatId;
        const messages = await GroupChatMessage.find({ groupId: groupChatId })
            .populate('senderId', 'firstName lastName'); // Populates firstName and lastName from the User model

        console.log(messages); // Log messages to check if firstName and lastName are populated

        return res.status(200).json(messages);
    } catch (error) {
        console.error(error);
        return res.status(500).json({ message: 'Failed to load messages.' });
    }
});

  
  // 3. Send a message to a group chat
  router.post('/message', async (req, res) => {
    try {
      const { groupId, senderId, content } = req.body;
  
      const newMessage = new GroupChatMessage({
        groupId,
        senderId,
        content,
      });
  
      await newMessage.save();
      return res.status(201).json(newMessage);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Failed to send message.' });
    }
  });
  
  // 4. Update participants based on interests (optional)
  router.put('/update-participants', async (req, res) => {
    try {
      const { userId, interest } = req.body;
  
      // Logic to update group chat participants based on interests goes here
      // For example, you might want to add the user to a group chat if they share an interest.
  
      return res.status(200).json({ message: 'Participants updated successfully.' });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Failed to update participants.' });
    }
  });
  

  // Route to count users with a specific interest
router.get('/countByInterest/:interest', async (req, res) => {
  const { interest } = req.params;
  try {
    // Count users with the specified interest in their customInterests field
    const count = await User.countDocuments({ customInterests: interest });
    res.status(200).json({ interest, count });
  } catch (error) {
    res.status(500).json({ message: 'Error counting users', error: error.message });
  }
});


module.exports = router;
