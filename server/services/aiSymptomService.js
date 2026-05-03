const { GoogleGenerativeAI } = require("@google/generative-ai");
const logger = require("../utils/logger");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function checkSymptoms(symptoms, profile) {
  try {
    // ✅ Correct model name
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const prompt = `
You are a medical AI assistant. Analyze the following symptoms and provide a structured assessment.

PATIENT PROFILE:
- Age: ${profile.age || 'Not specified'}
- Known Allergies: ${profile.allergies?.join(', ') || 'None reported'}
- Medical History: ${profile.medicalHistory || 'None reported'}

REPORTED SYMPTOMS: ${symptoms}

Provide your response in this exact structure:

**⚠️ DISCLAIMER**
This is NOT medical advice. Always consult a qualified healthcare professional for diagnosis and treatment.

**Possible Causes**
List 2-4 possible causes with brief explanations.

**Urgency Level**
State one of: 🏠 Home Care | 👨⚕️ Consult Doctor (within 48h) | 🏥 Urgent Care (today) | 🚨 Emergency (call now)
Explain why this urgency level applies.

**Recommended Actions**
List 3-5 specific actionable steps.

**Questions to Discuss with Your Doctor**
List 3 specific questions.

**Drug Interaction Warning** (only if medications mentioned)
If the patient mentioned any medications, flag potential concerns with their current medical history.

**⚠️ REMINDER**
This assessment is informational only. If symptoms worsen or you feel uncertain, seek immediate medical attention.
    `.trim();

    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text();
  } catch (error) {
    logger.error("Gemini AI Error: %s", error.message);
    throw new Error("Failed to analyze symptoms via AI.");
  }
}

module.exports = { checkSymptoms };
