const { prisma } = require("../prisma");
const { ok, fail } = require("../utils/response");
const { toUtcMidnight } = require("../utils/time");
const { patientUpdateSchema } = require("../validators/patient");

function safePatient(p) {
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

async function listPatients(req, res) {
  const patients = await prisma.patient.findMany({ orderBy: { id: "asc" } });
  return ok(res, patients.map(safePatient));
}

async function getPatient(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  if (req.user.role === "patient" && req.user.userId !== id) return fail(res, 403, "Forbidden");

  const patient = await prisma.patient.findUnique({ where: { id } });
  if (!patient) return fail(res, 404, "Not found");
  return ok(res, safePatient(patient));
}

async function updatePatient(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  if (req.user.role === "patient" && req.user.userId !== id) return fail(res, 403, "Forbidden");

  const body = patientUpdateSchema.parse(req.body);
  const patient = await prisma.patient.update({
    where: { id },
    data: {
      fullName: body.full_name,
      phoneNumber: body.phone_number,
      dateOfBirth: body.date_of_birth ? toUtcMidnight(body.date_of_birth) : body.date_of_birth === null ? null : undefined,
      gender: body.gender,
      address: body.address,
      bloodType: body.blood_type,
      emergencyContact: body.emergency_contact,
    },
  });
  return ok(res, safePatient(patient), "Updated");
}

module.exports = { listPatients, getPatient, updatePatient };

