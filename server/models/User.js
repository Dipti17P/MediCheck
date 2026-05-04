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
  
  weight: Number,

  renalStatus: {
    type: String,
    enum: ['normal', 'mild_impairment', 'moderate_impairment', 'severe_impairment', 'dialysis', 'unknown'],
    default: 'unknown'
  },

  hepaticStatus: {
    type: String,
    enum: ['normal', 'mild_impairment', 'moderate_impairment', 'severe_impairment', 'unknown'],
    default: 'unknown'
  },
  
  fcmToken: String,
  
  refreshToken: String
});

module.exports = mongoose.model("User", userSchema);