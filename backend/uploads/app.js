const express = require('express');
const mongoose = require('mongoose');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const surveyRoutes = require('./routes/survey'); // Import the survey routes
const path = require('path');
const dotenv = require('dotenv');  // Import dotenv
const app = express();

// Load environment variables
dotenv.config();

// Middleware
app.use(express.json());  // For parsing application/json
app.use(express.urlencoded({ extended: true }));  // For parsing application/x-www-form-urlencoded
app.use('/uploads', express.static(path.join(__dirname, 'uploads'))); // Serve profile images

// Routes
app.use('/api/auth', authRoutes); // Use '/api/auth' prefix for auth routes
app.use('/api/profile', profileRoutes); // Use '/api/profile' prefix for profile routes
app.use('/api/survey', surveyRoutes); // Use '/api/survey' prefix for survey routes

// Database connection
mongoose.connect(process.env.MONGO_URI, {  // Use environment variable for MongoDB URI
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('Failed to connect to MongoDB', err));

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
