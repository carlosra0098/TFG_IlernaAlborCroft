const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { StreamChat } = require('stream-chat');

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 8787);

const apiKey = process.env.STREAM_API_KEY;
const apiSecret = process.env.STREAM_API_SECRET;
const streamConfigured = Boolean(apiKey && apiSecret);
const igdbClientId = process.env.IGDB_CLIENT_ID || process.env.TWITCH_CLIENT_ID;
const igdbClientSecret =
  process.env.IGDB_CLIENT_SECRET || process.env.TWITCH_CLIENT_SECRET;
const igdbConfigured = Boolean(igdbClientId && igdbClientSecret);

const serverClient = streamConfigured ? StreamChat.getInstance(apiKey, apiSecret) : null;
if (!streamConfigured) {
  console.warn('Stream credentials not configured. /stream/token will return 503, IGDB can still work.');
}

async function safeFetch(url, options) {
  if (typeof fetch === 'function') {
    return fetch(url, options);
  }

  const { default: fetchImpl } = await import('node-fetch');
  return fetchImpl(url, options);
}

let igdbAccessToken = '';
let igdbTokenExpiresAtMs = 0;

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    streamConfigured,
    igdbConfigured,
    igdbClientIdConfigured: Boolean(igdbClientId),
    igdbClientSecretConfigured: Boolean(igdbClientSecret),
  });
});

async function getIgdbAccessToken() {
  if (!igdbConfigured) {
    throw new Error('Missing IGDB/Twitch credentials in environment.');
  }

  const now = Date.now();
  if (igdbAccessToken && now < igdbTokenExpiresAtMs - 30_000) {
    return igdbAccessToken;
  }

  const tokenUrl =
    `https://id.twitch.tv/oauth2/token` +
    `?client_id=${encodeURIComponent(igdbClientId)}` +
    `&client_secret=${encodeURIComponent(igdbClientSecret)}` +
    `&grant_type=client_credentials`;

  const tokenResponse = await safeFetch(tokenUrl, {
    method: 'POST',
  });

  if (!tokenResponse.ok) {
    const details = await tokenResponse.text();
    throw new Error(`Could not get Twitch token: ${tokenResponse.status} ${details}`);
  }

  const tokenJson = await tokenResponse.json();
  const accessToken = String(tokenJson.access_token || '');
  const expiresIn = Number(tokenJson.expires_in || 0);

  if (!accessToken || !expiresIn) {
    throw new Error('Invalid Twitch token response.');
  }

  igdbAccessToken = accessToken;
  igdbTokenExpiresAtMs = now + expiresIn * 1000;
  return igdbAccessToken;
}

app.post('/stream/token', async (req, res) => {
  try {
    if (!streamConfigured || !serverClient) {
      return res.status(503).json({
        error: 'Stream backend no configurado. Define STREAM_API_KEY y STREAM_API_SECRET.',
      });
    }

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
      role: 'admin',
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

app.post('/igdb/search', async (req, res) => {
  try {
    if (!igdbConfigured) {
      return res.status(503).json({
        error: 'IGDB backend no configurado. Define IGDB_CLIENT_ID y IGDB_CLIENT_SECRET.',
      });
    }

    const query = String(req.body?.query || '').trim();
    const limitRaw = Number(req.body?.limit || 12);
    const limit = Number.isFinite(limitRaw)
      ? Math.max(1, Math.min(25, Math.floor(limitRaw)))
      : 12;

    if (!query) {
      return res.status(400).json({
        error: 'query is required',
      });
    }

    const accessToken = await getIgdbAccessToken();
    const igdbBody = [
      'fields id,name,summary,genres.name,rating,first_release_date,cover.url;',
      `search "${query.replaceAll('"', '')}";`,
      'where version_parent = null;',
      `limit ${limit};`,
    ].join(' ');

    const igdbResponse = await safeFetch('https://api.igdb.com/v4/games', {
      method: 'POST',
      headers: {
        'Client-ID': igdbClientId,
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'text/plain',
        Accept: 'application/json',
      },
      body: igdbBody,
    });

    if (!igdbResponse.ok) {
      const details = await igdbResponse.text();
      return res.status(igdbResponse.status).json({
        error: 'IGDB request failed',
        details,
      });
    }

    const games = await igdbResponse.json();
    const mapped = (Array.isArray(games) ? games : [])
      .filter((item) => item && item.id && item.name)
      .map((item) => {
        const firstGenre = Array.isArray(item.genres) && item.genres.length > 0
          ? item.genres[0]?.name
          : null;
        return {
          igdbId: Number(item.id),
          name: String(item.name),
          genre: firstGenre ? String(firstGenre) : 'General',
          summary:
            item.summary && String(item.summary).trim()
              ? String(item.summary)
              : 'Importado desde IGDB.',
          rating: typeof item.rating === 'number' ? item.rating : null,
          coverUrl:
            item.cover && item.cover.url
              ? String(item.cover.url)
                  .replace('//', 'https://')
                  .replace('/t_thumb/', '/t_cover_big/')
              : null,
          releaseDateUnix:
            typeof item.first_release_date === 'number'
              ? item.first_release_date
              : null,
        };
      });

    return res.json({
      query,
      count: mapped.length,
      games: mapped,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Could not fetch IGDB games',
      details: String(error),
    });
  }
});

app.listen(port, () => {
  console.log(`Stream token server running on http://localhost:${port}`);
});
