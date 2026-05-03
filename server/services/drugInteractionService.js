const axios = require('axios');
const { createClient } = require('redis');
const NodeCache = require('node-cache');
const { GoogleGenerativeAI } = require("@google/generative-ai");
const logger = require('../utils/logger');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const localCache = new NodeCache({ stdTTL: 86400 });

const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://127.0.0.1:6379',
  socket: {
    reconnectStrategy: (retries) => {
      if (retries > 5) {
        logger.warn('Redis reconnection limit reached. Falling back to local cache permanently.');
        return false;
      }
      return Math.min(retries * 50, 1000);
    }
  }
});

let isRedisConnected = false;
let redisErrorLogged = false;

redisClient.on('error', (err) => {
  if (!redisErrorLogged) {
    logger.error('Redis Client Error: %s. Ensuring graceful fallback.', err.message);
    redisErrorLogged = true;
  }
  isRedisConnected = false;
});

redisClient.on('connect', () => {
  logger.info('Redis Client Connected');
  isRedisConnected = true;
  redisErrorLogged = false;
});

redisClient.connect().catch(() => {});

// Brand to generic mapper
const brandToGeneric = {
  'crocin': 'paracetamol', 'dolo': 'paracetamol', 'calpol': 'paracetamol',
  'tylenol': 'paracetamol', 'ecosprin': 'aspirin', 'combiflam': 'ibuprofen',
  'advil': 'ibuprofen', 'motrin': 'ibuprofen', 'aleve': 'naproxen',
  'allegra': 'fexofenadine', 'augmentin': 'amoxicillin',
  'azithral': 'azithromycin', 'pan': 'pantoprazole',
  'pantocid': 'pantoprazole', 'zantac': 'ranitidine',
  'aciloc': 'ranitidine', 'okacet': 'cetirizine',
  'avomine': 'promethazine', 'glucophage': 'metformin',
  'lipitor': 'atorvastatin', 'prilosec': 'omeprazole',
  'zithromax': 'azithromycin', 'amoxil': 'amoxicillin',
  'brufen': 'ibuprofen', 'voltaren': 'diclofenac',
  'crestor': 'rosuvastatin', 'norvasc': 'amlodipine',
};

function normalizeDrugName(name) {
  const lower = name.toLowerCase().trim()
    .replace(/\s*\d+\s*mg$/i, '')   // strip "500mg"
    .replace(/\s*\d+\s*mcg$/i, '')  // strip "25mcg"
    .trim();
  return brandToGeneric[lower] || lower;
}

// ── Step 1: Fetch FDA co-report count ────────────────────────────────────────
async function getFdaCoReportCount(drug1, drug2) {
  try {
    const q = `patient.drug.medicinalproduct:"${drug1}"+AND+patient.drug.medicinalproduct:"${drug2}"`;
    const url = `https://api.fda.gov/drug/event.json?search=${encodeURIComponent(q)}&limit=1`;
    const res = await axios.get(url, { timeout: 5000 });
    return res.data?.meta?.results?.total || 0;
  } catch {
    return 0;
  }
}

// ── Step 2: Fetch FDA label warnings ─────────────────────────────────────────
async function getFdaLabelWarning(drug1, drug2) {
  try {
    const queries = [
      `openfda.substance_name:"${drug1}"`,
      `openfda.generic_name:"${drug1}"`,
    ];

    for (const q of queries) {
      const url = `https://api.fda.gov/drug/label.json?search=${encodeURIComponent(q)}&limit=1`;
      const res = await axios.get(url, { timeout: 5000 });
      const result = res.data?.results?.[0];
      if (!result) continue;

      const fields = [
        result.drug_interactions?.[0],
        result.warnings_and_cautions?.[0],
        result.warnings?.[0],
        result.boxed_warning?.[0],
        result.precautions?.[0],
      ].filter(Boolean).join(' ');

      if (fields.toLowerCase().includes(drug2.toLowerCase())) {
        // Extract the sentence mentioning drug2
        const sentences = fields.split(/(?<=[.!?])\s+/);
        const relevant = sentences.filter(s =>
          s.toLowerCase().includes(drug2.toLowerCase())
        );
        if (relevant.length > 0) return relevant.slice(0, 3).join(' ');
      }
    }
  } catch {
    // FDA API unavailable, Gemini will handle it
  }
  return null;
}

