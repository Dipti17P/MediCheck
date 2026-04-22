const express = require("express");
const router = express.Router();

const { addReminder, getReminders } = require("../controllers/reminderController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/add-reminder", authMiddleware, addReminder);

router.get("/reminders", authMiddleware, getReminders);

module.exports = router;