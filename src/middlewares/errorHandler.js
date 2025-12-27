const { ZodError } = require("zod");
const { fail } = require("../utils/response");

function errorHandler(err, req, res, next) {
  if (res.headersSent) return next(err);

  if (err instanceof ZodError) {
    const errors = err.issues.map((i) => ({
      path: i.path.join("."),
      message: i.message,
    }));
    return fail(res, 422, "Validation error", errors);
  }

  // Prisma known errors
  if (err?.code === "P2002") {
    return fail(res, 409, "Duplicate value", { target: err?.meta?.target || null });
  }
  if (err?.code === "P2025") {
    return fail(res, 404, "Not found");
  }

  // eslint-disable-next-line no-console
  console.error(err);
  return fail(res, 500, "Internal server error");
}

module.exports = { errorHandler };

