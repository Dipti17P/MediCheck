const axios = require('axios');
const NodeCache = require('node-cache');

const cache = new NodeCache({ stdTTL: 86400 }); // cache 24 hrs

const RXNORM_BASE = 'https://rxnav.nlm.nih.gov/REST';

async function getRxCUI(drugName) {
  const key = `rxcui_${drugName.toLowerCase().trim()}`;
  const cached = cache.get(key);
  if (cached) return cached;

  const res = await axios.get(`${RXNORM_BASE}/rxcui.json`, {
    params: { name: drugName, search: 2 }
  });

  const id = res.data?.idGroup?.rxnormId?.[0];
  if (!id) throw new Error(`Drug not found in RxNorm: ${drugName}`);

  cache.set(key, id);
  return id;
}

module.exports = { getRxCUI };
