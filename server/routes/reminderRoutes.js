const express = require("express");
const router = express.Router();

const { addReminder, getReminders, updateReminderStatus } = require("../controllers/reminderController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/add-reminder", authMiddleware, addReminder);

router.get("/reminders", authMiddleware, getReminders);

router.put("/update-reminder/:id", authMiddleware, updateReminderStatus);

module.exports = router;