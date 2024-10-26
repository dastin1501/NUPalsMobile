const express = require('express');
const router = express.Router();
const Feedback = require('../models/feedback'); // Assuming you have a Feedback model

// POST feedback
router.post('/', async (req, res) => {
  const { userId, message, timestamp } = req.body;

  const feedback = new Feedback({ userId, message, timestamp });
  try {
    await feedback.save();
    res.status(201).send({ message: 'Feedback submitted successfully!' });
  } catch (error) {
    res.status(500).send({ error: 'Failed to submit feedback' });
  }
});

module.exports = router;
