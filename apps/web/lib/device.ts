// Device ID (S5 §4.5): a random ID in a first-party cookie, readable by the page so it can send it as
// X-Device-Id. It holds nothing but the ID. Shared with S6 (opens, rate limits).
export const DEVICE_COOKIE = 'velio_device';
export const DEVICE_HEADER = 'x-device-id';
export const DEVICE_MAX_AGE = 60 * 60 * 24 * 365;

/** Same shape the API accepts (contracts DeviceId). */
export const DEVICE_ID = /^[A-Za-z0-9_-]{1,128}$/;
