const express = require('express');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const User = require('../models/User');
const Log = require('../models/log');
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

  // Check if user exists
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(400).json({ message: 'Email already exist!' });
  }

  // Generate verification code
  const code = crypto.randomBytes(3).toString('hex');
  verificationCodes[email] = code;

  // Send email with the code
  const mailOptions = {
    from: 'no-reply@yourapp.com',
    to: email,
    subject: 'Verification Code',
    text: `Your verification code is: ${code}`,
  };

  transporter.sendMail(mailOptions, (error) => {
    if (error) {
      return res.status(500).json({ message: 'Failed to send email' });
    }
    res.status(200).json({ message: 'Verification code sent to email' });
  });
});

// Verify the provided verification code
router.post('/verify-code', async (req, res) => {
  const { email, code } = req.body;

  // Validate verification code
  if (verificationCodes[email] !== code) {
    return res.status(400).json({ message: 'Invalid verification code' });
  }

  // If valid, clear the code from storage
  delete verificationCodes[email];

  // Respond with success
  res.status(200).json({ message: 'Verification code is valid' });
});



// Send email verification code for forgot password
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
 
  // Ensure email domain is correct
  if (!email.endsWith('@students.national-u.edu.ph')) {
    return res.status(400).json({ message: 'Invalid email domain' });
  }
 
  // Check if user exists
  const existingUser = await User.findOne({ email });
  if (!existingUser) {
    return res.status(400).json({ message: 'User not found' });
  }
 
  // Generate verification code
  const code = crypto.randomBytes(3).toString('hex');
  verificationCodes[email] = code;
 
  // Send email with the code
  const mailOptions = {
    from: 'no-reply@yourapp.com',
    to: email,
    subject: 'Password Reset Code',
    text: `Your password reset code is: ${code}`,
  };
 
  transporter.sendMail(mailOptions, (error) => {
    if (error) {
      return res.status(500).json({ message: 'Failed to send email' });
    }
    res.status(200).json({ message: 'Verification code sent to email' });
  });
});
 
// Reset password
router.post('/reset-password', async (req, res) => {
  const { email, code, newPassword } = req.body;
 
  // Validate verification code
  if (verificationCodes[email] !== code) {
    return res.status(400).json({ message: 'Invalid verification code' });
  }
 
  // Hash the new password
  const hashedPassword = await bcrypt.hash(newPassword, 10);
 
  // Update user's password
  await User.updateOne({ email }, { password: hashedPassword });
  delete verificationCodes[email]; // Clear the used code
 
  res.status(200).json({ message: 'Password reset successfully' });
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
 
  // Validate email domain
  if (!email.endsWith('@test.com')) {
    return res.status(400).json({ message: 'Invalid email domain' });
  }
 
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'User not found', userId: null });
    }
 
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials', userId: null });
    }
 
    await Log.create({
      level: 'info',
      message: 'User logged in',
      studentId: user._id,
      studentName: user.email,
    });
 
    return res.status(200).json({
      userId: user._id.toString(),
      message: 'Login successful',
    });
  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ message: 'Server error' });
  }
});
 
//logout
router.post('/logout', async (req, res) => {
  const { userId } = req.body; // Only send userId in the request body
 
  try {
    // Fetch the user based on userId
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
 
    // Log the logout action with the user's email
    await Log.create({
      level: 'info',
      message: 'User logged out',
      studentId: userId,
      studentName: user.email, // Use user's email directly
    });
 
    // Handle any other logout logic, if necessary
    res.status(200).json({ message: 'User logged out successfully' });
  } catch (error) {
    console.error(error); // Log the error for debugging
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;