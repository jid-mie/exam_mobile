require("dotenv").config();

module.exports = {
  port: Number(process.env.PORT || 3000),
  nodeEnv: process.env.NODE_ENV || "development",
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET || "change_me_in_production",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "7d",
  studentId: process.env.STUDENT_ID || "2351060445",
  adminEmail: process.env.ADMIN_EMAIL || "admin@exam.local",
  adminPassword: process.env.ADMIN_PASSWORD || "admin123",
};

