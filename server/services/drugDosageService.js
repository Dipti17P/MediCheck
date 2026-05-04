const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');
const NodeCache = require('node-cache');
const logger = require('../utils/logger');
const { normalizeDrugName } = require('./drugInteractionService');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const dosageCache = new NodeCache({ stdTTL: 86400 }); // 24h cache

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-2.5-pro'];

async function callGeminiWithFallback(prompt) {
  for (const modelName of GEMINI_MODELS) {
    try {
      logger.info('DrugDosage: Trying model %s', modelName);
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();

      const stripped = text.replace(/```json|```/g, '').trim();
      const jsonMatch = stripped.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON found in response');

      const parsed = JSON.parse(jsonMatch[0]);
      logger.info('DrugDosage: Model %s succeeded', modelName);
      return parsed;
    } catch (err) {
      const isQuota = err.message?.includes('429') || err.message?.includes('quota') || err.message?.includes('RESOURCE_EXHAUSTED');
      const isNotFound = err.message?.includes('404') || err.message?.includes('not found');
      if (isQuota || isNotFound) {
        logger.warn('DrugDosage: %s failed (%s), trying next...', modelName, err.message?.slice(0, 60));
        continue;
      }
      logger.warn('DrugDosage: %s error (%s), trying next...', modelName, err.message?.slice(0, 60));
    }
  }
  throw new Error('All Gemini models exhausted for drug dosage.');
}

async function getFdaDosageLimits(drugName) {
  try {
    const url = `https://api.fda.gov/drug/label.json?search=openfda.generic_name:"${encodeURIComponent(drugName)}"+openfda.substance_name:"${encodeURIComponent(drugName)}"&limit=1`;
    const res = await axios.get(url, { timeout: 5000 });
    const result = res.data?.results?.[0];
    if (!result) return null;

    // Combine relevant dosage fields
    const dosageContext = [
      result.dosage_and_administration?.[0],
      result.overdosage?.[0]
    ].filter(Boolean).join('\n').slice(0, 2000); // Send up to 2000 chars of context to Gemini

    return dosageContext;
  } catch (e) {
    logger.warn('Failed to fetch FDA dosage limits for %s: %s', drugName, e.message);
    return null;
  }
}

async function getDosageRecommendation(drugName, user) {
  const normalized = normalizeDrugName(drugName);
  
  // Create cache key based on user vitals
  const userString = `${user.age || 'na'}_${user.weight || 'na'}_${user.renalStatus || 'na'}_${user.hepaticStatus || 'na'}`;
  const cacheKey = `dosage_v1:${normalized}:${userString}`;

  const cached = dosageCache.get(cacheKey);
  if (cached) {
    logger.info('DrugDosage: cache hit for %s', normalized);
    return cached;
  }

  // Check if we have enough data to calculate personalized dosage
  const hasVitals = user.age || user.weight || (user.renalStatus && user.renalStatus !== 'unknown') || (user.hepaticStatus && user.hepaticStatus !== 'unknown');

  const fdaLimits = await getFdaDosageLimits(normalized);

  const prompt = `
You are a clinical pharmacokinetics AI assistant. Calculate the recommended personalized dosage range for the medication: "${drugName}" (generic: "${normalized}").

Patient Profile:
- Age: ${user.age || 'Unknown'} years
- Weight: ${user.weight || 'Unknown'} kg
- Renal Function: ${user.renalStatus || 'Unknown'}
- Hepatic Function: ${user.hepaticStatus || 'Unknown'}

${fdaLimits ? `FDA Context for dosage/limits (extract constraints from here if applicable):\n"""\n${fdaLimits}\n"""` : 'No direct FDA context available.'}

Respond ONLY with a valid JSON object in this exact structure:
{
  "drug": "${drugName}",
  "recommendedDosage": "e.g., 500mg every 6 hours",
  "maxDailyDose": "e.g., 4000mg/day",
  "adjustmentsMade": "Explain if dose was altered due to weight, age, renal, or hepatic status (e.g., 'Dose reduced by 50% due to moderate renal impairment'). If no adjustments were needed, state 'Standard adult dosing applied.'",
  "specialInstructions": "e.g., Take with food, swallow whole",
  "warningLevel": "low" | "moderate" | "high" | "severe",
  "disclaimer": "AI estimates are not medical advice. ALWAYS consult your prescribing doctor before starting or changing any medication dosage.",
  "consultDoctorRequired": true
}

Rules:
1. If Patient Age is under 18, apply strict pediatric weight-based dosing (mg/kg) if applicable.
2. If Renal or Hepatic Function is impaired, adjust the dosage according to standard clinical guidelines.
3. If no vitals are provided (${!hasVitals}), provide the standard adult dose and state in adjustmentsMade that "Standard adult dosing applied due to missing patient vitals."
4. Be accurate and conservative. Do not exceed max daily doses.
`.trim();

  try {
    const data = await callGeminiWithFallback(prompt);
    
    const result = {
      ...data,
      isPersonalized: hasVitals,
      analyzedAt: new Date().toISOString()
    };
    
    return result;
  } catch (err) {
    logger.error('DrugDosage: All models failed for %s: %s', drugName, err.message);
    
    // Graceful fallback for API limits
    return {
      drug: drugName,
      recommendedDosage: "Unable to calculate (AI Rate Limited)",
      maxDailyDose: "Unknown. Please consult your prescribing doctor.",
      adjustmentsMade: "The MediCheck AI service is currently experiencing high traffic. We could not apply your vitals at this time.",
      specialInstructions: "Please refer to the physical packaging or try again in a few minutes.",
      warningLevel: "moderate",
      disclaimer: "AI estimates are currently unavailable. ALWAYS consult your prescribing doctor before starting or changing any medication dosage.",
      consultDoctorRequired: true,
      isPersonalized: false,
      analyzedAt: new Date().toISOString()
    };
  }
}

module.exports = { getDosageRecommendation };
