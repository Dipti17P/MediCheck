const { getDrugInteractionData } = require('../services/drugInteractionService');
const logger = require('../utils/logger');

async function checkInteraction(req, res, next) {
  const { medicines } = req.body;

  if (!medicines || !Array.isArray(medicines) || medicines.length < 2) {
    return res.status(400).json({ success: false, message: 'Send at least 2 medicine names.' });
  }

  try {
    logger.info(`Checking interactions for: ${medicines.join(', ')}`);

    const interactionPromises = [];
    for (let i = 0; i < medicines.length; i++) {
      for (let j = i + 1; j < medicines.length; j++) {
        interactionPromises.push(getDrugInteractionData(medicines[i], medicines[j]));
      }
    }

    const interactions = await Promise.all(interactionPromises);

    // Overall risk = highest risk among all pairs
    const riskOrder = { 'low': 0, 'low-moderate': 1, 'moderate': 2, 'high': 3, 'unknown': 1 };
    const overallRisk = interactions.reduce((highest, interaction) => {
      return (riskOrder[interaction.riskLevel] || 0) > (riskOrder[highest] || 0)
        ? interaction.riskLevel
        : highest;
    }, 'low');

    const requiresDoctorConsult = interactions.some(i => i.requiresDoctorConsult);

    return res.json({
      success: true,
      overallRisk,
      requiresDoctorConsult,
      interactions,
      analyzedBy: 'Gemini AI + OpenFDA',
    });

  } catch (err) {
    logger.error('Interaction check error: %o', err);
    next(err);
  }
}

module.exports = { checkInteraction };