const { prisma } = require("../prisma");
const { ok, fail } = require("../utils/response");
const { parseTimeToMinutes } = require("../utils/time");
const { scheduleCreateSchema } = require("../validators/doctor");

function requireSelfDoctor(req, res, doctorId) {
  if (req.user.role !== "doctor") return fail(res, 403, "Forbidden");
  if (req.user.userId !== doctorId) return fail(res, 403, "Forbidden");
  return null;
}

async function createSchedule(req, res) {
  const doctorId = Number(req.params.id);
  if (!Number.isFinite(doctorId)) return fail(res, 400, "Invalid doctor id");
  const forbidden = requireSelfDoctor(req, res, doctorId);
  if (forbidden) return forbidden;

  const body = scheduleCreateSchema.parse(req.body);
  const start = parseTimeToMinutes(body.start_time);
  const end = parseTimeToMinutes(body.end_time);
  if (start === null || end === null || start >= end) return fail(res, 422, "Invalid time range");

  const schedule = await prisma.doctorSchedule.create({
    data: {
      doctorId,
      dayOfWeek: body.day_of_week,
      startTime: body.start_time,
      endTime: body.end_time,
      isAvailable: body.is_available,
    },
  });

  return ok(res, {
    id: schedule.id,
    doctor_id: schedule.doctorId,
    day_of_week: schedule.dayOfWeek,
    start_time: schedule.startTime,
    end_time: schedule.endTime,
    is_available: schedule.isAvailable,
  });
}

async function listSchedules(req, res) {
  const doctorId = Number(req.params.id);
  if (!Number.isFinite(doctorId)) return fail(res, 400, "Invalid doctor id");

  const schedules = await prisma.doctorSchedule.findMany({
    where: { doctorId },
    orderBy: [{ dayOfWeek: "asc" }, { startTime: "asc" }],
  });

  return ok(res, schedules.map((s) => ({
    id: s.id,
    doctor_id: s.doctorId,
    day_of_week: s.dayOfWeek,
    start_time: s.startTime,
    end_time: s.endTime,
    is_available: s.isAvailable,
  })));
}

async function updateSchedule(req, res) {
  const doctorId = Number(req.params.id);
  const scheduleId = Number(req.params.schedule_id);
  if (!Number.isFinite(doctorId) || !Number.isFinite(scheduleId)) return fail(res, 400, "Invalid id");
  const forbidden = requireSelfDoctor(req, res, doctorId);
  if (forbidden) return forbidden;

  const body = scheduleCreateSchema.partial().parse(req.body);
  if (body.start_time && body.end_time) {
    const start = parseTimeToMinutes(body.start_time);
    const end = parseTimeToMinutes(body.end_time);
    if (start === null || end === null || start >= end) return fail(res, 422, "Invalid time range");
  }

  const existing = await prisma.doctorSchedule.findUnique({ where: { id: scheduleId } });
  if (!existing || existing.doctorId !== doctorId) return fail(res, 404, "Not found");

  const schedule = await prisma.doctorSchedule.update({
    where: { id: scheduleId },
    data: {
      dayOfWeek: body.day_of_week,
      startTime: body.start_time,
      endTime: body.end_time,
      isAvailable: body.is_available,
    },
  });

  return ok(res, {
    id: schedule.id,
    doctor_id: schedule.doctorId,
    day_of_week: schedule.dayOfWeek,
    start_time: schedule.startTime,
    end_time: schedule.endTime,
    is_available: schedule.isAvailable,
  });
}

async function deleteSchedule(req, res) {
  const doctorId = Number(req.params.id);
  const scheduleId = Number(req.params.schedule_id);
  if (!Number.isFinite(doctorId) || !Number.isFinite(scheduleId)) return fail(res, 400, "Invalid id");
  const forbidden = requireSelfDoctor(req, res, doctorId);
  if (forbidden) return forbidden;

  const existing = await prisma.doctorSchedule.findUnique({ where: { id: scheduleId } });
  if (!existing || existing.doctorId !== doctorId) return fail(res, 404, "Not found");

  await prisma.doctorSchedule.delete({ where: { id: scheduleId } });
  return ok(res, true, "Deleted");
}

module.exports = { createSchedule, listSchedules, updateSchedule, deleteSchedule };
