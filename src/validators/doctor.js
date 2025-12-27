const { z } = require("zod");

const doctorUpdateSchema = z.object({
  full_name: z.string().min(1).optional(),
  phone_number: z.string().optional().nullable(),
  specialization: z.enum(["Cardiology", "Dermatology", "Pediatrics", "Orthopedics", "General"]).optional(),
  qualification: z.string().optional().nullable(),
  experience: z.number().int().min(0).optional(),
  consultation_fee: z.number().positive().optional(),
  rating: z.number().min(0).max(5).optional(),
  is_active: z.boolean().optional(),
});

const scheduleCreateSchema = z.object({
  day_of_week: z.number().int().min(1).max(7),
  start_time: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
  end_time: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
  is_available: z.boolean().optional().default(true),
});

module.exports = { doctorUpdateSchema, scheduleCreateSchema };