// ── Step 3 (fallback): Static clinical knowledge base ────────────────────────
// Used when ALL Gemini models are quota-exhausted.
// Keys are alphabetically sorted: "drug1:drug2"
const STATIC_INTERACTIONS = {
  'aspirin:ibuprofen': {
    riskLevel: 'moderate',
    mechanism: 'Ibuprofen competes with aspirin for COX-1 binding sites, reducing aspirin\'s antiplatelet effect.',
    clinicalEffect: 'Reduced cardioprotective effect of low-dose aspirin; increased GI bleeding risk.',
    severity: 'Moderate — clinically significant for patients on aspirin for heart protection.',
    management: 'Take aspirin at least 30 minutes before ibuprofen, or use paracetamol for pain instead.',
    warning: 'Taking ibuprofen with aspirin can block aspirin\'s protective effect on your heart. Use paracetamol for pain relief if you are on daily aspirin.',
    requiresDoctorConsult: true, commonCombination: true,
    alternatives: 'Paracetamol (acetaminophen) is a safer pain reliever for patients on low-dose aspirin.',
  },
  'aspirin:paracetamol': {
    riskLevel: 'low',
    mechanism: 'Different mechanisms of action with minimal pharmacokinetic overlap.',
    clinicalEffect: 'Generally safe combination; minor additive analgesic effect.',
    severity: 'Low — no significant interaction expected at standard doses.',
    management: 'Can be used together at standard doses. Avoid prolonged combined use without medical advice.',
    warning: 'Aspirin and paracetamol are generally safe to take together at normal doses. Avoid long-term use of this combination without consulting your doctor.',
    requiresDoctorConsult: false, commonCombination: true, alternatives: null,
  },
  'aspirin:warfarin': {
    riskLevel: 'high',
    mechanism: 'Aspirin inhibits platelet aggregation and can displace warfarin from plasma proteins, increasing anticoagulant effect.',
    clinicalEffect: 'Significantly increased bleeding risk, including internal bleeding and hemorrhagic stroke.',
    severity: 'High — potentially life-threatening combination.',
    management: 'Avoid unless explicitly prescribed together by a cardiologist. Monitor INR closely.',
    warning: 'This is a dangerous combination that greatly increases your risk of serious bleeding. Do not take aspirin while on warfarin without direct medical supervision.',
    requiresDoctorConsult: true, commonCombination: false,
    alternatives: 'Paracetamol is preferred for pain relief in patients on warfarin.',
  },
  'ibuprofen:paracetamol': {
    riskLevel: 'low',
    mechanism: 'Different mechanisms (COX inhibition vs central analgesia) with complementary action.',
    clinicalEffect: 'Safe and effective combination; often used intentionally for better pain control.',
    severity: 'Low — well-established safe combination.',
    management: 'Can be alternated or combined at standard doses for enhanced pain relief.',
    warning: 'Ibuprofen and paracetamol are safe to take together and are often recommended by doctors for better pain control.',
    requiresDoctorConsult: false, commonCombination: true, alternatives: null,
  },
  'ibuprofen:warfarin': {
    riskLevel: 'high',
    mechanism: 'NSAIDs inhibit platelet function and may displace warfarin from protein binding sites, increasing free warfarin levels.',
    clinicalEffect: 'Elevated INR, increased bleeding risk including GI hemorrhage.',
    severity: 'High — avoid combination.',
    management: 'Use paracetamol for pain. If NSAID is essential, monitor INR very closely.',
    warning: 'Taking ibuprofen with warfarin significantly raises your risk of dangerous bleeding. Use paracetamol for pain instead and consult your doctor.',
    requiresDoctorConsult: true, commonCombination: false,
    alternatives: 'Paracetamol is the recommended analgesic for patients on warfarin.',
  },
  'metformin:ibuprofen': {
    riskLevel: 'low-moderate',
    mechanism: 'NSAIDs may reduce renal blood flow, decreasing metformin clearance and increasing lactic acidosis risk.',
    clinicalEffect: 'Possible reduced kidney function leading to metformin accumulation.',
    severity: 'Low-Moderate — occasional use is usually fine; avoid prolonged NSAID use.',
    management: 'Stay well hydrated. Avoid long-term NSAID use. Monitor kidney function.',
    warning: 'Regular use of ibuprofen with metformin may affect your kidneys. Use paracetamol for pain when possible and stay hydrated.',
    requiresDoctorConsult: true, commonCombination: true,
    alternatives: 'Paracetamol is preferred for pain in patients on metformin.',
  },
  'atorvastatin:clarithromycin': {
    riskLevel: 'high',
    mechanism: 'Clarithromycin inhibits CYP3A4, the enzyme that metabolizes atorvastatin, causing toxic drug accumulation.',
    clinicalEffect: 'Markedly elevated atorvastatin levels leading to risk of myopathy and rhabdomyolysis.',
    severity: 'High — potentially serious muscle damage.',
    management: 'Temporarily stop atorvastatin during clarithromycin course, or switch to an antibiotic that does not inhibit CYP3A4.',
    warning: 'Taking clarithromycin with atorvastatin can cause dangerous muscle breakdown. Your doctor should manage this combination carefully.',
    requiresDoctorConsult: true, commonCombination: false,
    alternatives: 'Azithromycin or amoxicillin are safer antibiotic alternatives for patients on statins.',
  },
  'amoxicillin:metformin': {
    riskLevel: 'low',
    mechanism: 'No significant pharmacokinetic or pharmacodynamic interaction.',
    clinicalEffect: 'No clinically significant interaction expected.',
    severity: 'Low — safe to use together.',
    management: 'No dose adjustment needed. Complete the full antibiotic course.',
    warning: 'Amoxicillin and metformin are generally safe to take together. Complete your full course of antibiotics.',
    requiresDoctorConsult: false, commonCombination: true, alternatives: null,
  },
  'cetirizine:promethazine': {
    riskLevel: 'moderate',
    mechanism: 'Additive CNS depressant and anticholinergic effects from two antihistamines.',
    clinicalEffect: 'Excessive sedation, dizziness, cognitive impairment, dry mouth.',
    severity: 'Moderate — avoid combination, especially before driving.',
    management: 'Avoid combining two antihistamines. Choose one and use the minimum effective dose.',
    warning: 'Combining two antihistamines can cause excessive drowsiness and is generally unnecessary. Do not drive or operate machinery.',
    requiresDoctorConsult: true, commonCombination: false,
    alternatives: 'Use only one antihistamine at a time.',
  },
  'omeprazole:clopidogrel': {
    riskLevel: 'moderate',
    mechanism: 'Omeprazole inhibits CYP2C19, reducing conversion of clopidogrel to its active form.',
    clinicalEffect: 'Reduced antiplatelet effect of clopidogrel, potentially increasing cardiovascular event risk.',
    severity: 'Moderate — clinical significance debated but generally recommended to avoid.',
    management: 'Switch to pantoprazole (minimal CYP2C19 inhibition) if a PPI is needed alongside clopidogrel.',
    warning: 'Omeprazole may reduce how well clopidogrel protects your heart. Ask your doctor about switching to pantoprazole instead.',
    requiresDoctorConsult: true, commonCombination: true,
    alternatives: 'Pantoprazole or rabeprazole are safer PPI alternatives with clopidogrel.',
  },
  'amlodipine:simvastatin': {
    riskLevel: 'moderate',
    mechanism: 'Amlodipine inhibits CYP3A4, increasing simvastatin plasma levels.',
    clinicalEffect: 'Increased risk of myopathy and rhabdomyolysis.',
    severity: 'Moderate — simvastatin dose should be limited to 20mg/day.',
    management: 'Limit simvastatin to 20mg/day. Consider switching to rosuvastatin or pravastatin.',
    warning: 'Amlodipine can increase simvastatin levels in your blood, raising the risk of muscle problems. Your doctor should check your statin dose.',
    requiresDoctorConsult: true, commonCombination: true,
    alternatives: 'Rosuvastatin or pravastatin are not affected by amlodipine.',
  },
  'azithromycin:cetirizine': {
    riskLevel: 'low-moderate',
    mechanism: 'Both drugs can prolong QT interval; additive effect possible.',
    clinicalEffect: 'Possible QT prolongation, rare risk of arrhythmia.',
    severity: 'Low-Moderate — significant only in patients with pre-existing cardiac conditions.',
    management: 'Caution in patients with cardiac disease or electrolyte abnormalities.',
    warning: 'This combination is generally safe but may rarely affect heart rhythm. Inform your doctor if you have heart problems.',
    requiresDoctorConsult: true, commonCombination: true, alternatives: null,
  },
  'naproxen:warfarin': {
    riskLevel: 'high',
    mechanism: 'NSAIDs inhibit platelet aggregation and may enhance anticoagulant activity of warfarin.',
    clinicalEffect: 'Significantly increased bleeding risk.',
    severity: 'High — avoid combination.',
    management: 'Use paracetamol for pain. Monitor INR closely if NSAID is unavoidable.',
    warning: 'Naproxen combined with warfarin significantly increases your bleeding risk. Use paracetamol and consult your doctor.',
    requiresDoctorConsult: true, commonCombination: false,
    alternatives: 'Paracetamol is the recommended pain reliever for patients on warfarin.',
  },
  'diclofenac:ibuprofen': {
    riskLevel: 'high',
    mechanism: 'Additive NSAID effects — both inhibit COX enzymes, doubling toxicity risk.',
    clinicalEffect: 'Significantly increased risk of GI bleeding, ulcers, kidney damage.',
    severity: 'High — combining two NSAIDs provides no benefit and doubles risk.',
    management: 'Never combine two NSAIDs. Use one at the lowest effective dose.',
    warning: 'You should never take two anti-inflammatory drugs (NSAIDs) together. This greatly increases the risk of stomach bleeding and kidney damage.',
    requiresDoctorConsult: true, commonCombination: false,
    alternatives: 'Use only one NSAID, or switch to paracetamol for additional pain relief.',
  },
  'paracetamol:warfarin': {
    riskLevel: 'low-moderate',
    mechanism: 'High-dose or prolonged paracetamol use can inhibit vitamin K-dependent clotting factors.',
    clinicalEffect: 'Mildly elevated INR at high doses; generally safe at standard doses.',
    severity: 'Low-Moderate — safe at standard doses (≤2g/day in patients on warfarin).',
    management: 'Limit paracetamol to ≤2g/day. Monitor INR if used regularly.',
    warning: 'Paracetamol is the safest pain reliever with warfarin, but limit to standard doses. Avoid taking more than 2g per day and monitor your INR.',
    requiresDoctorConsult: true, commonCombination: true, alternatives: null,
  },
};

