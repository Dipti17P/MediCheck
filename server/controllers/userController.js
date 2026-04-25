const User = require("../models/User");

// GET PROFILE
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select("-password");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// UPDATE PROFILE
exports.updateProfile = async (req, res) => {
  try {
    const { allergies, medicalHistory } = req.body;
    
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (allergies !== undefined) user.allergies = allergies;
    if (medicalHistory !== undefined) user.medicalHistory = medicalHistory;

    await user.save();

    res.json({ message: "Profile updated successfully", user: {
      name: user.name,
      email: user.email,
      allergies: user.allergies,
      medicalHistory: user.medicalHistory
    }});
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
