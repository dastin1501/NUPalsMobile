const express = require('express');
const router = express.Router();
const Post = require('../models/post');

// Route to get all posts
router.get('/', async (req, res) => {
  try {
    const posts = await Post.find().populate('userId', 'email'); // Populate userId with email
    res.status(200).json(posts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Route to get a single post with its details
router.get('/:id', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id).populate('userId', 'email');
    if (!post) return res.status(404).json({ message: 'Post not found' });
    res.status(200).json(post);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Route to like a post
router.post('/:id/like', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    // Add user to likes array if they haven't liked the post already
    if (!post.likes.includes(req.body.userId)) {
      post.likes.push(req.body.userId);
    }

    await post.save();
    res.status(200).json({ message: 'Post liked' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Route to add a comment to a post
router.post('/:id/comment', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    const comment = {
      userId: req.body.userId,
      text: req.body.text
    };

    post.comments.push(comment);
    await post.save();
    res.status(200).json({ message: 'Comment added' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
