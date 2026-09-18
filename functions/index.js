const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

const SUPABASE_AI_URL =
  'https://vihbsfrwnslnmheowkhy.supabase.co/functions/v1/veylola-ai';

const MEDIA_DAILY_LIMIT = 5;

function localDayKey() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Africa/Lagos',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

async function reserveMediaGeneration(uid, type) {
  if (!['image', 'video'].includes(type)) return null;
  const day = localDayKey();
  const ref = admin.firestore()
    .collection('users').doc(uid)
    .collection('aiUsage').doc(day);

  return admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = snap.exists ? (snap.data() || {}) : {};
    const used = Number(current[type] || 0);
    if (used >= MEDIA_DAILY_LIMIT) {
      throw new HttpsError(
        'resource-exhausted',
        `Daily ${type} generation limit reached. You can generate up to ${MEDIA_DAILY_LIMIT} ${type} generations per day.`,
        { type, used, limit: MEDIA_DAILY_LIMIT, remaining: 0, day },
      );
    }
    tx.set(ref, {
      [type]: used + 1,
      day,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { type, day, used: used + 1, limit: MEDIA_DAILY_LIMIT, remaining: MEDIA_DAILY_LIMIT - used - 1 };
  });
}

async function releaseMediaGeneration(uid, reservation) {
  if (!reservation) return;
  const ref = admin.firestore()
    .collection('users').doc(uid)
    .collection('aiUsage').doc(reservation.day);
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const current = snap.data() || {};
    const next = Math.max(0, Number(current[reservation.type] || 0) - 1);
    tx.update(ref, {
      [reservation.type]: next,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

exports.veylolaAi = onCall({ timeoutSeconds: 540 }, async (request) => {
  if (!request.auth?.token) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  const body = request.data && typeof request.data === 'object'
    ? request.data
    : {};

  let mediaReservation = null;
  const mediaType = body.type === 'video' ? 'video' : body.type === 'image' ? 'image' : null;
  if (mediaType) {
    mediaReservation = await reserveMediaGeneration(request.auth.uid, mediaType);
  }

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
    if (mediaReservation) {
      try {
        await releaseMediaGeneration(request.auth.uid, mediaReservation);
      } catch (rollbackError) {
        logger.error('Failed to roll back media quota reservation', { error: rollbackError });
      }
    }
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

  if (mediaReservation) {
    data.usage = mediaReservation;
  }

  return data;
});
