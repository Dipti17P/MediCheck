const express = require("express");
const router = express.Router();
const { analyzeSymptoms } = require("../controllers/aiSymptomController");
const auth = require("../middleware/authMiddleware");

router.post("/analyze-symptoms", auth, analyzeSymptoms);

module.exports = router;
