/**
 * Entry point: load app and start HTTP server.
 * See docs/architecture/SYSTEM_DESIGN.md for component overview.
 */
const app = require("./app");

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.info(`Attendance API listening on port ${PORT}`);
});

module.exports = server;
