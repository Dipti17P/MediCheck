const express = require('express');
const rateLimit = require('express-rate-limit');
const { checkInteraction } = require('../controllers/interactionController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

const limiter = rateLimit({
  windowMs: 60 * 1000,  // 1 minute
  max: 20,              // 20 requests per user per minute
  message: { error: 'Too many requests. Please wait.' }
});

router.post('/check-interaction', authMiddleware, limiter, checkInteraction);

module.exports = router;