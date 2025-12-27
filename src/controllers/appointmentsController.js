const { prisma } = require("../prisma");
const { ok, fail } = require("../utils/response");
const { appointmentCreateSchema, appointmentCompleteSchema } = require("../validators/appointment");
const { isTimeInRange, toUtcMidnight, localTodayDateString, dayOfWeekFromDateString } = require("../utils/time");

function mapAppointment(a) {
  return {
    id: a.id,
    patient_id: a.patientId,
    doctor_id: a.doctorId,
    appointment_date: a.appointmentDate,
    appointment_time: a.appointmentTime,
    reason: a.reason,
    status: a.status,
    diagnosis: a.diagnosis,
    prescription: a.prescription,
    notes: a.notes,
    created_at: a.createdAt,
    updated_at: a.updatedAt,
    patient: a.patient
      ? {
          id: a.patient.id,
          email: a.patient.email,
          full_name: a.patient.fullName,
          phone_number: a.patient.phoneNumber,
        }
      : undefined,
    doctor: a.doctor
      ? {
          id: a.doctor.id,
          email: a.doctor.email,
          full_name: a.doctor.fullName,
          specialization: a.doctor.specialization,
          consultation_fee: a.doctor.consultationFee,
          rating: a.doctor.rating,
        }
      : undefined,
  };
}

function canAccessAppointment(reqUser, appointment) {
  if (reqUser.role === "admin") return true;
  if (reqUser.role === "patient") return appointment.patientId === reqUser.userId;
  if (reqUser.role === "doctor") return appointment.doctorId === reqUser.userId;
  return false;
}

async function createAppointment(req, res) {
  if (req.user.role !== "patient") return fail(res, 403, "Forbidden");
  const body = appointmentCreateSchema.parse(req.body);

  const appointmentDate = toUtcMidnight(body.appointment_date);
  if (Number.isNaN(appointmentDate.getTime())) return fail(res, 422, "Invalid appointment_date");

  const todayStr = localTodayDateString();
  if (body.appointment_date < todayStr) return fail(res, 422, "appointment_date cannot be in the past");

  const doctor = await prisma.doctor.findUnique({ where: { id: body.doctor_id } });
  if (!doctor || !doctor.isActive) return fail(res, 404, "Doctor not found");

  const dayOfWeek = dayOfWeekFromDateString(body.appointment_date);
  if (!dayOfWeek) return fail(res, 422, "Invalid appointment_date");
  const schedules = await prisma.doctorSchedule.findMany({
    where: { doctorId: doctor.id, dayOfWeek, isAvailable: true },
  });
  const isAvailable = schedules.some((s) => isTimeInRange(body.appointment_time, s.startTime, s.endTime));
  if (!isAvailable) return fail(res, 422, "Doctor is not available for this time slot");

  try {
    const created = await prisma.$transaction(async (tx) => {
      const exists = await tx.appointment.findFirst({
        where: {
          doctorId: doctor.id,
          appointmentDate,
          appointmentTime: body.appointment_time,
          activeSlot: 1,
        },
        select: { id: true },
      });
      if (exists) throw Object.assign(new Error("Slot already booked"), { statusCode: 409 });

      return tx.appointment.create({
        data: {
          patientId: req.user.userId,
          doctorId: doctor.id,
          appointmentDate,
          appointmentTime: body.appointment_time,
          reason: body.reason,
          status: "scheduled",
          activeSlot: 1,
        },
        include: {
          patient: true,
          doctor: true,
        },
      });
    });

    return ok(res, mapAppointment(created), "Created");
  } catch (e) {
    if (e?.statusCode) return fail(res, e.statusCode, e.message);
    throw e;
  }
}

async function getAppointment(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  const appointment = await prisma.appointment.findUnique({
    where: { id },
    include: { patient: true, doctor: true },
  });
  if (!appointment) return fail(res, 404, "Not found");
  if (!canAccessAppointment(req.user, appointment)) return fail(res, 403, "Forbidden");

  return ok(res, mapAppointment(appointment));
}

function parsePagination(req) {
  const page = Math.max(1, Number(req.query.page || 1));
  const limit = Math.min(50, Math.max(1, Number(req.query.limit || 10)));
  const skip = (page - 1) * limit;
  return { page, limit, skip };
}

async function listPatientAppointments(req, res) {
  const patientId = Number(req.params.id);
  if (!Number.isFinite(patientId)) return fail(res, 400, "Invalid id");
  if (req.user.role === "patient" && req.user.userId !== patientId) return fail(res, 403, "Forbidden");
  if (req.user.role !== "patient" && req.user.role !== "admin") return fail(res, 403, "Forbidden");

  const status = (req.query.status || "").toString().trim();
  const { page, limit, skip } = parsePagination(req);

  const where = { patientId };
  if (status) {
    const allowed = ["scheduled", "confirmed", "completed", "cancelled", "no_show"];
    if (!allowed.includes(status)) return fail(res, 422, "Invalid status");
    where.status = status;
  }

  const [total, rows] = await prisma.$transaction([
    prisma.appointment.count({ where }),
    prisma.appointment.findMany({
      where,
      orderBy: { appointmentDate: "desc" },
      skip,
      take: limit,
      include: { doctor: true },
    }),
  ]);

  return ok(res, {
    items: rows.map(mapAppointment),
    pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
  });
}

