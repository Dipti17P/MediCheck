const { checkSymptoms } = require("../services/aiSymptomService");
const User = require("../models/User");
const logger = require("../utils/logger");

exports.analyzeSymptoms = async (req, res, next) => {
  try {
    const { symptoms } = req.body;
    const userId = req.user.userId;

    const user = await User.findById(userId);
    
    logger.info(`AI Symptom Check requested by user: ${userId}`);
    
    const analysis = await checkSymptoms(symptoms, {
      age: user.age,
      allergies: user.allergies,
      medicalHistory: user.medicalHistory
    });

    res.json({
      success: true,
      analysis
    });
  } catch (error) {
    next(error);
  }
};
