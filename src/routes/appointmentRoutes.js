const express = require("express");
const { asyncHandler } = require("../middlewares/asyncHandler");
const { authenticate, requireRole } = require("../middlewares/auth");
const appointments = require("../controllers/appointmentsController");

const router = express.Router();

router.post("/", authenticate(true), requireRole("patient"), asyncHandler(appointments.createAppointment));
router.get("/", authenticate(true), requireRole("admin"), asyncHandler(appointments.listAppointmentsByDate));
router.get("/:id", authenticate(true), requireRole("admin", "patient", "doctor"), asyncHandler(appointments.getAppointment));
router.put("/:id/confirm", authenticate(true), requireRole("admin", "doctor"), asyncHandler(appointments.confirmAppointment));
router.put("/:id/complete", authenticate(true), requireRole("admin", "doctor"), asyncHandler(appointments.completeAppointment));
router.delete("/:id", authenticate(true), requireRole("admin", "doctor", "patient"), asyncHandler(appointments.cancelAppointment));

module.exports = router;

