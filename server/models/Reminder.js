const mongoose = require("mongoose");

const reminderSchema = new mongoose.Schema({

  medicineName: {
    type: String,
    required: true
  },

  time: {
    type: String,
    required: true
  },

  frequency: {
    type: String,
    default: 'daily'
  },

  isTaken: {
    type: Boolean,
    default: false
  },

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  }

});

module.exports = mongoose.model("Reminder", reminderSchema);