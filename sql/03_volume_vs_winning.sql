-- =============================================================================
-- 03_volume_vs_winning.sql
-- =============================================================================
-- Question: Within each NBA regular season, do teams that shoot more threes
-- win more games? Has that relationship changed over time?
--
-- Method: For each season, split the 30 teams into two halves by 3PA per game
-- (NTILE(2)): "high volume" (top 15) and "low volume" (bottom 15). Compare
-- average win % between the two groups. The gap is the strength of the
-- "more threes = more wins" relationship that season.
--
-- Output columns:
--   season_start_year      - first year of the season (e.g., 2000 for 2000-01)
--   season_label           - human-readable label (e.g., "2000-01")
--   high_3pa_avg_win_pct   - avg win % of teams in the top half by 3PA volume
--   low_3pa_avg_win_pct    - avg win % of teams in the bottom half by 3PA volume
--   win_pct_gap            - high - low (positive = volume wins, negative = inverted)
--
-- The 2012-13 season is absent from the source dataset; see
-- 00_data_quality_check.sql for details.
-- =============================================================================

-- Step 1: turn each game into two team-game rows (home + away on separate rows).
WITH team_games AS (
    SELECT
        CAST(SUBSTR(season_id, 2) AS INTEGER) AS season_start_year,
        team_abbreviation_home                AS team,
        fg3a_home                             AS fg3a,
        CASE WHEN wl_home = 'W' THEN 1 ELSE 0 END AS win
    FROM game
    WHERE season_id LIKE '2%'
      AND CAST(SUBSTR(season_id, 2) AS INTEGER) >= 2000
      AND fg3a_home IS NOT NULL

    UNION ALL

    SELECT
        CAST(SUBSTR(season_id, 2) AS INTEGER),
        team_abbreviation_away,
        fg3a_away,
        CASE WHEN wl_away = 'W' THEN 1 ELSE 0 END
    FROM game
    WHERE season_id LIKE '2%'
      AND CAST(SUBSTR(season_id, 2) AS INTEGER) >= 2000
      AND fg3a_away IS NOT NULL
),

-- Step 2: aggregate to one row per (season, team).
season_team_stats AS (
    SELECT
        season_start_year,
        team,
        COUNT(*)                                AS games,
        ROUND(SUM(fg3a) * 1.0  / COUNT(*), 2)   AS threes_per_game,
        ROUND(SUM(win)  * 100.0 / COUNT(*), 1)  AS win_pct
    FROM team_games
    GROUP BY season_start_year, team
),

-- Step 3: split each season into two halves by 3PA per game.
ranked AS (
    SELECT
        season_start_year,
        team,
        threes_per_game,
        win_pct,
        NTILE(2) OVER (
            PARTITION BY season_start_year
            ORDER BY threes_per_game
        ) AS volume_half     -- 1 = bottom half, 2 = top half
    FROM season_team_stats
)

-- Final: compare avg win % between the two halves, season by season.
SELECT
    season_start_year,
    season_start_year || '-' ||
        SUBSTR(CAST(season_start_year + 1 AS TEXT), 3, 2) AS season_label,
    ROUND(AVG(CASE WHEN volume_half = 2 THEN win_pct END), 1) AS high_3pa_avg_win_pct,
    ROUND(AVG(CASE WHEN volume_half = 1 THEN win_pct END), 1) AS low_3pa_avg_win_pct,
    ROUND(
        AVG(CASE WHEN volume_half = 2 THEN win_pct END) -
        AVG(CASE WHEN volume_half = 1 THEN win_pct END),
        1
    ) AS win_pct_gap
FROM ranked
GROUP BY season_start_year
ORDER BY season_start_year;
