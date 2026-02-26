import express, { Request, Response } from "express";
import mongoose from "mongoose";
import { playground, seedDatabase } from "./Service";

const app = express();
const PORT = process.env.PORT ?? 3000;
const MONGO_URI = process.env.MONGO_URI ?? "mongodb://localhost:27018/app_db";

app.use(express.json());

// Health check (no DB required)
app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Simple API that uses MongoDB
app.get("/api/status", async (_req: Request, res: Response) => {
  try {
    const state = mongoose.connection.readyState;
    const states = ["disconnected", "connected", "connecting", "disconnecting"];
    res.json({
      mongodb: states[state] ?? "unknown",
      readyState: state,
    });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

async function start() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("MongoDB connected");
    // await seedDatabase();
    await playground();
  } catch (err) {
    console.error("MongoDB connection error:", err);
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT}`);
  });
}

start();
