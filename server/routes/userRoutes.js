const express = require("express");
const router = express.Router();
const { getProfile, updateProfile, updateFcmToken } = require("../controllers/userController");
const authMiddleware = require("../middleware/authMiddleware");

router.get("/profile", authMiddleware, getProfile);
router.put("/profile", authMiddleware, updateProfile);
router.post("/fcm-token", authMiddleware, updateFcmToken);

module.exports = router;
