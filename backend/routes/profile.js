// routes/profile.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

// Ensure the uploads directory exists
const uploadDir = 'uploads/';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// Set up multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

// Register a new user
router.post('/', upload.single('profileImage'), async (req, res) => {
  const { firstName, lastName, email, password, username, age, college, yearLevel, customInterests, categorizedInterests } = req.body;
  const profileImage = req.file ? req.file.path : undefined;

  // Log the incoming request body
  console.log('Incoming Request Body:', req.body);

  // Validate required fields
  const requiredFields = { firstName, lastName, email, password, username, age, college, yearLevel };
  for (const [key, value] of Object.entries(requiredFields)) {
    if (!value) {
      console.error(`${key} is required but was not provided:`, value);
    }
  }

  // Check if any required field is missing
  if (Object.values(requiredFields).some(field => !field)) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    // Hash password before saving
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = new User({
      firstName,
      lastName,
      email,
      password: hashedPassword,
      username,
      age,
      college,
      yearLevel,
      profileImage,
      customInterests: customInterests || [],  // Ensure it's set
      categorizedInterests: categorizedInterests || [] // Ensure it's set
    });

    await newUser.save();
    res.status(201).json(newUser);
  } catch (err) {
    console.error('Error during user creation:', err);
    res.status(500).send('Server Error');
  }
});

// Fetch user profile details
router.get('/:userId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .populate('following followers', 'username')
      .select('-password'); // Exclude password from response

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }
    
    console.log('Fetched User:', user); // Log the fetched user
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

// Update user profile with image upload
router.post('/:userId/update', upload.single('profileImage'), async (req, res) => {
  const { username, age, college, yearLevel, bio, customInterests, categorizedInterests } = req.body;
  const profileImage = req.file ? req.file.path : undefined;

  try {
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Update user fields, preserving existing values if not provided
    user.username = username || user.username;
    user.age = age || user.age;
    user.college = college || user.college;
    user.yearLevel = yearLevel || user.yearLevel;
    user.bio = bio || user.bio;
    user.profileImage = profileImage || user.profileImage;
    user.customInterests = customInterests || user.customInterests;
    user.categorizedInterests = categorizedInterests || user.categorizedInterests;

    await user.save();
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

// Follow a user
router.post('/:userId/follow', async (req, res) => {
  const { followId } = req.body;
  try {
    const user = await User.findById(req.params.userId);
    const followUser = await User.findById(followId);

    if (!user || !followUser) {
      return res.status(404).json({ msg: 'User not found' });
    }

    if (!user.following.includes(followId)) {
      user.following.push(followId);
      followUser.followers.push(req.params.userId);

      await user.save();
      await followUser.save();

      res.json({ msg: 'User followed' });
    } else {
      res.status(400).json({ msg: 'Already following' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

// Unfollow a user
router.post('/:userId/unfollow', async (req, res) => {
  const { followId } = req.body;
  try {
    const user = await User.findById(req.params.userId);
    const unfollowUser = await User.findById(followId);

    if (!user || !unfollowUser) {
      return res.status(404).json({ msg: 'User not found' });
    }

    if (user.following.includes(followId)) {
      user.following = user.following.filter(id => id.toString() !== followId);
      unfollowUser.followers = unfollowUser.followers.filter(id => id.toString() !== req.params.userId);

      await user.save();
      await unfollowUser.save();

      res.json({ msg: 'User unfollowed' });
    } else {
      res.status(400).json({ msg: 'Not following this user' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

module.exports = router;
