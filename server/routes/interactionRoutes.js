const express = require("express");
const router = express.Router();
const { checkInteraction } = require("../controllers/interactionController");
const auth = require("../middleware/authMiddleware");
const validate = require("../middleware/validate");
const schemas = require("../validation/schemas");

// Apply validation to interaction check
router.post("/check-interaction", auth, validate(schemas.checkInteraction), checkInteraction);

module.exports = router;