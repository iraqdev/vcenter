const functions = require('firebase-functions');
const crypto = require('crypto');

const DEFAULT_API_BASE = 'https://dnzteam.online/notifications-api';

// يجب أن تطابق قناة التطبيق (NotificationCenter / AndroidManifest)
// androidSound: default = صوت النظام (أوثق عند إغلاق التطبيق حسب دليل DNZ)
const ANDROID_CHANNEL_ID = 'vcenter_push_v3';
const ANDROID_SOUND = 'default';

function getDnzConfig() {
  const cfg = functions.config().dnz || {};
  return {
    apiKey: (process.env.DNZ_NOTIFICATIONS_API_KEY || cfg.api_key || '').trim(),
    apiBase: (process.env.DNZ_NOTIFICATIONS_API_BASE || cfg.api_base || DEFAULT_API_BASE)
      .trim()
      .replace(/\/+$/, ''),
  };
}

function recipientIdForPhone(phone) {
  const p = (phone || '').toString().trim();
  if (!p) return '';
  // حسب دليل DNZ: user_07811098146
  return p.startsWith('user_') ? p : `user_${p}`;
}

function recipientIdCandidates(phone, storedRecipientId) {
  const primary = recipientIdForPhone(phone);
  const stored = (storedRecipientId || '').toString().trim();
  const candidates = [];
  if (stored) candidates.push(stored);
  if (primary) candidates.push(primary);
  return [...new Set(candidates.filter(Boolean))];
}

function connectionIdForToken(token, recipientId, platform = 'android') {
  const raw = (token || '').toString();
  const hash = crypto.createHash('sha256').update(raw || recipientId).digest('hex').slice(0, 24);
  const prefix = platform === 'ios' ? 'ios' : 'android';
  return `${prefix}-${recipientId}-${hash}`;
}

function recipientIdForDashboardToken(token) {
  const t = (token || '').toString().trim();
  if (!t) return '';
  const hash = crypto.createHash('sha256').update(t).digest('hex').slice(0, 24);
  return `dashboard_${hash}`;
}

async function dnzRequest(path, body) {
  const { apiKey, apiBase } = getDnzConfig();
  if (!apiKey) {
    return { ok: false, status: 0, error: 'dnz_not_configured' };
  }

  const response = await fetch(`${apiBase}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
    },
    body: JSON.stringify(body),
  });

  let payload = null;
  try {
    payload = await response.json();
  } catch (_) {
    payload = null;
  }

  return {
    ok: response.ok,
    status: response.status,
    payload,
    error: response.ok ? null : (payload?.message || payload?.error || `http_${response.status}`),
  };
}

async function registerDnzMobileSubscriber({
  recipientId,
  fcmToken,
  apnsToken,
  platform = 'android',
  metadata = {},
}) {
  if (!recipientId) {
    return { ok: false, error: 'missing_recipient' };
  }

  const nativeFcmToken = (fcmToken || '').toString().trim();
  const nativeApnsToken = (apnsToken || '').toString().trim();
  const resolvedPlatform = (platform || '').toString().trim() ||
    (nativeApnsToken && !nativeFcmToken ? 'ios' : 'android');

  if (!nativeFcmToken && !nativeApnsToken) {
    return { ok: false, error: 'missing_recipient_or_token' };
  }

  const body = {
    recipientId,
    platform: resolvedPlatform,
    deviceTransport: 'mobile_background',
    connectionId: connectionIdForToken(
      nativeFcmToken || nativeApnsToken,
      recipientId,
      resolvedPlatform
    ),
    metadata,
  };
  if (nativeFcmToken) body.nativeFcmToken = nativeFcmToken;
  if (nativeApnsToken) body.nativeApnsToken = nativeApnsToken;

  return dnzRequest('/v1/subscribers/register', body);
}

async function sendDnzPush({ recipientId, title, body, data = {} }) {
  if (!recipientId) {
    return { ok: false, error: 'missing_recipient' };
  }

  // حسب دليل DNZ: androidChannelId + androidSound للصوت عند إغلاق التطبيق (أندرويد)
  // نمرّرها أيضاً داخل data كما يسمح الدليل — لا تضر iOS
  return dnzRequest('/v1/send', {
    recipientId,
    channel: 'push',
    title,
    body,
    androidChannelId: ANDROID_CHANNEL_ID,
    androidSound: ANDROID_SOUND,
    data: {
      ...data,
      androidChannelId: ANDROID_CHANNEL_ID,
      androidSound: ANDROID_SOUND,
      channel_id: ANDROID_CHANNEL_ID,
      sound: ANDROID_SOUND,
    },
  });
}

module.exports = {
  getDnzConfig,
  recipientIdForPhone,
  recipientIdCandidates,
  recipientIdForDashboardToken,
  registerDnzMobileSubscriber,
  sendDnzPush,
};
