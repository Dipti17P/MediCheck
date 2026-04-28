const User = require("../models/User");
const Medicine = require("../models/Medicine");
const Reminder = require("../models/Reminder");
const logger = require("../utils/logger");
const bcrypt = require("bcryptjs");

// GET PROFILE
exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.userId).select("-password");
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }
    res.json({ success: true, user });
  } catch (error) {
    logger.error("Error fetching profile: %o", error);
    next(error);
  }
};

// CHANGE PASSWORD
exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: "Current and new passwords are required" });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: "Incorrect current password" });
    }

    // Hash and save new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    logger.info(`Password changed for user: ${req.user.userId}`);
    res.json({ success: true, message: "Password updated successfully" });
  } catch (error) {
    logger.error("Error changing password: %o", error);
    next(error);
  }
};

// UPDATE PROFILE
exports.updateProfile = async (req, res, next) => {
  try {
    const { allergies, medicalHistory } = req.body;
    
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    if (allergies !== undefined) user.allergies = allergies;
    if (medicalHistory !== undefined) user.medicalHistory = medicalHistory;

    await user.save();
    logger.info(`Profile updated for user: ${req.user.userId}`);

    res.json({ 
      success: true, 
      message: "Profile updated successfully", 
      user: {
        name: user.name,
        email: user.email,
        allergies: user.allergies,
        medicalHistory: user.medicalHistory
      }
    });
  } catch (error) {
    logger.error("Error updating profile: %o", error);
    next(error);
  }
};

// SAVE FCM TOKEN
exports.updateFcmToken = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    await User.findByIdAndUpdate(req.user.userId, { fcmToken });
    logger.info(`FCM Token updated for user: ${req.user.userId}`);
    res.json({ success: true, message: "FCM Token updated" });
  } catch (error) {
    logger.error("Error updating FCM token: %o", error);
    next(error);
  }
};

// EXPORT ALL USER DATA (GDPR)
exports.exportData = async (req, res, next) => {
  try {
    const [user, medicines, reminders] = await Promise.all([
      User.findById(req.user.userId).select("-password"),
      Medicine.find({ userId: req.user.userId }),
      Reminder.find({ userId: req.user.userId })
    ]);

    const dataDump = {
      profile: user,
      medicines,
      reminders,
      exportedAt: new Date().toISOString()
    };

    logger.info(`Data export generated for user: ${req.user.userId}`);
    res.json({ success: true, data: dataDump });
  } catch (error) {
    logger.error("Error exporting data: %o", error);
    next(error);
  }
};

// DELETE ACCOUNT (GDPR)
exports.deleteAccount = async (req, res, next) => {
  try {
    await Promise.all([
      Medicine.deleteMany({ userId: req.user.userId }),
      Reminder.deleteMany({ userId: req.user.userId }),
      User.findByIdAndDelete(req.user.userId)
    ]);

    logger.info(`Account and all data deleted for user: ${req.user.userId}`);
    res.json({ success: true, message: "Account and all associated data permanently deleted" });
  } catch (error) {
    logger.error("Error deleting account: %o", error);
    next(error);
  }
};