async function listDoctorAppointments(req, res) {
  const doctorId = Number(req.params.id);
  if (!Number.isFinite(doctorId)) return fail(res, 400, "Invalid id");
  if (req.user.role === "doctor" && req.user.userId !== doctorId) return fail(res, 403, "Forbidden");
  if (req.user.role !== "doctor" && req.user.role !== "admin") return fail(res, 403, "Forbidden");

  const status = (req.query.status || "").toString().trim();
  const date = (req.query.date || "").toString().trim();
  const { page, limit, skip } = parsePagination(req);

  const where = { doctorId };
  if (status) {
    const allowed = ["scheduled", "confirmed", "completed", "cancelled", "no_show"];
    if (!allowed.includes(status)) return fail(res, 422, "Invalid status");
    where.status = status;
  }
  if (date) {
    const d = toUtcMidnight(date);
    if (Number.isNaN(d.getTime())) return fail(res, 422, "Invalid date");
    where.appointmentDate = d;
  }

  const [total, rows] = await prisma.$transaction([
    prisma.appointment.count({ where }),
    prisma.appointment.findMany({
      where,
      orderBy: { appointmentDate: "desc" },
      skip,
      take: limit,
      include: { patient: true },
    }),
  ]);

  return ok(res, {
    items: rows.map(mapAppointment),
    pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
  });
}

async function listAppointmentsByDate(req, res) {
  if (req.user.role !== "admin") return fail(res, 403, "Forbidden");
  const date = (req.query.date || "").toString().trim();
  if (!date) return fail(res, 422, "date is required");
  const d = toUtcMidnight(date);
  if (Number.isNaN(d.getTime())) return fail(res, 422, "Invalid date");

  const items = await prisma.appointment.findMany({
    where: { appointmentDate: d },
    orderBy: [{ appointmentTime: "asc" }],
    include: { patient: true, doctor: true },
  });

  return ok(res, items.map(mapAppointment));
}

async function confirmAppointment(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  const appt = await prisma.appointment.findUnique({ where: { id } });
  if (!appt) return fail(res, 404, "Not found");
  if (req.user.role === "doctor" && req.user.userId !== appt.doctorId) return fail(res, 403, "Forbidden");
  if (req.user.role !== "doctor" && req.user.role !== "admin") return fail(res, 403, "Forbidden");
  if (appt.status === "cancelled") return fail(res, 422, "Appointment is cancelled");

  const updated = await prisma.appointment.update({
    where: { id },
    data: { status: "confirmed", activeSlot: 1 },
    include: { patient: true, doctor: true },
  });
  return ok(res, mapAppointment(updated), "Confirmed");
}

async function completeAppointment(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  const body = appointmentCompleteSchema.parse(req.body);
  const appt = await prisma.appointment.findUnique({ where: { id } });
  if (!appt) return fail(res, 404, "Not found");
  if (req.user.role === "doctor" && req.user.userId !== appt.doctorId) return fail(res, 403, "Forbidden");
  if (req.user.role !== "doctor" && req.user.role !== "admin") return fail(res, 403, "Forbidden");
  if (appt.status === "cancelled") return fail(res, 422, "Appointment is cancelled");

  const updated = await prisma.$transaction(async (tx) => {
    return tx.appointment.update({
      where: { id },
      data: {
        status: "completed",
        activeSlot: 1,
        diagnosis: body.diagnosis,
        prescription: body.prescription,
        notes: body.notes ?? null,
      },
      include: { patient: true, doctor: true },
    });
  });

  return ok(res, mapAppointment(updated), "Completed");
}

async function cancelAppointment(req, res) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return fail(res, 400, "Invalid id");

  const appt = await prisma.appointment.findUnique({ where: { id } });
  if (!appt) return fail(res, 404, "Not found");

  const isPatient = req.user.role === "patient";
  const isDoctor = req.user.role === "doctor";
  const isAdmin = req.user.role === "admin";

  if (isPatient) {
    if (appt.patientId !== req.user.userId) return fail(res, 403, "Forbidden");
    if (!["scheduled", "confirmed"].includes(appt.status)) return fail(res, 422, "Cannot cancel this appointment");
  } else if (isDoctor) {
    if (appt.doctorId !== req.user.userId) return fail(res, 403, "Forbidden");
  } else if (!isAdmin) {
    return fail(res, 403, "Forbidden");
  }

  const updated = await prisma.appointment.update({
    where: { id },
    data: { status: "cancelled", activeSlot: 0 },
    include: { patient: true, doctor: true },
  });
  return ok(res, mapAppointment(updated), "Cancelled");
}

module.exports = {
  createAppointment,
  getAppointment,
  listPatientAppointments,
  listDoctorAppointments,
  listAppointmentsByDate,
  confirmAppointment,
  completeAppointment,
  cancelAppointment,
};
