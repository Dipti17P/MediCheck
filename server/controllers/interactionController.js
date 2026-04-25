const { getRxCUI } = require('../services/rxNormService');
const { getDrugWarnings, extractInteractions } = require('../services/openFdaService');

function scoreRisk(interactionText) {
  const text = interactionText.join(' ').toLowerCase();

  const highKeywords = [
    'fatal',
    'death',
    'severe',
    'serious',
    'bleeding',
    'hemorrhage',
    'contraindicated',
    'avoid',
    'heart attack',
    'stroke'
  ];

  const mediumKeywords = [
    'monitor',
    'adjust dose',
    'increase',
    'decrease',
    'caution',
    'reduce dose'
  ];

  const lowKeywords = [
    'mild',
    'temporary',
    'minor',
    'dizziness'
  ];

  if (highKeywords.some(k => text.includes(k))) {
    return 'HIGH';
  }

  if (mediumKeywords.some(k => text.includes(k))) {
    return 'MEDIUM';
  }

  if (lowKeywords.some(k => text.includes(k))) {
    return 'LOW';
  }

  return 'LOW';
}

async function checkInteraction(req, res) {
  const { medicines } = req.body; // ["Aspirin", "Ibuprofen"]

  if (!medicines || medicines.length < 2) {
    return res.status(400).json({ error: 'Send at least 2 medicine names.' });
  }

  try {
    // 1. Resolve all names → RxCUI codes in parallel
    const rxcuiList = await Promise.all(
      medicines.map(name => getRxCUI(name))
    );

    // 2. Fetch FDA label data for each drug in parallel
    const labelDataList = await Promise.all(
      rxcuiList.map((rxcui, index) => getDrugWarnings(rxcui, medicines[index]))
    );

    // 3. Build interaction pairs
    const interactions = [];

    for (let i = 0; i < medicines.length; i++) {
      for (let j = i + 1; j < medicines.length; j++) {
        const drug1 = medicines[i];
        const drug2 = medicines[j];

        // Combine both drugs' interaction sections
        const sentences1 = extractInteractions(labelDataList[i]);
        const sentences2 = extractInteractions(labelDataList[j]);
        const combined = [...sentences1, ...sentences2];

        const riskLevel = scoreRisk(combined, drug1, drug2);
        const relevant = combined.filter(s =>
          s.toLowerCase().includes(drug1.toLowerCase()) ||
          s.toLowerCase().includes(drug2.toLowerCase())
        );

        interactions.push({
          drug1,
          drug2,
          riskLevel,
          warnings: relevant.length > 0 ? relevant : combined.slice(0, 2),
          source: 'OpenFDA'
        });
      }
    }

    return res.json({ interactions });

  } catch (err) {
    console.error('Interaction check error:', err.message);

    if (err.message.includes('not found in RxNorm')) {
      return res.status(404).json({ error: err.message });
    }
    return res.status(500).json({ error: 'Interaction check failed. Try again.' });
  }
}

module.exports = { checkInteraction };