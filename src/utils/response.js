function ok(res, data, message) {
  return res.json({ success: true, message: message || null, data });
}

function fail(res, statusCode, message, errors) {
  return res.status(statusCode).json({
    success: false,
    message,
    errors: errors || null,
  });
}

module.exports = { ok, fail };

