const express = require('express');
const User = require('../models/User');
const SurveyResponse = require('../models/surveyResponse');
const Log = require('../models/log');
const MultiWordKeyword = require('../models/MultiWordKeyword');
const Stopword = require('../models/Stopword');
const { GroupChat } = require('../models/GroupChat');

async function extractInterests(answers) {
    try {
        const specificInterests = [];
        const combinedAnswers = answers.join(' ').toLowerCase();

        // Retrieve stopwords and multi-word keywords from the database
        const stopWordsSet = new Set((await Stopword.find()).map(stopword => stopword.word.toLowerCase()));
        const multiWordKeywords = (await MultiWordKeyword.find()).map(k => k.keyword.toLowerCase());

        // Normalize the combined answers
        let markedCombinedAnswers = combinedAnswers;

        // Detect multi-word keywords first
        multiWordKeywords.forEach(keyword => {
            if (markedCombinedAnswers.includes(keyword) && !specificInterests.includes(keyword)) {
                specificInterests.push(keyword);
                // Mark the found keyword to prevent splitting
                markedCombinedAnswers = markedCombinedAnswers.replace(keyword, '');
            }
        });

        // Split words and filter out stopwords
        const singleWords = markedCombinedAnswers
            .split(/[\s,]+/)
            .map(word => word.replace(/[^a-z]/g, ''))
            .filter(word => word && !stopWordsSet.has(word));

        const frequencyMap = {};

        // Count the frequency of each single word
        singleWords.forEach(word => {
            frequencyMap[word] = (frequencyMap[word] || 0) + 1;
        });

        // Sort by frequency and limit to top 3 specific interests
        const sortedWords = Object.keys(frequencyMap).sort((a, b) => frequencyMap[b] - frequencyMap[a]);
        const uniqueInterests = [...specificInterests, ...sortedWords].slice(0, 3);

        return { specificInterests: uniqueInterests };
    } catch (error) {
        console.error("Error in extractInterests:", error);
        throw error;
    }
}

async function addInterestsToGroupChat(interests) {
    for (const interest of interests) {
        // Check if the interest already exists in the GroupChat collection
        const existingGroupChat = await GroupChat.findOne({ title: interest });

        if (!existingGroupChat) {
            // If not, add it to the GroupChat collection
            const newGroupChat = new GroupChat({ title: interest });
            await newGroupChat.save();
        }
    }
}


// Express.js setup
const router = express.Router();

router.post('/analyze', async (req, res) => {
    const { userId, surveyResponse } = req.body;

    if (!userId || !surveyResponse || !surveyResponse.questions) {
        return res.status(400).json({ error: 'userId and surveyResponse with questions are required.' });
    }

    try {
        // Check if the user already has a survey response
        const existingResponse = await SurveyResponse.findOne({ userId });

        if (existingResponse) {
            const now = new Date();
            const lastEdited = existingResponse.lastEdited || new Date(0); // Default to epoch if not set
            const timeDiff = now - lastEdited;

            // Check if less than 7 days (in milliseconds)
            if (timeDiff < 7 * 24 * 60 * 60 * 1000) {
                return res.status(403).json({ error: 'You can only edit your survey once every 7 days.' });
            }
        }

        const responses = surveyResponse.questions.map(q => q.answer);
        const analysis = await extractInterests(responses);

        // Save the survey response and analysis result to the database
        const newSurveyResponse = new SurveyResponse({
            userId,
            surveyResponse,
            analysisResult: {
                specificInterests: analysis.specificInterests,
                topCategories: analysis.topCategories
            },
            lastEdited: new Date() // Set the last edited timestamp
        });

        await newSurveyResponse.save();

        // Update the user's custom interests and lastSurveyDate
        await User.findByIdAndUpdate(userId, {
            $set: {
                customInterests: analysis.specificInterests,
                categorizedInterests: analysis.topCategories,
                lastSurveyDate: new Date() // Update last survey date
            }
        });

        // Fetch the user's email based on userId
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Log the user interest update action with the fetched email
        await Log.create({
            level: 'info',
            message: 'User updated interests based on survey',
            studentId: userId,
            studentName: user.email,
        });

             // Add each specific interest to the GroupChat collection if it doesn't already exist
    await addInterestsToGroupChat(analysis.specificInterests);

        return res.status(200).json({
            interests: analysis.specificInterests,
            topCategories: analysis.topCategories
        });
    } catch (error) {
        console.error("Error analyzing survey response:", error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;