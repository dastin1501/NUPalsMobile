    const express = require('express');
    const { HfInference } = require('@huggingface/inference');
    const hf = new HfInference('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');
    const User = require('../models/User');
    const SurveyResponse = require('../models/surveyResponse');
    const Fuse = require('fuse.js');
    const natural = require('natural');
    const Log = require('../models/log');
    const MultiWordKeyword = require('../models/MultiWordKeyword');
    const Stopword = require('../models/Stopword');
    const { GroupChat } = require('../models/GroupChat');


    async function extractInterests(answers) {
        try {
            const specificInterests = [];
            const combinedAnswers = answers.join(' ').toLowerCase();

            // Fetch multi-word keywords from the database
            const multiWordKeywords = await MultiWordKeyword.find().then(keywords => keywords.map(k => k.keyword.toLowerCase()));

            // Fetch stopwords from the database
            const stopwordsFromDb = await Stopword.find();
            const stopWordsSet = new Set(stopwordsFromDb.map(stopword => stopword.word.toLowerCase()));

            // Check if multi-word keywords are present in combined answers
            for (const keyword of multiWordKeywords) {
                if (combinedAnswers.includes(keyword)) {
                    specificInterests.push(keyword); // Add multi-word keywords directly
                }
            }

            // Split the combined answers into words, excluding multi-word keywords
            const singleWords = combinedAnswers.split(/[\s,]+/);

            // Collect specific interests from single words
            singleWords.forEach(word => {
                if (!stopWordsSet.has(word) && !specificInterests.includes(word)) {
                    specificInterests.push(word);
                }
            });

            // Deduplicate and limit to top 3 specific interests
            const uniqueInterests = [...new Set(specificInterests)].slice(0, 3);

            const matchedCategories = fuzzyMatch(uniqueInterests);

            const classificationResult = await hf.zeroShotClassification({
                model: 'facebook/bart-large-mnli',
                inputs: combinedAnswers,
                parameters: { candidate_labels: categories.slice(0, 10) }
            });

            if (classificationResult && classificationResult[0]?.labels) {
                const topCategories = classificationResult[0].labels.slice(0, 3);
                return {
                    specificInterests: uniqueInterests,
                    topCategories,
                    matchedCategories
                };
            } else {
                throw new Error("Classification result is undefined or does not contain labels.");
            }
        } catch (error) {
            console.error("Error in extractInterests:", error);
            throw error;
        }
    }


    // Initialize the tagger
    const tagger = new natural.BrillPOSTagger();

    // Generalized and expanded categories
    const categories = [
        "Sports", "Technology", "Arts", "Health & Wellness", "Business", "Education",
        "Travel", "Environment", "Personal Development", "Food & Cooking", "Gaming",
        "Finance", "Music", "Science", "Literature", "Fashion", "Social Issues",
        "History", "Mathematics", "Physics", "Biology", "Chemistry", "Engineering",
        "Computer Science", "Psychology", "Sociology", "Philosophy", "Economics",
        "Political Science", "Linguistics", "Environmental Science", "Statistics",
        "Art History", "Music Theory"
    ];

    // Fuzzy matching configuration
    const fuseOptions = {
        includeScore: true,
        threshold: 0.4,
        keys: ["name"]
    };

    // Function to perform fuzzy matching
    function fuzzyMatch(interests) {
        const fuse = new Fuse(categories.map(cat => ({ name: cat })), fuseOptions);
        const matches = [];

        interests.forEach(interest => {
            const result = fuse.search(interest);
            if (result.length > 0) {
                matches.push(result[0].item.name); // Get the top match
            }
        });

        return [...new Set(matches)]; // Remove duplicates
    }

    async function extractInterests(answers) {
        try {
            const specificInterests = [];
            const combinedAnswers = answers.join(' ').toLowerCase();

            // Fetch multi-word keywords from the database
            const multiWordKeywords = await MultiWordKeyword.find().then(keywords => keywords.map(k => k.keyword.toLowerCase()));

            // Fetch stopwords from the database
            const stopwordsFromDb = await Stopword.find();
            const stopWordsSet = new Set(stopwordsFromDb.map(stopword => stopword.word.toLowerCase()));

            // Regex to remove non-alphabetic characters and normalize words
            const normalizeWord = word => word.replace(/[^a-z]/g, '');

            // Check if multi-word keywords are present in combined answers
            for (const keyword of multiWordKeywords) {
                if (combinedAnswers.includes(keyword)) {
                    specificInterests.push(keyword); // Add multi-word keywords directly
                }
            }

            // Split the combined answers into words, normalize them, and exclude multi-word keywords
            const singleWords = combinedAnswers.split(/[\s,]+/).map(normalizeWord).filter(Boolean);

            // Collect specific interests from single words
            singleWords.forEach(word => {
                if (!stopWordsSet.has(word) && !specificInterests.includes(word)) {
                    specificInterests.push(word);
                }
            });

            // Deduplicate and limit to top 3 specific interests
            const uniqueInterests = [...new Set(specificInterests)].slice(0, 3);

            const matchedCategories = fuzzyMatch(uniqueInterests);

            const classificationResult = await hf.zeroShotClassification({
                model: 'facebook/bart-large-mnli',
                inputs: combinedAnswers,
                parameters: { candidate_labels: categories.slice(0, 10) }
            });

            if (classificationResult && classificationResult[0]?.labels) {
                const topCategories = classificationResult[0].labels.slice(0, 3);
                return {
                    specificInterests: uniqueInterests,
                    topCategories,
                    matchedCategories
                };
            } else {
                throw new Error("Classification result is undefined or does not contain labels.");
            }
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
