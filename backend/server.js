const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const http = require('http'); // Import http module for creating server
const socketIo = require('socket.io'); // Import Socket.IO
const authRoutes = require('./routes/auth');
const surveyRoutes = require('./routes/survey');
const profileRoutes = require('./routes/profile');
const postRoutes = require('./routes/post');
const userRoutes = require('./routes/users');
const messageRoutes = require('./routes/message');
const groupChatRoutes = require('./routes/groupchat');
const notificationRoutes = require('./routes/notifications'); // Add this line for notifications
const { GroupChat, GroupChatMessage } = require('./models/groupChat');
const feedbackRoutes = require('./routes/feedback');
const reportRoute = require('./routes/report');// Import both models
const User = require('./models/User');
const multiWordKeywordRoutes = require('./routes/multiWordKeywords');

// Load environment variables
dotenv.config();

// Initialize the Express app
const app = express();

// Enable CORS
app.use(cors({
  origin: '*', // Adjust as necessary
}));

// Increase the limit to 10mb (adjust as necessary)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Use the authentication, survey, profile, post, user, and notification routes
app.use('/api/auth', authRoutes);
app.use('/api/survey', surveyRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/group', groupChatRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/report', reportRoute); // This line is correct
app.use('/api/multi-word-keywords', multiWordKeywordRoutes);



// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  serverSelectionTimeoutMS: 5000,
})
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Create HTTP server and integrate Socket.IO
const server = http.createServer(app);
const io = socketIo(server);

io.on('connection', (socket) => {
  console.log('A user connected');

  // Join specific chat rooms
  socket.on('join', ({ userId, otherUserId }) => {
    socket.join(userId); // Join userId room
    socket.join(otherUserId); // Join otherUserId room
    console.log(`${userId} joined the chat with ${otherUserId}`);
  });


  // Listen for new messages in individual chats
  socket.on('new_message', (message) => {
    console.log('New message:', message);
    // Emit the message to the intended recipient only
    socket.to(message.receiverId).emit('new_message', message);
  });

  // Join specific group chat
  socket.on('joinGroup', (groupId) => {
    socket.join(groupId); // Join the group chat room
    console.log(`Socket ${socket.id} joined group ${groupId}`);
  });

  socket.on('sendMessage', async (message) => {
    try {
      // Log the received message for debugging
      console.log('Received message:', message);
 
      // Validate the message structure
      if (!message.groupId || !message.senderId || !message.content) {
        console.error('Invalid message structure:', message);
        return;
      }
 
      // Assuming `senderId` corresponds to a user in your User model
      const sender = await User.findById(message.senderId); // Fetch the sender's details
 
      if (!sender) {
        console.error('Sender not found:', message.senderId);
        return; // Early return if sender not found
      }
 
      // Create the message in the database
      const newMessage = new GroupChatMessage({
        groupId: message.groupId,
        senderId: message.senderId,
        content: message.content,
      });
 
      const savedMessage = await newMessage.save(); // Save to MongoDB
 
      // Prepare the message to emit with sender's details
      const messageToEmit = {
        _id: savedMessage._id,
        groupId: savedMessage.groupId,
        senderId: savedMessage.senderId, // This should be the sender's ID
        firstName: sender.firstName,      // Ensure sender's first name is emitted
        lastName: sender.lastName,        // Ensure sender's last name is emitted
        content: savedMessage.content,
        createdAt: savedMessage.createdAt,
      };
 
      // Emit the message to all users in the group chat
      io.to(message.groupId).emit('newMessage', messageToEmit);
    } catch (error) {
      console.error('Error handling message:', error);
    }
  });
 
});


// Basic route for testing server
app.get('/', (req, res) => {
  res.send('API is running...');
});

// Start the server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
