const express = require('express');
const MultiWordKeyword = require('../models/MultiWordKeyword');
const router = express.Router();

// Create a new multi-word keyword
router.post('/', async (req, res) => {
    const { keyword } = req.body;
    if (!keyword) {
        return res.status(400).json({ error: 'Keyword is required.' });
    }

    try {
        const newKeyword = new MultiWordKeyword({ keyword });
        await newKeyword.save();
        return res.status(201).json(newKeyword);
    } catch (error) {
        console.error('Error creating multi-word keyword:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});

// Get all multi-word keywords
router.get('/', async (req, res) => {
    try {
        const keywords = await MultiWordKeyword.find();
        return res.status(200).json(keywords);
    } catch (error) {
        console.error('Error fetching multi-word keywords:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});

// Delete a multi-word keyword by ID
router.delete('/:id', async (req, res) => {
    try {
        const deletedKeyword = await MultiWordKeyword.findByIdAndDelete(req.params.id);
        if (!deletedKeyword) {
            return res.status(404).json({ error: 'Keyword not found.' });
        }
        return res.status(200).json({ message: 'Keyword deleted successfully.' });
    } catch (error) {
        console.error('Error deleting multi-word keyword:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
