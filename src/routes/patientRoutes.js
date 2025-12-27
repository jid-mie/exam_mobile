const express = require("express");
const { asyncHandler } = require("../middlewares/asyncHandler");
const { authenticate, requireRole } = require("../middlewares/auth");
const patients = require("../controllers/patientsController");
const appointments = require("../controllers/appointmentsController");

const router = express.Router();

router.get("/", authenticate(true), requireRole("admin"), asyncHandler(patients.listPatients));
router.get("/:id", authenticate(true), requireRole("admin", "patient"), asyncHandler(patients.getPatient));
router.put("/:id", authenticate(true), requireRole("admin", "patient"), asyncHandler(patients.updatePatient));
router.get("/:id/appointments", authenticate(true), requireRole("admin", "patient"), asyncHandler(appointments.listPatientAppointments));

module.exports = router;

