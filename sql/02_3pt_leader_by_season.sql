-- =============================================================================
-- 02_3pt_leader_by_season.sql
-- =============================================================================
-- Question: For each NBA regular season from 2000-01 to 2022-23, which team
-- led the league in 3-point attempts per game? How often did they win?
--
-- Output columns:
--   season_start_year      - first year of the season (e.g., 2000 for 2000-01)
--   season_label           - human-readable label (e.g., "2000-01")
--   leader                 - team abbreviation of that season's 3PA leader
--   leader_3pa_per_game    - the leader's 3-point attempts per game
--   leader_win_pct         - the leader's regular-season win percentage
--
-- Method: Each row in `game` contains both the home and away team's stats.
-- We use UNION ALL to split each game into two team-game rows, then aggregate
-- to season-team totals, then RANK() within each season by 3PA per game.
--
-- The 2012-13 season is absent from the source dataset; see
-- 00_data_quality_check.sql for details.
-- =============================================================================

-- Step 1: turn each game into two team-game rows (home + away on separate rows).
WITH team_games AS (
    SELECT
        CAST(SUBSTR(season_id, 2) AS INTEGER)   AS season_start_year,
        team_abbreviation_home                  AS team,
        fg3a_home                               AS fg3a,
        fg3m_home                               AS fg3m,
        fga_home                                AS fga,
        pts_home                                AS pts,
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
        fg3m_away,
        fga_away,
        pts_away,
        CASE WHEN wl_away = 'W' THEN 1 ELSE 0 END
    FROM game
    WHERE season_id LIKE '2%'
      AND CAST(SUBSTR(season_id, 2) AS INTEGER) >= 2000
      AND fg3a_away IS NOT NULL
),

-- Step 2: aggregate to season-team totals.
season_team_stats AS (
    SELECT
        season_start_year,
        team,
        COUNT(*)                                  AS games,
        SUM(fg3a)                                 AS total_3pa,
        SUM(fg3m)                                 AS total_3pm,
        SUM(fga)                                  AS total_fga,
        SUM(pts)                                  AS total_pts,
        SUM(win)                                  AS wins,
        ROUND(SUM(fg3a) * 1.0  / COUNT(*), 2)     AS threes_per_game,
        ROUND(SUM(win)  * 100.0 / COUNT(*), 1)    AS win_pct
    FROM team_games
    GROUP BY season_start_year, team
),

-- Step 3: rank teams within each season by 3PA per game.
ranked AS (
    SELECT
        season_start_year,
        team,
        games,
        threes_per_game,
        win_pct,
        RANK() OVER (
            PARTITION BY season_start_year
            ORDER BY threes_per_game DESC
        ) AS three_pa_rank_in_season
    FROM season_team_stats
)

-- Final: show the league leader (rank 1) for each season.
SELECT
    season_start_year,
    season_start_year || '-' ||
        SUBSTR(CAST(season_start_year + 1 AS TEXT), 3, 2) AS season_label,
    team                  AS leader,
    threes_per_game       AS leader_3pa_per_game,
    win_pct               AS leader_win_pct
FROM ranked
WHERE three_pa_rank_in_season = 1
ORDER BY season_start_year;
