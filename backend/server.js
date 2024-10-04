const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const authRoutes = require('./routes/auth');
const surveyRoutes = require('./routes/survey'); // Import survey routes
const profileRoutes = require('./routes/profile');
const postRoutes = require('./routes/post');
const cors = require('cors');
const User = require('./models/User'); // Import your User model

// Load environment variables
dotenv.config();

// Initialize the Express app
const app = express();

// Enable CORS
app.use(cors({
  origin: '*', // Adjust this if needed
}));

// Middleware to parse JSON requests
app.use(express.json());

// Use the authentication, survey, profile, and post routes
app.use('/api/auth', authRoutes);
app.use('/api/survey', surveyRoutes); // Use survey routes for interest handling
app.use('/api/profile', profileRoutes);
app.use('/api/posts', postRoutes); // Add post routes

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
