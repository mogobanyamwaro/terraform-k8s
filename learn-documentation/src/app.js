/**
 * Express application setup.
 * Keeps server.js thin; all middleware and routes are mounted here.
 */
const express = require("express");
const healthRouter = require("../routes/health");

const app = express();

app.use(express.json());

// Correlation ID (for logging/tracing) — placeholder; replace with real middleware
app.use((req, res, next) => {
  req.correlationId = req.get("x-correlation-id") || `req-${Date.now()}`;
  next();
});

// Routes
app.use("/health", healthRouter);
// app.use('/api/v1/attendance', attendanceRouter); // Phase 1

// 404
app.use((req, res) => {
  res.status(404).json({ error: "Not found", path: req.path });
});

// Error handler — keep minimal for now
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error" });
});

module.exports = app;
