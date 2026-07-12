const functions = require('firebase-functions');
const crypto = require('crypto');

const DEFAULT_ENGINE = 'https://dnzteam.online/wa-engine';
const OTP_TTL_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;

function getWhatsAppOtpConfig() {
  const cfg = functions.config().dnz || {};
  return {
    apiKey: (
      process.env.DNZ_WHATSAPP_OTP_API_KEY ||
      cfg.whatsapp_otp_api_key ||
      ''
    ).trim(),
    engineUrl: (
      process.env.DNZ_WHATSAPP_OTP_ENGINE_URL ||
      process.env.WHATSAPP_OTP_ENGINE_URL ||
      cfg.whatsapp_otp_engine_url ||
      DEFAULT_ENGINE
    )
      .trim()
      .replace(/\/+$/, ''),
  };
}

function normalizeIraqiPhone(phone) {
  let p = (phone || '').toString().trim().replace(/\s+/g, '');
  if (p.startsWith('+')) p = p.slice(1);
  if (p.startsWith('964') && p.length === 13) {
    return `0${p.slice(3)}`;
  }
  if (p.startsWith('07') && p.length === 11) return p;
  return '';
}

function toE164Iraq(phone07) {
  const local = normalizeIraqiPhone(phone07);
  if (!local) return '';
  return `+964${local.slice(1)}`;
}

function otpDocId(phone07, purpose) {
  return `${phone07}_${purpose}`;
}

function hashOtp(phone07, purpose, code) {
  return crypto
    .createHash('sha256')
    .update(`${phone07}:${purpose}:${code}`)
    .digest('hex');
}

function generateOtpCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function buildOtpMessage(code) {
  return `رمز التحقق الخاص بك لتطبيق Vcenter هو \n${code}`;
}

async function sendWhatsAppOtpMessage({ numberE164, message }) {
  const { apiKey, engineUrl } = getWhatsAppOtpConfig();
  if (!apiKey) {
    return { ok: false, status: 0, error: 'whatsapp_otp_not_configured' };
  }

  const response = await fetch(`${engineUrl}/api/send-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      apiKey,
      number: numberE164,
      message,
    }),
  });

  let payload = null;
  try {
    payload = await response.json();
  } catch (_) {
    payload = null;
  }

  const accepted =
    response.status === 202 ||
    payload?.accepted === true ||
    response.ok;

  return {
    ok: accepted,
    status: response.status,
    payload,
    error: accepted
      ? null
      : payload?.error || payload?.message || `http_${response.status}`,
  };
}

module.exports = {
  OTP_TTL_MS,
  RESEND_COOLDOWN_MS,
  MAX_ATTEMPTS,
  getWhatsAppOtpConfig,
  normalizeIraqiPhone,
  toE164Iraq,
  otpDocId,
  hashOtp,
  generateOtpCode,
  buildOtpMessage,
  sendWhatsAppOtpMessage,
};
