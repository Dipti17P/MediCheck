const express = require("express");
const router = express.Router();
const { getProfile, updateProfile, updateFcmToken, exportData, deleteAccount, changePassword } = require("../controllers/userController");
const authMiddleware = require("../middleware/authMiddleware");
const validate = require("../middleware/validate");
const schemas = require("../validation/schemas");

router.get("/profile", authMiddleware, getProfile);
router.put("/profile", authMiddleware, validate(schemas.updateProfile), updateProfile);
router.post("/fcm-token", authMiddleware, validate(schemas.updateFcmToken), updateFcmToken);
router.post("/change-password", authMiddleware, validate(schemas.changePassword), changePassword);
router.get("/export-data", authMiddleware, exportData);
router.delete("/account", authMiddleware, deleteAccount);

module.exports = router;
