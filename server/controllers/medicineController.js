const Medicine = require("../models/Medicine");


// ADD MEDICINE
exports.addMedicine = async (req, res) => {

  try {

    const { name, uses, sideEffects } = req.body;

    const medicine = new Medicine({
      name,
      uses,
      sideEffects,
      userId: req.user.userId
    });

    await medicine.save();

    res.json({
      message: "Medicine added successfully",
      medicine
    });

  } catch (error) {

    res.status(500).json({ error: error.message });

  }

};


// GET USER MEDICINES
exports.getMedicines = async (req, res) => {

  try {

    const medicines = await Medicine.find({
      userId: req.user.userId
    });

    res.json(medicines);

  } catch (error) {

    res.status(500).json({ error: error.message });

  }

};