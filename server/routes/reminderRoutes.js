const express = require("express");
const router = express.Router();

const { addReminder, getReminders, updateReminderStatus, deleteReminder } = require("../controllers/reminderController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/add-reminder", authMiddleware, addReminder);
router.get("/reminders", authMiddleware, getReminders);
router.delete("/reminders/:id", authMiddleware, deleteReminder);
router.put("/update-reminder/:id", authMiddleware, updateReminderStatus);

module.exports = router;