function lookupStaticInteraction(drug1, drug2) {
  // Keys are alphabetically sorted
  const key = [drug1, drug2].sort().join(':');
  return STATIC_INTERACTIONS[key] || null;
}

// ── Step 4: Gemini AI interaction analysis (THE CORE) ────────────────────────

// Model fallback chain — each has its own free-tier quota pool
const GEMINI_MODELS = ['gemini-2.0-flash', 'gemini-2.0-flash-lite', 'gemini-1.5-flash-8b'];

async function callGeminiWithFallback(prompt) {
  for (const modelName of GEMINI_MODELS) {
    try {
      logger.info('Trying Gemini model: %s', modelName);
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();

      // Strip markdown fences, then extract first JSON object
      const stripped = text.replace(/```json|```/g, '').trim();
      const jsonMatch = stripped.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON object found in Gemini response');

      const parsed = JSON.parse(jsonMatch[0]);
      logger.info('Gemini model succeeded: %s', modelName);
      return parsed;
    } catch (err) {
      const isQuota = err.message?.includes('quota') || err.message?.includes('429') || err.message?.includes('RESOURCE_EXHAUSTED');
      const isNotFound = err.message?.includes('404') || err.message?.includes('not found');

      if (isQuota) {
        logger.warn('Quota exhausted for %s, trying next model...', modelName);
        continue; // try next model
      }
      if (isNotFound) {
        logger.warn('Model %s not available, trying next model...', modelName);
        continue; // try next model
      }
      // For other errors (JSON parse, network), also try next model
      logger.warn('Gemini %s failed (%s), trying next model...', modelName, err.message);
    }
  }
  // All models exhausted
  throw new Error('All Gemini models exhausted or unavailable.');
}

