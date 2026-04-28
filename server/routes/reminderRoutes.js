const express = require("express");
const router = express.Router();
const { addReminder, getReminders, updateReminderStatus, deleteReminder } = require("../controllers/reminderController");
const authMiddleware = require("../middleware/authMiddleware");
const validate = require("../middleware/validate");
const schemas = require("../validation/schemas");

router.post("/add-reminder", authMiddleware, validate(schemas.createReminder), addReminder);
router.get("/reminders", authMiddleware, getReminders);
router.delete("/reminders/:id", authMiddleware, deleteReminder);
router.put("/update-reminder/:id", authMiddleware, updateReminderStatus);

module.exports = router;