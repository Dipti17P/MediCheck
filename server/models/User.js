const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },

  email: {
    type: String,
    required: true,
    unique: true
  },

  password: {
    type: String,
    required: true
  },

  age: Number,

  allergies: [String],
  
  medicalHistory: String,
  
  fcmToken: String,
  
  refreshToken: String
});

module.exports = mongoose.model("User", userSchema);