async function getGeminiInteractionAnalysis(drug1, drug2, fdaWarning, coReportCount) {
  const fdaContext = fdaWarning
    ? `FDA label data found: "${fdaWarning}"`
    : `No specific FDA label cross-reference found. Co-adverse-event reports: ${coReportCount}.`;

  const prompt = `
You are a clinical pharmacology AI assistant. Analyze the drug interaction between these two medications and respond ONLY with a valid JSON object — no markdown, no explanation outside the JSON.

Drug A: ${drug1}
Drug B: ${drug2}

Supporting data: ${fdaContext}

Respond with this exact JSON structure:
{
  "riskLevel": "low" | "low-moderate" | "moderate" | "high",
  "mechanism": "Brief 1-sentence pharmacological mechanism of the interaction",
  "clinicalEffect": "What actually happens to the patient (symptoms/outcomes)",
  "severity": "Brief severity classification with reasoning",
  "management": "Specific clinical management recommendation",
  "warning": "A clear, patient-friendly warning summary (2-3 sentences max)",
  "requiresDoctorConsult": true | false,
  "commonCombination": true | false,
  "alternatives": "Brief mention of safer alternatives if risk is high, else null"
}

Risk level guidelines:
- "low": No clinically significant interaction expected
- "low-moderate": Minor interaction, monitor but generally safe
- "moderate": Clinically significant — requires dose adjustment or monitoring  
- "high": Dangerous combination — avoid or use only under strict medical supervision

Be accurate. Base your answer on established pharmacology. Do not invent interactions that don't exist.
  `.trim();

  try {
    return await callGeminiWithFallback(prompt);
  } catch (err) {
    logger.error('All Gemini models failed: %s', err.message);
    // Fallback response if Gemini fails
    return {
      riskLevel: 'unknown',
      mechanism: 'Unable to analyze at this time.',
      clinicalEffect: 'Analysis unavailable.',
      severity: 'Unknown',
      management: 'Consult your pharmacist or doctor.',
      warning: 'We could not complete an AI analysis. Please consult a healthcare professional before combining these medications.',
      requiresDoctorConsult: true,
      commonCombination: false,
      alternatives: null
    };
  }
}

