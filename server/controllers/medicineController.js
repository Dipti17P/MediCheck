const Medicine = require("../models/Medicine");
const logger = require("../utils/logger");

// ADD MEDICINE
exports.addMedicine = async (req, res, next) => {
  try {
    const { name, uses, sideEffects } = req.body;

    const medicine = new Medicine({
      name,
      uses,
      sideEffects,
      userId: req.user.userId
    });

    await medicine.save();
    logger.info(`Medicine saved to DB: ${name} for user ${req.user.userId}`);

    res.json({
      success: true,
      message: "Medicine added successfully",
      medicine
    });

  } catch (error) {
    logger.error("Error adding medicine: %o", error);
    next(error);
  }
};

// GET USER MEDICINES
exports.getMedicines = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const [medicines, total] = await Promise.all([
      Medicine.find({ userId: req.user.userId }).skip(skip).limit(limit),
      Medicine.countDocuments({ userId: req.user.userId })
    ]);

    logger.info(`Found ${medicines.length} medicines for user: ${req.user.userId} (Page ${page})`);

    res.json({
      success: true,
      medicines,
      pagination: {
        total,
        page,
        limit,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    logger.error("Error fetching medicines: %o", error);
    next(error);
  }
};