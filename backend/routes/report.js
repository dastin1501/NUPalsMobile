const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Report = require('../models/report');

// Report a user
router.post('/:userId', async (req, res) => {
    const { userId } = req.params;
    const { reportedBy, reason } = req.body;

    try {
        const reportedUser = await User.findById(userId);

        if (!reportedUser) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Create a new report
        const report = new Report({
            reportedUser: userId,
            reportedBy: reportedBy,
            reason: reason,
            date: Date.now(),
        });

        await report.save();
        return res.status(201).json({ message: 'Report submitted successfully' });
    } catch (error) {
        return res.status(500).json({ message: 'Server error', error });
    }
});

module.exports = router;
