const mongoose = require('mongoose');

const surveyResponseSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'User',
    },
    surveyResponse: {
      type: Object, // Store structured survey data
      required: true,
    },
    analysisResult: {
      specificInterests: {
        type: [String],
        default: [], // Default to empty array
      },
      topCategories: {
        type: [String],
        default: [], // Default to empty array
      },
      tfidfTerms: {
        type: [String],
        default: [], // Store TF-IDF extracted terms
      },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('SurveyResponse', surveyResponseSchema);
