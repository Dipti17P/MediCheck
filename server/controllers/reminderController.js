const Reminder = require("../models/Reminder");


// ADD REMINDER
exports.addReminder = async (req, res) => {

  try {
    const { medicineName, time, frequency } = req.body;

    const reminder = new Reminder({
      medicineName,
      time,
      frequency: frequency || 'daily',
      userId: req.user.userId
    });

    await reminder.save();

    res.json({
      message: "Reminder added successfully",
      reminder
    });

  } catch (error) {

    res.status(500).json({
      error: error.message
    });

  }

};



// GET REMINDERS
exports.getReminders = async (req, res) => {

  try {

    const reminders = await Reminder.find({
      userId: req.user.userId
    });

    res.json(reminders);

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};

// UPDATE REMINDER STATUS
exports.updateReminderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isTaken } = req.body;

    const reminder = await Reminder.findOne({ _id: id, userId: req.user.userId });
    
    if (!reminder) {
      return res.status(404).json({ message: "Reminder not found" });
    }

    reminder.isTaken = isTaken;
    await reminder.save();

    res.json({ message: "Reminder updated successfully", reminder });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};