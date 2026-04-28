const { GoogleGenerativeAI } = require("@google/generative-ai");
const logger = require("../utils/logger");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function checkSymptoms(symptoms, profile) {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-3-flash" });

    const prompt = `
      As a medical AI assistant, analyze the following symptoms:
      Symptoms: ${symptoms}
      User Profile: ${JSON.stringify(profile)}

      Provide a concise assessment including:
      1. Possible causes (disclaimer: not a diagnosis).
      2. Recommended urgency (Home Care, Consult Doctor, Urgent Care, Emergency).
      3. Questions to consider.
      4. Potential drug interactions with their current medications if provided.

      IMPORTANT: Always start and end with a disclaimer that this is NOT medical advice and the user should consult a professional.
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text();
  } catch (error) {
    logger.error("Gemini AI Error: %s", error.message);
    throw new Error("Failed to analyze symptoms via AI.");
  }
}

module.exports = { checkSymptoms };
