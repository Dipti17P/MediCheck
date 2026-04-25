const axios = require('axios');
const NodeCache = require('node-cache');

const cache = new NodeCache({ stdTTL: 3600 });

const FDA_BASE = 'https://api.fda.gov/drug/label.json';

async function getDrugWarnings(rxcui, drugName) {
  const key = `fda_${rxcui || drugName}`;
  const cached = cache.get(key);
  if (cached) return cached;

  try {
    const res = await axios.get(FDA_BASE, {
      params: {
        search: `openfda.rxcui:"${rxcui}"`,
        limit: 1,
        ...(process.env.OPENFDA_API_KEY && { api_key: process.env.OPENFDA_API_KEY })
      }
    });

    const result = res.data?.results?.[0] || null;
    cache.set(key, result);
    return result;
  } catch (err) {
    if (err.response && err.response.status === 404 && drugName) {
      try {
        const res2 = await axios.get(FDA_BASE, {
          params: {
            search: `openfda.substance_name:"${drugName}"`,
            limit: 1,
            ...(process.env.OPENFDA_API_KEY && { api_key: process.env.OPENFDA_API_KEY })
          }
        });
        const result2 = res2.data?.results?.[0] || null;
        cache.set(key, result2);
        return result2;
      } catch (err2) {
        if (err2.response && err2.response.status === 404) {
          cache.set(key, null);
          return null;
        }
      }
    }
    if (err.response && err.response.status === 404) {
      cache.set(key, null);
      return null;
    }
    throw err;
  }
}

function extractInteractions(labelData) {
  if (!labelData) return [];
  
  const fieldsToCheck = [
    labelData.drug_interactions?.[0],
    labelData.warnings_and_cautions?.[0],
    labelData.warnings?.[0],
    labelData.boxed_warning?.[0],
    labelData.ask_doctor_or_pharmacist?.[0],
    labelData.ask_doctor?.[0],
    labelData.precautions?.[0]
  ];

  const raw = fieldsToCheck.filter(Boolean).join('. ');

  if (!raw) return [];

  // Split into sentences, filter blanks
  return raw
    .split(/(?<=[.!?])\s+/)
    .map(s => s.trim())
    .filter(s => s.length > 20)
    // Remove duplicate sentences
    .filter((v, i, a) => a.indexOf(v) === i)
    .slice(0, 8); // return up to 8 relevant sentences
}

module.exports = { getDrugWarnings, extractInteractions };
