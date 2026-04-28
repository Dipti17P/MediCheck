const express = require("express");
const router = express.Router();
const { signup, login, refreshToken, resetPassword } = require("../controllers/authController");
const validate = require("../middleware/validate");
const schemas = require("../validation/schemas");

router.post("/signup", validate(schemas.signup), signup);
router.post("/login", validate(schemas.login), login);
router.post("/refresh-token", validate(schemas.refreshToken), refreshToken);
router.post("/reset-password", validate(schemas.resetPassword), resetPassword);

module.exports = router;