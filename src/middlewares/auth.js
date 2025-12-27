const jwt = require("jsonwebtoken");
const { fail } = require("../utils/response");
const config = require("../config");

function authenticate(required = true) {
  return (req, res, next) => {
    const auth = req.headers.authorization || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;

    if (!token) {
      if (!required) return next();
      return fail(res, 401, "Unauthorized");
    }

    try {
      const payload = jwt.verify(token, config.jwtSecret);
      req.user = payload;
      return next();
    } catch {
      return fail(res, 401, "Invalid token");
    }
  };
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user?.role) return fail(res, 401, "Unauthorized");
    if (!roles.includes(req.user.role)) return fail(res, 403, "Forbidden");
    return next();
  };
}

module.exports = { authenticate, requireRole };

