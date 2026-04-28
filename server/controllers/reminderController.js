const Reminder = require("../models/Reminder");
const logger = require("../utils/logger");

// ADD REMINDER
exports.addReminder = async (req, res, next) => {
  try {
    const { medicineName, time, hour, minute, frequency } = req.body;

    const reminder = new Reminder({
      medicineName,
      time,
      hour,
      minute,
      frequency: frequency ? frequency.toLowerCase() : 'daily',
      userId: req.user.userId
    });

    await reminder.save();
    logger.info(`Reminder created: ${medicineName} at ${time} for user ${req.user.userId}`);
    res.status(201).json({ success: true, reminder });

  } catch (error) {
    logger.error("Error creating reminder: %o", error);
    next(error);
  }
};

// GET REMINDERS
exports.getReminders = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const [reminders, total] = await Promise.all([
      Reminder.find({ userId: req.user.userId }).sort({ hour: 1, minute: 1 }).skip(skip).limit(limit),
      Reminder.countDocuments({ userId: req.user.userId })
    ]);

    logger.info(`Fetched ${reminders.length} reminders for user ${req.user.userId} (Page ${page})`);
    res.json({ 
      success: true, 
      reminders,
      pagination: {
        total,
        page,
        limit,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    logger.error("Error fetching reminders: %o", error);
    next(error);
  }
};

// DELETE REMINDER
exports.deleteReminder = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deleted = await Reminder.findOneAndDelete({ _id: id, userId: req.user.userId });
    
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Reminder not found" });
    }

    logger.info(`Reminder deleted: ${id} for user ${req.user.userId}`);
    res.json({ success: true, message: "Reminder deleted successfully" });
  } catch (error) {
    logger.error("Error deleting reminder: %o", error);
    next(error);
  }
};

// UPDATE REMINDER STATUS
exports.updateReminderStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { isTaken } = req.body;

    const reminder = await Reminder.findOne({ _id: id, userId: req.user.userId });
    
    if (!reminder) {
      return res.status(404).json({ success: false, message: "Reminder not found" });
    }

    reminder.isTaken = isTaken;
    await reminder.save();

    logger.info(`Reminder status updated: ${id} for user ${req.user.userId} (isTaken: ${isTaken})`);
    res.json({ success: true, message: "Reminder updated successfully", reminder });
  } catch (error) {
    logger.error("Error updating reminder status: %o", error);
    next(error);
  }
};