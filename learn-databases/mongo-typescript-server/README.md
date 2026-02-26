# Mongo TypeScript Server

TypeScript + Express server with MongoDB, using Docker Compose for the database.

## Prerequisites

- Node.js 18+
- Docker & Docker Compose

## Quick start

1. **Start MongoDB** (in this directory):

   ```bash
   docker compose up -d
   ```

2. **Install dependencies and run the server**:

   ```bash
   npm install
   npm run dev
   ```

3. **Try the API**:

   - Health: http://localhost:3000/health
   - DB status: http://localhost:3000/api/status

## Scripts

- `npm run dev` – run with ts-node-dev (hot reload)
- `npm run build` – compile TypeScript to `dist/`
- `npm start` – run compiled app (`node dist/index.js`)

## Environment

Copy `.env.example` to `.env` and adjust if needed. Defaults:

- `PORT=3000`
- `MONGO_URI=mongodb://localhost:27018/app_db` (this project’s Compose uses host port **27018** so it doesn’t clash with `learn-databases` MongoDB on 27017)

## Stop MongoDB

```bash
docker compose down
```

To remove the data volume: `docker compose down -v`
