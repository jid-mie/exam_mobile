const { z } = require("zod");

const patientRegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  full_name: z.string().min(1),
  phone_number: z.string().optional().nullable(),
  date_of_birth: z.string().optional().nullable(),
  gender: z.enum(["male", "female", "other"]).optional().nullable(),
  address: z.string().optional().nullable(),
  blood_type: z.string().optional().nullable(),
  emergency_contact: z.string().optional().nullable(),
});

const doctorRegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  full_name: z.string().min(1),
  phone_number: z.string().optional().nullable(),
  specialization: z.enum(["Cardiology", "Dermatology", "Pediatrics", "Orthopedics", "General"]),
  qualification: z.string().optional().nullable(),
  experience: z.preprocess(
    (value) => {
      if (typeof value === "number") return value;
      if (typeof value === "string" && value.trim() !== "") return Number(value);
      return value;
    },
    z.number().int().min(0).optional().default(0)
  ),
  consultation_fee: z.preprocess(
    (value) => {
      if (typeof value === "number") return value;
      if (typeof value === "string" && value.trim() !== "") return Number(value);
      return value;
    },
    z.number().positive()
  ),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

module.exports = { patientRegisterSchema, doctorRegisterSchema, loginSchema };
