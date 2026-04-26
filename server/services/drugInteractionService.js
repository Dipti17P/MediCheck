const axios = require('axios');
const { createClient } = require('redis');

// Initialize Redis client
const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://127.0.0.1:6379'
});

let isRedisConnected = false;

redisClient.on('error', (err) => {
  console.log('Redis Client Error:', err.message);
  isRedisConnected = false;
});

redisClient.on('connect', () => {
  console.log('Redis Client Connected');
  isRedisConnected = true;
});

redisClient.connect().catch((err) => {
  console.log('Failed to connect to Redis:', err.message);
});

// Brand to generic mapper
const brandToGeneric = {
  'crocin': 'paracetamol',
  'dolo': 'paracetamol',
  'ecosprin': 'aspirin',
  'combiflam': 'ibuprofen',
  'calpol': 'paracetamol',
  'allegra': 'fexofenadine',
  'augmentin': 'amoxicillin',
  'azithral': 'azithromycin',
  'pan': 'pantoprazole',
  'pantocid': 'pantoprazole',
  'zantac': 'ranitidine',
  'aciloc': 'ranitidine',
  'okacet': 'cetirizine',
  'avomine': 'promethazine',
  'tylenol': 'paracetamol',
  'advil': 'ibuprofen',
  'motrin': 'ibuprofen',
  'aleve': 'naproxen'
};

function normalizeDrugName(name) {
  const lowerName = name.toLowerCase().trim();
  return brandToGeneric[lowerName] || lowerName;
}

async function getDrugInteractionData(drugA, drugB) {
  const d1 = normalizeDrugName(drugA);
  const d2 = normalizeDrugName(drugB);
  
  // Sort alphabetically to maintain consistent cache keys
  const [drug1, drug2] = [d1, d2].sort();

  const cacheKey = `interaction:${drug1}:${drug2}`;
  
  if (isRedisConnected) {
    try {
      const cachedResult = await redisClient.get(cacheKey);
      if (cachedResult) {
        return JSON.parse(cachedResult);
      }
    } catch (err) {
      console.error('Redis get error:', err.message);
    }
  }

  let warning = "No specific official warnings found.";
  let labelMention = false;
  let coReportCount = 0;

  try {
    // 1. Check drug labels for interactions
    const labelQuery = `(openfda.substance_name:"${drug1}" AND drug_interactions:"${drug2}") OR (openfda.substance_name:"${drug2}" AND drug_interactions:"${drug1}")`;
    const labelUrl = `https://api.fda.gov/drug/label.json?search=${encodeURIComponent(labelQuery)}&limit=1`;
    
    const labelRes = await axios.get(labelUrl).catch(e => {
       if (e.response && e.response.status === 404) return { data: null };
       throw e;
    });

    if (labelRes.data && labelRes.data.results && labelRes.data.results.length > 0) {
      labelMention = true;
      const result = labelRes.data.results[0];
      if (result.drug_interactions && result.drug_interactions.length > 0) {
        const text = result.drug_interactions[0];
        const sentences = text.split(/(?<=[.!?])\s+/);
        const relevantSentences = sentences.filter(s => 
          s.toLowerCase().includes(drug1) || s.toLowerCase().includes(drug2)
        );
        if (relevantSentences.length > 0) {
          warning = relevantSentences.join(' ');
        } else {
          warning = text.substring(0, 200) + (text.length > 200 ? '...' : '');
        }
      }
    }
  } catch (err) {
    console.error('FDA Label API Error:', err.message);
  }

  try {
    // 2. Check adverse event co-reports
    const eventQuery = `patient.drug.medicinalproduct:"${drug1}" AND patient.drug.medicinalproduct:"${drug2}"`;
    const eventUrl = `https://api.fda.gov/drug/event.json?search=${encodeURIComponent(eventQuery)}&limit=1`;
    
    const eventRes = await axios.get(eventUrl).catch(e => {
       if (e.response && e.response.status === 404) return { data: { meta: { results: { total: 0 } } } };
       throw e;
    });

    if (eventRes.data && eventRes.data.meta && eventRes.data.meta.results) {
      coReportCount = eventRes.data.meta.results.total;
    }
  } catch (err) {
    console.error('FDA Event API Error:', err.message);
  }

  // Calculate risk level based on signals
  let riskLevel = 'low';
  
  if (labelMention) {
    const warningLower = warning.toLowerCase();
    if (warningLower.includes('fatal') || warningLower.includes('contraindicated') || warningLower.includes('avoid') || warningLower.includes('severe')) {
      riskLevel = 'high';
    } else {
      riskLevel = 'moderate';
    }
  } else if (coReportCount > 500) {
    riskLevel = 'moderate';
  } else if (coReportCount > 50) {
    riskLevel = 'low-moderate';
  }

  const result = {
    drug1: drugA,
    drug2: drugB,
    riskLevel,
    warning,
    coReportCount,
    labelMention
  };

  if (isRedisConnected) {
    try {
      // Cache for 24 hours (86400 seconds)
      await redisClient.setEx(cacheKey, 86400, JSON.stringify(result));
    } catch (err) {
      console.error('Redis set error:', err.message);
    }
  }

  return result;
}

module.exports = {
  getDrugInteractionData,
  normalizeDrugName
};
