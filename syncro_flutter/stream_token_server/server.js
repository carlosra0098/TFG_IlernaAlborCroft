const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { StreamChat } = require('stream-chat');

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 8787);

const apiKey = process.env.STREAM_API_KEY;
const apiSecret = process.env.STREAM_API_SECRET;

if (!apiKey || !apiSecret) {
  console.error('Missing STREAM_API_KEY or STREAM_API_SECRET in environment.');
  process.exit(1);
}

const serverClient = StreamChat.getInstance(apiKey, apiSecret);

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.post('/stream/token', async (req, res) => {
  try {
    const userId = String(req.body?.userId || '').trim();

    if (!userId) {
      return res.status(400).json({
        error: 'userId is required',
      });
    }

    const token = serverClient.createToken(userId);

    await serverClient.upsertUser({
      id: userId,
      name: String(req.body?.name || userId),
      image: String(req.body?.image || ''),
    });

    return res.json({
      userId,
      apiKey,
      token,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Could not create stream token',
      details: String(error),
    });
  }
});

app.listen(port, () => {
  console.log(`Stream token server running on http://localhost:${port}`);
});
