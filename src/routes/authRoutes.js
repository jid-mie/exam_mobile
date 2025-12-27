const express = require("express");
const { asyncHandler } = require("../middlewares/asyncHandler");
const { authenticate } = require("../middlewares/auth");
const auth = require("../controllers/authController");

const router = express.Router();

router.post("/register/patient", asyncHandler(auth.registerPatient));
router.post("/register/doctor", asyncHandler(auth.registerDoctor));
router.post("/login", asyncHandler(auth.login));
router.get("/me", authenticate(true), asyncHandler(auth.me));

module.exports = router;

