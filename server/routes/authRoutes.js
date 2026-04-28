const express = require("express");
const router = express.Router();
const { signup, login, refreshToken } = require("../controllers/authController");
const validate = require("../middleware/validate");
const schemas = require("../validation/schemas");

router.post("/signup", validate(schemas.signup), signup);
router.post("/login", validate(schemas.login), login);
router.post("/refresh-token", validate(schemas.refreshToken), refreshToken);

module.exports = router;