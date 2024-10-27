// routes/stopwords.js
const express = require('express');
const router = express.Router();
const Stopword = require('../models/Stopword');

// Add a stopword
router.post('/add', async (req, res) => {
    const { word } = req.body;
    if (!word) {
        return res.status(400).json({ error: "Word is required" });
    }

    try {
        const newStopword = new Stopword({ word: word.toLowerCase() });
        await newStopword.save();
        res.status(201).json({ message: 'Stopword added successfully', stopword: newStopword });
    } catch (error) {
        console.error("Error adding stopword:", error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Delete a stopword
router.delete('/delete', async (req, res) => {
    const { word } = req.body;
    if (!word) {
        return res.status(400).json({ error: "Word is required" });
    }

    try {
        const result = await Stopword.deleteOne({ word: word.toLowerCase() });
        if (result.deletedCount > 0) {
            res.status(200).json({ message: 'Stopword deleted successfully' });
        } else {
            res.status(404).json({ error: 'Stopword not found' });
        }
    } catch (error) {
        console.error("Error deleting stopword:", error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// View all stopwords
router.get('/', async (req, res) => {
    try {
        const stopwords = await Stopword.find();
        res.status(200).json(stopwords);
    } catch (error) {
        console.error("Error fetching stopwords:", error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
