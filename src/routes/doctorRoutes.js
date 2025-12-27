const express = require("express");
const { asyncHandler } = require("../middlewares/asyncHandler");
const { authenticate, requireRole } = require("../middlewares/auth");
const doctors = require("../controllers/doctorsController");
const schedules = require("../controllers/schedulesController");
const appointments = require("../controllers/appointmentsController");

const router = express.Router();

router.get("/", asyncHandler(doctors.listDoctors));
router.get("/:id", asyncHandler(doctors.getDoctor));
router.put("/:id", authenticate(true), requireRole("admin", "doctor"), asyncHandler(doctors.updateDoctor));

router.post("/:id/schedules", authenticate(true), requireRole("doctor"), asyncHandler(schedules.createSchedule));
router.get("/:id/schedules", asyncHandler(schedules.listSchedules));
router.put("/:id/schedules/:schedule_id", authenticate(true), requireRole("doctor"), asyncHandler(schedules.updateSchedule));
router.delete("/:id/schedules/:schedule_id", authenticate(true), requireRole("doctor"), asyncHandler(schedules.deleteSchedule));

router.get("/:id/appointments", authenticate(true), requireRole("admin", "doctor"), asyncHandler(appointments.listDoctorAppointments));

module.exports = router;
