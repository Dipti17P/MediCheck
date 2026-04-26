const { getDrugInteractionData } = require('../services/drugInteractionService');

async function checkInteraction(req, res) {
  const { medicines } = req.body; // ["Aspirin", "Ibuprofen"]

  if (!medicines || !Array.isArray(medicines) || medicines.length < 2) {
    return res.status(400).json({ error: 'Send at least 2 medicine names.' });
  }

  try {
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

    return res.json({ overallRisk, interactions });

  } catch (err) {
    console.error('Interaction check error:', err.message);
    return res.status(500).json({ error: 'Interaction check failed. Try again.' });
  }
}

module.exports = { checkInteraction };