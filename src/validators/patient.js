const { z } = require("zod");

const patientUpdateSchema = z.object({
  full_name: z.string().min(1).optional(),
  phone_number: z.string().optional().nullable(),
  date_of_birth: z.string().optional().nullable(),
  gender: z.enum(["male", "female", "other"]).optional().nullable(),
  address: z.string().optional().nullable(),
  blood_type: z.string().optional().nullable(),
  emergency_contact: z.string().optional().nullable(),
});

module.exports = { patientUpdateSchema };

