const { GoogleGenerativeAI } = require('@google/generative-ai');
const NodeCache = require('node-cache');
const logger = require('../utils/logger');
const { normalizeDrugName } = require('./drugInteractionService');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const altCache = new NodeCache({ stdTTL: 86400 }); // 24h cache

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-2.5-pro'];

async function callGeminiWithFallback(prompt) {
  for (const modelName of GEMINI_MODELS) {
    try {
      logger.info('DrugAlt: Trying model %s', modelName);
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();

      const stripped = text.replace(/```json|```/g, '').trim();
      const jsonMatch = stripped.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON found in response');

      const parsed = JSON.parse(jsonMatch[0]);
      logger.info('DrugAlt: Model %s succeeded', modelName);
      return parsed;
    } catch (err) {
      const isQuota = err.message?.includes('429') || err.message?.includes('quota') || err.message?.includes('RESOURCE_EXHAUSTED');
      const isNotFound = err.message?.includes('404') || err.message?.includes('not found');
      if (isQuota || isNotFound) {
        logger.warn('DrugAlt: %s failed (%s), trying next...', modelName, err.message?.slice(0, 60));
        continue;
      }
      logger.warn('DrugAlt: %s error (%s), trying next...', modelName, err.message?.slice(0, 60));
    }
  }
  throw new Error('All Gemini models exhausted for drug alternatives.');
}

async function getDrugAlternatives(drugName, reason = null) {
  const normalized = normalizeDrugName(drugName);
  const cacheKey = `alt_v1:${normalized}:${reason ?? 'general'}`;

  const cached = altCache.get(cacheKey);
  if (cached) {
    logger.info('DrugAlt: cache hit for %s', normalized);
    return cached;
  }

  const reasonContext = reason
    ? `The patient needs an alternative because: ${reason}.`
    : 'The patient is looking for alternative medications.';

  const prompt = `
You are a clinical pharmacology AI. A patient is asking about alternatives to the drug: "${drugName}" (generic: "${normalized}").
${reasonContext}

Respond ONLY with a valid JSON object in this exact structure:
{
  "drug": "${drugName}",
  "drugClass": "The pharmacological class this drug belongs to (e.g. NSAID, ACE inhibitor, PPI)",
  "primaryUse": "What this drug is typically used for (1 sentence)",
  "alternatives": [
    {
      "name": "Generic drug name",
      "brandExamples": ["Brand1", "Brand2"],
      "drugClass": "Same or similar class",
      "comparisonToOriginal": "How it compares — key differences in 1-2 sentences",
      "advantages": "Why someone might prefer this alternative (1 sentence)",
      "suitableFor": "Who this is best for (e.g. 'patients with kidney issues', 'elderly patients', 'general population')",
      "requiresPrescription": true | false,
      "availabilityInIndia": "common" | "moderate" | "limited"
    }
  ],
  "generalAdvice": "A short patient-friendly note about switching medications (2-3 sentences)",
  "alwaysConsultDoctor": true
}

Rules:
- Provide 3 to 5 meaningful alternatives.
- Include alternatives from the same drug class AND cross-class alternatives where clinically appropriate.
- Be accurate. Do not invent drugs that don't exist.
- Tailor availabilityInIndia to Indian pharmacy context.
`.trim();

  try {
    const data = await callGeminiWithFallback(prompt);
    // Ensure required fields exist
    const result = {
      drug: drugName,
      drugClass: data.drugClass ?? 'Unknown',
      primaryUse: data.primaryUse ?? 'Information unavailable.',
      alternatives: Array.isArray(data.alternatives) ? data.alternatives : [],
      generalAdvice: data.generalAdvice ?? 'Consult your doctor before switching medications.',
      alwaysConsultDoctor: true,
      analyzedAt: new Date().toISOString(),
    };
    altCache.set(cacheKey, result);
    return result;
  } catch (err) {
    logger.error('DrugAlt: All models failed for %s: %s', drugName, err.message);
    // Return graceful fallback if API quota is reached
    return {
      drug: drugName,
      drugClass: "Unavailable (AI Rate Limited)",
      primaryUse: "The MediCheck AI service is currently experiencing high traffic or rate limits.",
      alternatives: [
        {
          name: "API Limit Reached",
          brandExamples: [],
          drugClass: "N/A",
          comparisonToOriginal: "We are currently unable to analyze alternatives due to server limits. Please try again in 1-2 minutes.",
          advantages: "N/A",
          suitableFor: "N/A",
          requiresPrescription: true,
          availabilityInIndia: "moderate"
        }
      ],
      generalAdvice: "Please try again later or consult a healthcare professional directly. AI generation is temporarily unavailable.",
      alwaysConsultDoctor: true,
      analyzedAt: new Date().toISOString(),
    };
  }
}

module.exports = { getDrugAlternatives };
