const mongoose = require("mongoose");

const medicineSchema = new mongoose.Schema({

  name: {
    type: String,
    required: true
  },

  uses: String,

  sideEffects: [String],

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    index: true
  }

});

module.exports = mongoose.model("Medicine", medicineSchema);