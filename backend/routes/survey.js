const express = require('express');
const { HfInference } = require('@huggingface/inference');
const hf = new HfInference('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');
const User = require('../models/User');
const SurveyResponse = require('../models/surveyResponse');
const Fuse = require('fuse.js');
const natural = require('natural');

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

// Stop words to filter out
const stopWords = new Set([
    "them", "their", "theirs", "that", "this", "these", "those", "and",
    "but", "or", "if", "because", "as", "at", "by", "for", "of", "with",
    "to", "in", "on", "an", "a", "the", "is", "are", "was", "were", "be",
    "being", "been", "have", "has", "had", "do", "does", "did", "not",
    "no", "yes", "all", "any", "some", "one", "two", "three", "four",
    "five", "then", "than", "more", "most", "less", "least", "other",
    "another", "such", "like", "as", "same", "also", "but", "so", "than",
    "too", "very", "just", "only", "still", "even", "back", "here",
    "there", "where", "when", "why", "how", "who", "whom", "which",
    "what", "say", "says", "said", "tell", "tells", "tell", "make",
    "makes", "want", "wants", "need", "needs", "know", "knows", "see",
    "sees", "think", "thinks", "feel", "feels", "work", "works", "use",
    "uses", "find", "finds", "give", "gives", "take", "takes", "go",
    "goes", "come", "comes", "look", "looks", "ask", "asks", "put",
    "puts", "call", "calls", "like", "likes", "love", "loves", "enjoy",
    "enjoys", "hate", "hates", "try", "tries", "start", "starts", "finish",
    "finishes", "play", "plays", "walk", "walks", "run", "runs", "swim",
    "swims", "eat", "eats", "drink", "drinks", "sleep", "sleeps"
]);

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

// Function to extract interests using keyword extraction
async function extractInterests(answers) {
    try {
        const specificInterests = [];
        const combinedAnswers = answers.join(' ');

        const tokenizer = new natural.WordTokenizer();
        const words = tokenizer.tokenize(combinedAnswers.toLowerCase());

        const filteredWords = words.filter(word => {
            return !stopWords.has(word);
        });

        const uniqueInterests = [...new Set(filteredWords)].slice(0, 3);
        specificInterests.push(...uniqueInterests);

        const matchedCategories = fuzzyMatch(specificInterests);

        const classificationResult = await hf.zeroShotClassification({
            model: 'facebook/bart-large-mnli',
            inputs: combinedAnswers,
            parameters: { candidate_labels: categories.slice(0, 10) }
        });

        if (classificationResult && classificationResult.length > 0 && classificationResult[0].labels) {
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
        throw error; // Re-throw to be caught in the route handler
    }
}

// Express.js setup
const router = express.Router();

// Route to analyze survey responses
router.post('/analyze', async (req, res) => {
    const { userId, surveyResponse } = req.body;

    if (!userId || !surveyResponse || !surveyResponse.questions) {
        return res.status(400).json({ error: 'userId and surveyResponse with questions are required.' });
    }

    try {
        const responses = surveyResponse.questions.map(q => q.answer);
        const analysis = await extractInterests(responses);

        // Save the survey response and analysis result to the database
        const newSurveyResponse = new SurveyResponse({
            userId: userId,
            surveyResponse: surveyResponse,
            analysisResult: {
                specificInterests: analysis.specificInterests,
                topCategories: analysis.topCategories,
                matchedCategories: analysis.matchedCategories // Include matched categories
            }
        });

        await newSurveyResponse.save();

        return res.status(200).json({
            interests: analysis.specificInterests,
            topCategories: analysis.topCategories,
            matchedCategories: analysis.matchedCategories
        });
    } catch (error) {
        console.error("Error analyzing survey response:", error);
        return res.status(500).json({ error: 'Internal server error', details: error.message });
    }
});

module.exports = router;
