function parseTimeToMinutes(value) {
  if (typeof value !== "string") return null;
  const m = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(value.trim());
  if (!m) return null;
  const hh = Number(m[1]);
  const mm = Number(m[2]);
  return hh * 60 + mm;
}

function isTimeInRange(appointmentTime, startTime, endTime) {
  const t = parseTimeToMinutes(appointmentTime);
  const start = parseTimeToMinutes(startTime);
  const end = parseTimeToMinutes(endTime);
  if (t === null || start === null || end === null) return false;
  if (start >= end) return false;
  return t >= start && t < end;
}

function toUtcMidnight(dateStr) {
  return new Date(`${dateStr}T00:00:00.000Z`);
}

function utcDateToDayOfWeek(dateObj) {
  // JS: 0=Sun..6=Sat => 1=Mon..7=Sun
  const d = dateObj.getUTCDay();
  return d === 0 ? 7 : d;
}

function utcTodayMidnight() {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
}

function localTodayDateString() {
  const now = new Date();
  const yyyy = now.getFullYear().toString().padStart(4, "0");
  const mm = (now.getMonth() + 1).toString().padStart(2, "0");
  const dd = now.getDate().toString().padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function dayOfWeekFromDateString(dateStr) {
  if (typeof dateStr !== "string") return null;
  const parts = dateStr.split("-");
  if (parts.length !== 3) return null;
  const y = Number(parts[0]);
  const m = Number(parts[1]);
  const d = Number(parts[2]);
  if (!Number.isFinite(y) || !Number.isFinite(m) || !Number.isFinite(d)) return null;
  const date = new Date(y, m - 1, d);
  const day = date.getDay(); // 0=Sun..6=Sat
  return day === 0 ? 7 : day;
}

module.exports = {
  parseTimeToMinutes,
  isTimeInRange,
  toUtcMidnight,
  utcDateToDayOfWeek,
  utcTodayMidnight,
  localTodayDateString,
  dayOfWeekFromDateString,
};
