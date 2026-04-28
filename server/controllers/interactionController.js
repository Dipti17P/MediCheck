const { getDrugInteractionData } = require('../services/drugInteractionService');
const logger = require('../utils/logger');

async function checkInteraction(req, res, next) {
  const { medicines } = req.body; // ["Aspirin", "Ibuprofen"]

  // Validation is now handled by middleware, but we can keep a safety check or remove it
  if (!medicines || !Array.isArray(medicines) || medicines.length < 2) {
    return res.status(400).json({ success: false, message: 'Send at least 2 medicine names.' });
  }

  try {
    logger.info(`Checking interactions for: ${medicines.join(', ')}`);
    const interactions = [];

    // Check all drug pairs if more than 2 medicines are sent
    for (let i = 0; i < medicines.length; i++) {
      for (let j = i + 1; j < medicines.length; j++) {
        const result = await getDrugInteractionData(medicines[i], medicines[j]);
        interactions.push(result);
      }
    }

    // Calculate overall risk
    let overallRisk = 'low';
    const hasHigh = interactions.some(i => i.riskLevel === 'high');
    const hasModerate = interactions.some(i => i.riskLevel === 'moderate');
    const hasLowModerate = interactions.some(i => i.riskLevel === 'low-moderate');

    if (hasHigh) {
      overallRisk = 'high';
    } else if (hasModerate) {
      overallRisk = 'moderate';
    } else if (hasLowModerate) {
      overallRisk = 'low-moderate';
    }

    return res.json({ success: true, overallRisk, interactions });

  } catch (err) {
    logger.error('Interaction check error: %o', err);
    next(err);
  }
}

module.exports = { checkInteraction };