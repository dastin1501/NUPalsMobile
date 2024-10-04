const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const postSchema = new Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  content: {
    type: String,
    required: true
  },
  media: {
    type: String // base64 image string
  },
  likes: {
    type: [mongoose.Schema.Types.ObjectId], // Array of userIds who liked the post
    default: []
  },
  comments: [
    {
      userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      text: { type: String, required: true }
    }
  ]
}, { timestamps: true });

const Post = mongoose.model('Post', postSchema);

module.exports = Post;
