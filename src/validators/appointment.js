const { z } = require("zod");

function normalizeDate(value) {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString().slice(0, 10);
  }
  if (typeof value === "string") {
    const trimmed = value.trim();
    const match = /(\d{4})[-/](\d{1,2})[-/](\d{1,2})/.exec(trimmed);
    if (match) {
      const yyyy = match[1];
      const mm = match[2].padStart(2, "0");
      const dd = match[3].padStart(2, "0");
      return `${yyyy}-${mm}-${dd}`;
    }
    const parsed = new Date(trimmed);
    if (!Number.isNaN(parsed.getTime())) {
      const yyyy = parsed.getUTCFullYear().toString().padStart(4, "0");
      const mm = (parsed.getUTCMonth() + 1).toString().padStart(2, "0");
      const dd = parsed.getUTCDate().toString().padStart(2, "0");
      return `${yyyy}-${mm}-${dd}`;
    }
    return trimmed;
  }
  return value;
}

function normalizeTime(value) {
  if (typeof value === "string") {
    const trimmed = value.trim();
    const match = /(\d{1,2}):(\d{2})/.exec(trimmed);
    if (match) {
      const hh = match[1].padStart(2, "0");
      const mm = match[2].padStart(2, "0");
      return `${hh}:${mm}`;
    }
    return trimmed;
  }
  return value;
}

const appointmentCreateSchema = z.object({
  doctor_id: z.preprocess(
    (value) => {
      if (typeof value === "number") return value;
      if (typeof value === "string" && value.trim() !== "") return Number(value);
      return value;
    },
    z.number().int().positive()
  ),
  appointment_date: z.preprocess(normalizeDate, z.string().regex(/^\d{4}-\d{2}-\d{2}$/)),
  appointment_time: z.preprocess(normalizeTime, z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/)),
  reason: z.string().min(1),
});

const appointmentCompleteSchema = z.object({
  diagnosis: z.string().min(1),
  prescription: z.string().min(1),
  notes: z.string().optional().nullable(),
});

module.exports = { appointmentCreateSchema, appointmentCompleteSchema };
