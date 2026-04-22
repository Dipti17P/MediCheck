const express = require("express");
const router = express.Router();

const { checkInteraction } = require("../controllers/interactionController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/check-interaction", authMiddleware, checkInteraction);

module.exports = router;