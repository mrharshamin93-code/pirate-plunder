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
    const localBestValue = Number(textQuery(request.query?.localBest));
    const localBest = Number.isFinite(localBestValue) && localBestValue > 0
      ? Math.min(Math.floor(localBestValue), 1_000_000_000)
      : 0;
    const requestedName = textQuery(request.query?.playerName).trim().slice(0, 20);
    const localName = requestedName || 'Pirate';

    const leaderboard = await sql`
      SELECT player_name AS name, score, coins, created_at AS "createdAt"
      FROM leaderboard_scores
      ORDER BY score DESC, created_at ASC
      LIMIT 10
    `;

    let personalBest = 0;
    let personalRank = 0;
    let rankWindow: unknown[] = [];

    if (PLAYER_ID.test(playerId)) {
      const personal = await sql`
        WITH player_bests AS (
          SELECT DISTINCT ON (player_id)
            player_id,
            player_name AS name,
            score,
            coins,
            created_at
          FROM leaderboard_scores
          WHERE player_id IS NOT NULL
          ORDER BY player_id, score DESC, created_at ASC
        ),
        ranked AS (
          SELECT
            player_id,
            name,
            score,
            coins,
            created_at,
            row_number() OVER (
              ORDER BY score DESC, created_at ASC, player_id
            )::integer AS rank
          FROM player_bests
        )
        SELECT score, rank
        FROM ranked
        WHERE player_id = ${playerId}::uuid
        LIMIT 1
      `;

      personalBest = Number(personal[0]?.score ?? 0);
      personalRank = Number(personal[0]?.rank ?? 0);

      // The Rank tab should use the player's true saved high-score history even
      // when that best run has not been submitted in the current session. If the
      // device has a newer local best, rank it in-memory without inserting it.
      if (localBest > personalBest) {
        personalBest = localBest;
        rankWindow = await sql`
          WITH player_bests AS (
            SELECT DISTINCT ON (player_id)
              player_id,
              player_name AS name,
              score,
              coins,
              created_at
            FROM leaderboard_scores
            WHERE player_id IS NOT NULL
            ORDER BY player_id, score DESC, created_at ASC
          ),
          candidates AS (
            SELECT
              player_id,
              name,
              score,
              coins,
              created_at,
              false AS is_you
            FROM player_bests
            WHERE player_id <> ${playerId}::uuid

            UNION ALL

            SELECT
              ${playerId}::uuid AS player_id,
              ${localName}::text AS name,
              ${localBest}::integer AS score,
              0::integer AS coins,
              NOW() AS created_at,
              true AS is_you
          ),
          ranked AS (
            SELECT
              player_id,
              name,
              score,
              coins,
              created_at,
              is_you,
              row_number() OVER (
                ORDER BY score DESC, created_at ASC, player_id
              )::integer AS rank
            FROM candidates
          ),
          mine AS (
            SELECT rank
            FROM ranked
            WHERE is_you
            LIMIT 1
          ),
          window_start AS (
            SELECT GREATEST(1, rank - 4)::integer AS first_rank
            FROM mine
          )
          SELECT
            r.name,
            r.score,
            r.coins,
            r.rank,
            r.is_you AS "isYou"
          FROM ranked r
          CROSS JOIN window_start w
          WHERE r.rank >= w.first_rank
          ORDER BY r.rank ASC
          LIMIT 10
        `;

        const mine = rankWindow.find((row) => Boolean((row as { isYou?: unknown }).isYou));
        personalRank = Number((mine as { rank?: unknown } | undefined)?.rank ?? 0);
      } else if (personalRank > 0) {
        rankWindow = await sql`
          WITH player_bests AS (
            SELECT DISTINCT ON (player_id)
              player_id,
              player_name AS name,
              score,
              coins,
              created_at
            FROM leaderboard_scores
            WHERE player_id IS NOT NULL
            ORDER BY player_id, score DESC, created_at ASC
          ),
          ranked AS (
            SELECT
              player_id,
              name,
              score,
              coins,
              created_at,
              row_number() OVER (
                ORDER BY score DESC, created_at ASC, player_id
              )::integer AS rank
            FROM player_bests
          ),
          mine AS (
            SELECT rank
            FROM ranked
            WHERE player_id = ${playerId}::uuid
          ),
          window_start AS (
            SELECT GREATEST(1, rank - 4)::integer AS first_rank
            FROM mine
          )
          SELECT
            r.name,
            r.score,
            r.coins,
            r.rank,
            (r.player_id = ${playerId}::uuid) AS "isYou"
          FROM ranked r
          CROSS JOIN window_start w
          WHERE r.rank >= w.first_rank
          ORDER BY r.rank ASC
          LIMIT 10
        `;
      }
    }

    response.status(200).json({
      leaderboard,
      personalBest,
      personalRank,
      rankWindow,
    });
  } catch {
    response.status(500).json({ error: 'Leaderboard request failed' });
  }
}
