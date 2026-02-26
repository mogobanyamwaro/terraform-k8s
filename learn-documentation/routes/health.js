/**
 * Health endpoints for liveness and readiness.
 * See docs/architecture/SYSTEM_DESIGN.md — Observability.
 */
const router = require("express").Router();

// Liveness: process is up
router.get("/", (req, res) => {
  res.status(200).json({ status: "ok" });
});

// Readiness: ready to accept traffic (e.g. DB connected)
// TODO: add DB check when persistence is added
router.get("/ready", (req, res) => {
  res.status(200).json({ status: "ready" });
});

module.exports = router;
