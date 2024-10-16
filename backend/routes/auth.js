const express = require('express');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const User = require('../models/User');
const router = express.Router();

// Temporary store for email verification codes
const verificationCodes = {};

// Configure your email transport
const transporter = nodemailer.createTransport({
  service: 'Gmail',
  auth: {
    user: 'nupalsbulldogs@gmail.com', // Replace with your email
    pass: 'aany zmjb pswo jvlp', // Replace with your app password
  },
});

// Send email verification code
router.post('/send-verification', async (req, res) => {
  const { email } = req.body;

  // Ensure email domain is correct
  if (!email.endsWith('@students.national-u.edu.ph')) {
    return res.status(400).json({ message: 'Invalid email domain' });
  }

  // Check if user already exists
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(400).json({ message: 'User already exists' });
  }

  // Generate verification code
  const code = crypto.randomBytes(3).toString('hex');
  verificationCodes[email] = code;

  // Send email with the code
  const mailOptions = {
    from: 'no-reply@yourapp.com',
    to: email,
    subject: 'Email Verification',
    text: `Your verification code is: ${code}`,
  };

  transporter.sendMail(mailOptions, (error) => {
    if (error) {
      return res.status(500).json({ message: 'Failed to send email' });
    }
    res.status(200).json({ message: 'Verification code sent' });
  });
});

// Verify the code only
router.post('/verify-code', async (req, res) => {
  const { email, code } = req.body;

  // Check if the code matches
  if (verificationCodes[email] !== code) {
    return res.status(400).json({ message: 'Invalid verification code' });
  }

  // Code is valid, respond with success message
  res.status(200).json({ message: 'Verification successful. Please proceed to register.' });
});

// Route to handle user registration
router.post('/register', async (req, res) => {
  const { email, username, password, age, college, yearLevel, bio } = req.body;

  // Check if the user already exists
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(400).json({ message: 'User already exists' });
  }

  // Hash the password
  const hashedPassword = await bcrypt.hash(password, 10);

  // Create the user
  const newUser = new User({
    email,
    password: hashedPassword,
    username,
    age,
    college,
    yearLevel,
    bio,
  });

  try {
    const savedUser = await newUser.save();
    res.status(201).json({
      message: 'User created successfully',
      userId: savedUser._id.toString(), // Return the user ID
    });
  } catch (error) {
    console.error('Error during user creation:', error);
    res.status(500).json({ message: 'Error during user creation' });
  }
});

// Login route
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    return res.status(200).json({
      userId: user._id.toString(), // Include user ID in response
      message: 'Login successful',
    });
  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