// ── Main exported function ────────────────────────────────────────────────────
async function getDrugInteractionData(drugA, drugB) {
  const d1 = normalizeDrugName(drugA);
  const d2 = normalizeDrugName(drugB);
  const [drug1, drug2] = [d1, d2].sort();

  const cacheKey = `interaction_v2:${drug1}:${drug2}`;

  // Check cache first
  if (isRedisConnected) {
    try {
      const cached = await redisClient.get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch {}
  } else {
    const cached = localCache.get(cacheKey);
    if (cached) return cached;
  }

  // ── Check static knowledge base (instant, no quota) ──────────────────────
  const staticData = lookupStaticInteraction(drug1, drug2);
  if (staticData) {
    logger.info('Static KB hit for: %s + %s', drug1, drug2);
    const result = {
      drug1: drugA,
      drug2: drugB,
      ...staticData,
      coReportCount: 0,
      fdaWarningFound: false,
      source: 'Clinical Knowledge Base',
      analyzedAt: new Date().toISOString(),
    };
    // Cache it
    if (isRedisConnected) {
      try { await redisClient.setEx(cacheKey, 86400, JSON.stringify(result)); } catch {}
    } else {
      localCache.set(cacheKey, result);
    }
    return result;
  }

  // ── Fetch FDA data + call Gemini AI for unknown pairs ────────────────────
  const [fdaWarning, coReportCount] = await Promise.all([
    getFdaLabelWarning(drug1, drug2),
    getFdaCoReportCount(drug1, drug2),
  ]);

  const aiAnalysis = await getGeminiInteractionAnalysis(drug1, drug2, fdaWarning, coReportCount);

  const result = {
    drug1: drugA,
    drug2: drugB,
    riskLevel: aiAnalysis.riskLevel,
    mechanism: aiAnalysis.mechanism,
    clinicalEffect: aiAnalysis.clinicalEffect,
    severity: aiAnalysis.severity,
    management: aiAnalysis.management,
    warning: aiAnalysis.warning,
    requiresDoctorConsult: aiAnalysis.requiresDoctorConsult,
    commonCombination: aiAnalysis.commonCombination,
    alternatives: aiAnalysis.alternatives,
    coReportCount,
    fdaWarningFound: !!fdaWarning,
    source: aiAnalysis.riskLevel === 'unknown' ? 'Analysis Unavailable' : 'Gemini AI + OpenFDA',
    analyzedAt: new Date().toISOString(),
  };

  // Cache for 24 hours
  if (isRedisConnected) {
    try {
      await redisClient.setEx(cacheKey, 86400, JSON.stringify(result));
    } catch {}
  } else {
    localCache.set(cacheKey, result);
  }

  return result;
}

module.exports = { getDrugInteractionData, normalizeDrugName };
