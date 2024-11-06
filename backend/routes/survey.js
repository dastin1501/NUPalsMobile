const express = require('express');
const User = require('../models/User');
const SurveyResponse = require('../models/surveyResponse');
const Log = require('../models/log');
const natural = require('natural');
const Tokenizer = natural.WordTokenizer;
const tokenizer = new Tokenizer();
const stopwords = natural.stopwords; // Corrected import
const MultiWordKeyword = require('../models/MultiWordKeyword');
const Stopword = require('../models/Stopword');
const { GroupChat } = require('../models/groupChat');

async function extractInterests(answers) {
    try {
        const specificInterests = [];
        const combinedAnswers = answers.join(' ').toLowerCase();

        // Step 1: Retrieve multi-word keywords from the database
        const multiWordKeywords = (await MultiWordKeyword.find()).map(k => k.keyword.toLowerCase());

        // Step 2: Normalize the combined answers
        let markedCombinedAnswers = combinedAnswers;

        // Step 3: Detect multi-word keywords first
        multiWordKeywords.forEach(keyword => {
            if (markedCombinedAnswers.includes(keyword) && !specificInterests.includes(keyword)) {
                specificInterests.push(keyword); // Add keyword to the specific interests
                // Mark the found keyword to prevent splitting (remove from combinedAnswers)
                markedCombinedAnswers = markedCombinedAnswers.replace(keyword, ''); // Remove it from combinedAnswers
            }
        });

        // Step 4: Tokenization on the remaining (now cleaned) combined answers
        let tokens = tokenizer.tokenize(markedCombinedAnswers);

        // Step 5: Retrieve stopwords from the database
        const stopWordsSet = new Set([
            ...stopwords, // Natural's stopwords
            ...(await Stopword.find()).map(stopword => stopword.word.toLowerCase()) // Custom stopwords from DB
        ]);

        // Step 6: Filter out stopwords from the tokens
        const filteredTokens = tokens.filter(word => word && !stopWordsSet.has(word));

        // Step 7: Combine specific interests (multi-word) with the filtered tokens
        const finalInterests = [...specificInterests, ...new Set(filteredTokens)].slice(0, 3);

        return { specificInterests: finalInterests };
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
            },
            lastEdited: new Date() // Set the last edited timestamp
        });

        await newSurveyResponse.save();

        // Update the user's custom interests and lastSurveyDate
        await User.findByIdAndUpdate(userId, {
            $set: {
                customInterests: analysis.specificInterests,
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
            interests: analysis.specificInterests
        });
    } catch (error) {
        console.error("Error analyzing survey response:", error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
