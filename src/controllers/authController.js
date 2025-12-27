const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const config = require("../config");
const { prisma } = require("../prisma");
const { ok, fail } = require("../utils/response");
const { toUtcMidnight } = require("../utils/time");
const { patientRegisterSchema, doctorRegisterSchema, loginSchema } = require("../validators/auth");

function safePatient(p) {
  if (!p) return null;
  const { password, ...rest } = p;
  return {
    ...rest,
    full_name: p.fullName,
    phone_number: p.phoneNumber,
    date_of_birth: p.dateOfBirth,
    blood_type: p.bloodType,
    emergency_contact: p.emergencyContact,
  };
}

function safeDoctor(d) {
  if (!d) return null;
  const { password, ...rest } = d;
  return {
    ...rest,
    full_name: d.fullName,
    phone_number: d.phoneNumber,
    consultation_fee: d.consultationFee,
    is_active: d.isActive,
  };
}

async function registerPatient(req, res) {
  const body = patientRegisterSchema.parse(req.body);
  const passwordHash = await bcrypt.hash(body.password, 10);

  const patient = await prisma.patient.create({
    data: {
      email: body.email,
      password: passwordHash,
      fullName: body.full_name,
      phoneNumber: body.phone_number ?? null,
      dateOfBirth: body.date_of_birth ? toUtcMidnight(body.date_of_birth) : null,
      gender: body.gender ?? null,
      address: body.address ?? null,
      bloodType: body.blood_type ?? null,
      emergencyContact: body.emergency_contact ?? null,
    },
  });

  return ok(res, safePatient(patient), "Registered patient");
}

async function registerDoctor(req, res) {
  const body = doctorRegisterSchema.parse(req.body);
  const passwordHash = await bcrypt.hash(body.password, 10);

  const doctor = await prisma.doctor.create({
    data: {
      email: body.email,
      password: passwordHash,
      fullName: body.full_name,
      phoneNumber: body.phone_number ?? null,
      specialization: body.specialization,
      qualification: body.qualification ?? null,
      experience: body.experience ?? 0,
      consultationFee: String(body.consultation_fee),
      isActive: true,
    },
  });

  return ok(res, safeDoctor(doctor), "Registered doctor");
}

async function login(req, res) {
  const body = loginSchema.parse(req.body);

  if (body.email === config.adminEmail && body.password === config.adminPassword) {
    const token = jwt.sign({ role: "admin" }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
    return ok(res, {
      token,
      user: { email: config.adminEmail, full_name: "Admin" },
      role: "admin",
      student_id: config.studentId,
    });
  }

  const patient = await prisma.patient.findUnique({ where: { email: body.email } });
  if (patient && (await bcrypt.compare(body.password, patient.password))) {
    const token = jwt.sign({ role: "patient", userId: patient.id }, config.jwtSecret, {
      expiresIn: config.jwtExpiresIn,
    });
    return ok(res, { token, user: safePatient(patient), role: "patient", student_id: config.studentId });
  }

  const doctor = await prisma.doctor.findUnique({ where: { email: body.email } });
  if (doctor && (await bcrypt.compare(body.password, doctor.password))) {
    const token = jwt.sign({ role: "doctor", userId: doctor.id }, config.jwtSecret, {
      expiresIn: config.jwtExpiresIn,
    });
    return ok(res, { token, user: safeDoctor(doctor), role: "doctor", student_id: config.studentId });
  }

  return fail(res, 401, "Invalid credentials");
}

async function me(req, res) {
  if (req.user.role === "admin") {
    return ok(res, { role: "admin", user: { email: config.adminEmail, full_name: "Admin" } });
  }
  if (req.user.role === "patient") {
    const patient = await prisma.patient.findUnique({ where: { id: req.user.userId } });
    if (!patient) return fail(res, 404, "Not found");
    return ok(res, { role: "patient", user: safePatient(patient) });
  }
  if (req.user.role === "doctor") {
    const doctor = await prisma.doctor.findUnique({ where: { id: req.user.userId } });
    if (!doctor) return fail(res, 404, "Not found");
    return ok(res, { role: "doctor", user: safeDoctor(doctor) });
  }
  return fail(res, 401, "Unauthorized");
}

module.exports = { registerPatient, registerDoctor, login, me };

