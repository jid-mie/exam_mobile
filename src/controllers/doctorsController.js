const { prisma } = require("../prisma");
const { ok, fail } = require("../utils/response");
const { doctorUpdateSchema } = require("../validators/doctor");

function safeDoctor(d) {
  const { password, ...rest } = d;
  return {
    ...rest,
    full_name: d.fullName,
    phone_number: d.phoneNumber,
    consultation_fee: d.consultationFee,
    is_active: d.isActive,
  };
}

async function listDoctors(req, res) {
  const search = (req.query.search || "").toString().trim();
  const specialization = (req.query.specialization || "").toString().trim();
  const availableOnly = (req.query.available_only || "").toString().trim().toLowerCase() === "true";

  const allowedSpecializations = ["Cardiology", "Dermatology", "Pediatrics", "Orthopedics", "General"];

  const where = {};
  if (search) {
    where.OR = [{ fullName: { contains: search } }];
    if (allowedSpecializations.includes(search)) {
      where.OR.push({ specialization: search });
    }
  }
  if (specialization) {
    if (!allowedSpecializations.includes(specialization)) return fail(res, 422, "Invalid specialization");
    where.specialization = specialization;
  }
  if (availableOnly) {
    where.doctorSchedules = { some: { isAvailable: true } };
    where.isActive = true;
  }

  const doctors = await prisma.doctor.findMany({
    where,
    orderBy: { rating: "desc" },
    select: {
      id: true,
      fullName: true,
      specialization: true,
      consultationFee: true,
      rating: true,
      isActive: true,
    },
  });

  return ok(res, doctors.map((d) => ({
    id: d.id,
    full_name: d.fullName,
    specialization: d.specialization,
    consultation_fee: d.consultationFee,
    rating: d.rating,
    is_active: d.isActive,
  })));
}

async function getDoctor(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  const doctor = await prisma.doctor.findUnique({
    where: { id },
    include: { doctorSchedules: { orderBy: [{ dayOfWeek: "asc" }, { startTime: "asc" }] } },
  });
  if (!doctor) return fail(res, 404, "Not found");

  const data = safeDoctor(doctor);
  data.doctor_schedules = doctor.doctorSchedules.map((s) => ({
    id: s.id,
    doctor_id: s.doctorId,
    day_of_week: s.dayOfWeek,
    start_time: s.startTime,
    end_time: s.endTime,
    is_available: s.isAvailable,
  }));
  delete data.doctorSchedules;
  return ok(res, data);
}

async function updateDoctor(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  if (req.user.role === "doctor" && req.user.userId !== id) return fail(res, 403, "Forbidden");

  const body = doctorUpdateSchema.parse(req.body);

  const doctor = await prisma.doctor.update({
    where: { id },
    data: {
      fullName: body.full_name,
      phoneNumber: body.phone_number,
      specialization: body.specialization,
      qualification: body.qualification,
      experience: body.experience,
      consultationFee: body.consultation_fee != null ? String(body.consultation_fee) : undefined,
      rating: body.rating != null ? String(body.rating) : undefined,
      isActive: body.is_active,
    },
  });

  return ok(res, safeDoctor(doctor), "Updated");
}

module.exports = { listDoctors, getDoctor, updateDoctor };
