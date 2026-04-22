const Reminder = require("../models/Reminder");


// ADD REMINDER
exports.addReminder = async (req, res) => {

  try {

    const { medicineName, time } = req.body;

    const reminder = new Reminder({
      medicineName,
      time,
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