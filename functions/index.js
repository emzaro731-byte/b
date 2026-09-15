const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');
const KIE_API_KEY = defineSecret('KIE_API_KEY');
const KIE_API_URL = defineSecret('KIE_API_URL');

exports.chat = onCall({ secrets: [GROQ_API_KEY] }, async (request) => {
  const message = String(request.data?.message ?? '').trim();
  if (!message) throw new HttpsError('invalid-argument', 'Message is required.');

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${GROQ_API_KEY.value()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: 'You are Veylola AI, a helpful, concise and capable multimodal assistant.' },
        { role: 'user', content: message },
      ],
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    logger.error('Groq request failed', { status: response.status });
    throw new HttpsError('internal', 'AI provider request failed.');
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;
  if (!reply) throw new HttpsError('internal', 'AI provider returned no response.');

  if (request.auth?.uid) {
    await admin.firestore().collection('users').doc(request.auth.uid).collection('conversations').add({
      userMessage: message,
      assistantMessage: reply,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return { reply };
});

exports.generateMedia = onCall({ secrets: [KIE_API_KEY, KIE_API_URL] }, async (request) => {
  const type = String(request.data?.type ?? '').trim();
  const prompt = String(request.data?.prompt ?? '').trim();
  if (!type || !prompt) throw new HttpsError('invalid-argument', 'Media type and prompt are required.');

  const endpoint = KIE_API_URL.value();
  if (!endpoint) throw new HttpsError('failed-precondition', 'Kie.ai endpoint is not configured.');

  // Keep Kie.ai credentials server-side. The exact request body can be adapted
  // to the Kie.ai model/task selected for each media type.
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${KIE_API_KEY.value()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ type, prompt }),
  });

  if (!response.ok) {
    logger.error('Kie.ai request failed', { status: response.status, type });
    throw new HttpsError('internal', 'Media provider request failed.');
  }

  return await response.json();
});
