# Stream Token Server

Small backend to generate Stream Chat JWT tokens safely.

## 1) Setup

1. Copy `.env.example` to `.env`.
2. Set your values:
   - `STREAM_API_KEY`
   - `STREAM_API_SECRET` (from Stream dashboard, keep private)

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
