const express = require('express');
const axios = require('axios');
const mongoose = require('mongoose');
const User = require('../models/User'); // Assuming user.js is in the root folder
const router = express.Router();
const Fuse = require('fuse.js'); // Import Fuse.js

// Hugging Face API Key
const HUGGING_FACE_API_KEY = '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'; // Replace with your API key

// Categories mapping based on keywords
const interestCategories = {
  Sports: ['jogging', 'parachuting', 'soccer', 'basketball', 'tennis', 'swimming', 'running'],
  Arts: ['drawing', 'painting', 'music', 'theater', 'sculpting', 'photography'],
  Technology: ['AI programming', 'software', 'coding', 'web development', 'data science', 'machine learning'],
  Gaming: ['gaming', 'video games', 'e-sports'],
  Horror: ['horror', 'thriller', 'suspense'],
  Fitness: ['gym', 'exercise', 'yoga', 'weightlifting'],
  Cooking: ['cooking', 'baking', 'culinary'],
  Nature: ['hiking', 'camping', 'outdoor activities'],
  Literature: ['reading', 'writing', 'poetry', 'novels'],
  Travel: ['travel', 'exploring', 'vacation'],
  // Add more categories as needed
};

// Prepare the keywords for Fuse.js
const keywordsArray = Object.entries(interestCategories).flatMap(([category, keywords]) =>
  keywords.map(keyword => ({ keyword, category }))
);

const fuse = new Fuse(keywordsArray, {
  keys: ['keyword'],
  threshold: 0.3, // Adjust threshold for matching
});

// Route to process user interests
router.post('/submit-survey', async (req, res) => {
  const { email, answers } = req.body; // Expect email instead of userId

  // Check if email and answers are provided
  if (!email || !answers || !Array.isArray(answers)) {
    return res.status(400).json({ error: 'Email and answers are required.' });
  }

  // Log received data for debugging
  console.log('Received email:', email);
  console.log('Received answers:', answers);

  try {
    // Find user by email to get the ObjectId
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ error: 'User not found' });
    }

    const userId = user._id; // Get the MongoDB ObjectId

    // Combine all answers into a single string
    const userInput = answers.join(' ');

    // Extract custom interests using Hugging Face API
    const customInterests = await extractCustomInterests(userInput);
    // Classify categorized interests
    const categorizedInterests = classifyCategorizedInterests(customInterests);

    // Log extracted interests for debugging
    console.log('Custom Interests:', customInterests);
    console.log('Categorized Interests:', categorizedInterests);

    // Update user interests in MongoDB
    await User.findOneAndUpdate(
      { _id: userId }, // Ensure we are querying with the correct field
      {
        customInterests, // Save custom interests in the interests field
        categorizedInterests, // Save categorized interests
      },
      { new: true, upsert: true } // Create a new document if one does not exist
    );

    res.json({ message: 'Interests saved successfully!', customInterests, categorizedInterests });
  } catch (error) {
    console.error('Error processing interests:', error.message);
    res.status(500).json({ error: 'Failed to process interests' });
  }
});

// Function to extract custom interests using NER
async function extractCustomInterests(userInput) {
  try {
    const response = await axios.post(
      'https://api-inference.huggingface.co/models/dbmdz/bert-large-cased-finetuned-conll03-english',
      { inputs: userInput },
      {
        headers: {
          'Authorization': `Bearer ${HUGGING_FACE_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );
    console.log('Custom interests response:', response.data); // Log API response for debugging

    // Adjust this mapping based on the actual structure of response.data
    if (Array.isArray(response.data)) {
      return response.data.map(entity => entity.word || entity); // Fallback to entity itself if 'word' is not available
    } else {
      return []; // Return an empty array if the response is not in expected format
    }
  } catch (error) {
    console.error('Error extracting custom interests:', error.response?.data || error.message);
    return []; // Return an empty array in case of an error
  }
}

// Function to classify categorized interests based on custom interests using Fuse.js
function classifyCategorizedInterests(customInterests) {
  const categorized = new Set(); // Use Set to avoid duplicates

  if (customInterests.length === 0) {
    return []; // Return an empty array if no custom interests are found
  }

  customInterests.forEach(interest => {
    const results = fuse.search(interest);

    results.forEach(result => {
      categorized.add(result.item.category); // Add the category if a match is found
    });
  });

  return Array.from(categorized); // Convert Set to Array
}

module.exports = router;
