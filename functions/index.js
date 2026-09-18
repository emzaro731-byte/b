const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

const SUPABASE_AI_URL =
  'https://vihbsfrwnslnmheowkhy.supabase.co/functions/v1/veylola-ai';

exports.veylolaAi = onCall({ timeoutSeconds: 540 }, async (request) => {
  if (!request.auth?.token) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  const body = request.data && typeof request.data === 'object'
    ? request.data
    : {};

  const response = await fetch(SUPABASE_AI_URL, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + request.auth.token,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  const text = await response.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch (_) {
    data = { error: text || 'AI provider returned an invalid response.' };
  }

  if (response.ok && !data?.error && body.type === 'chat' && request.auth.uid) {
    await admin.firestore().collection('users').doc(request.auth.uid).collection('conversations').add({
      userMessage: String(body.prompt || body.message || ''),
      assistantMessage: String(data.reply || data.message || ''),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  if (!response.ok || data?.error) {
    logger.error('Supabase AI proxy failed', {
      status: response.status,
      uid: request.auth.uid,
      error: data?.error,
    });
    throw new HttpsError(
      response.status === 401 ? 'unauthenticated' : 'internal',
      data?.error || 'AI request failed.',
    );
  }

  return data;
});
