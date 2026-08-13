import { neon } from '@neondatabase/serverless';

const PLAYER_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

interface ApiRequest {
  method?: string;
  body?: unknown;
  query?: Record<string, string | string[] | undefined>;
}

interface ApiResponse {
  status: (code: number) => ApiResponse;
  setHeader: (name: string, value: string) => void;
  json: (body: unknown) => void;
  end: () => void;
}

interface ScoreBody {
  name?: unknown;
  score?: unknown;
  coins?: unknown;
  playerId?: unknown;
}

function textQuery(value: string | string[] | undefined): string {
  return Array.isArray(value) ? (value[0] ?? '') : (value ?? '');
}

export default async function handler(request: ApiRequest, response: ApiResponse): Promise<void> {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method === 'OPTIONS') {
    response.status(204).end();
    return;
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    response.status(503).json({ error: 'Leaderboard is not configured' });
    return;
  }

  const sql = neon(databaseUrl);

  try {
    if (request.method === 'POST') {
      const body = (request.body ?? {}) as ScoreBody;
      const name = typeof body.name === 'string' ? body.name.trim().slice(0, 20) : '';
      const score = typeof body.score === 'number' ? Math.floor(body.score) : -1;
      const coins = typeof body.coins === 'number' ? Math.floor(body.coins) : -1;
      const playerId = typeof body.playerId === 'string' ? body.playerId : '';

      if (!name || score < 0 || coins < 0 || !PLAYER_ID.test(playerId)) {
        response.status(400).json({ error: 'Invalid score submission' });
        return;
      }

      await sql`
        INSERT INTO leaderboard_scores (player_name, score, coins, player_id)
        VALUES (${name}, ${score}, ${coins}, ${playerId}::uuid)
      `;
    } else if (request.method !== 'GET') {
      response.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const playerId = textQuery(request.query?.playerId);
    const leaderboard = await sql`
      SELECT player_name AS name, score, coins, created_at AS "createdAt"
      FROM leaderboard_scores
      ORDER BY score DESC, created_at ASC
      LIMIT 10
    `;
    const personal = PLAYER_ID.test(playerId)
      ? await sql`
          SELECT max(score)::integer AS score
          FROM leaderboard_scores
          WHERE player_id = ${playerId}::uuid
        `
      : [{ score: null }];

    response.status(200).json({
      leaderboard,
      personalBest: personal[0]?.score ?? 0,
    });
  } catch {
    response.status(500).json({ error: 'Leaderboard request failed' });
  }
}
