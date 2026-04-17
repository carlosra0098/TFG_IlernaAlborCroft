# Stream Token Server

Small backend to generate Stream Chat JWT tokens safely.

## 1) Setup

1. Copy `.env.example` to `.env`.
2. Set your values:
   - `STREAM_API_KEY`
   - `STREAM_API_SECRET` (from Stream dashboard, keep private)
  - `IGDB_CLIENT_ID` (Twitch/IGDB Client ID)
  - `IGDB_CLIENT_SECRET` (Twitch/IGDB Client Secret)

Notes:
- IGDB and Stream are independent now.
- If only IGDB keys are configured, `/igdb/search` works and `/stream/token` returns `503`.
- If only Stream keys are configured, `/stream/token` works and `/igdb/search` returns `503`.

## 2) Install

```bash
npm install
```

## 3) Run

```bash
npm start
```

Server starts at `http://localhost:8787`.

## 4) Create token

```bash
curl -X POST http://localhost:8787/stream/token \
  -H "Content-Type: application/json" \
  -d '{"userId":"super-band-9","name":"Super Band"}'
```

Response includes:
- `apiKey`
- `token` (JWT for Stream Chat)

Use `token` in Flutter as `STREAM_CHAT_USER_TOKEN`.

## 5) Search games in IGDB (secure backend proxy)

```bash
curl -X POST http://localhost:8787/igdb/search \
  -H "Content-Type: application/json" \
  -d '{"query":"zelda","limit":10}'
```

Response includes:
- `count`
- `games[]` with fields `igdbId`, `name`, `genre`, `summary`, `rating`, `coverUrl`
