const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const surveyRoutes = require('./routes/survey');
const profileRoutes = require('./routes/profile');
const postRoutes = require('./routes/post');
const userRoutes = require('./routes/users');
const messageRoutes = require('./routes/message');
const notificationRoutes = require('./routes/notifications'); // Add this line for messages

// Load environment variables
dotenv.config();

// Initialize the Express app
const app = express();

// Enable CORS
app.use(cors({
  origin: '*', // Adjust as necessary
}));

// Middleware to parse JSON requests
app.use(express.json());

// Use the authentication, survey, profile, post, and user routes
app.use('/api/auth', authRoutes);
app.use('/api/survey', surveyRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/notifications', notificationRoutes); // Add this line for message routes

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  serverSelectionTimeoutMS: 5000,
})
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Basic route for testing server
app.get('/', (req, res) => {
  res.send('API is running...');
});

// Start the server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
