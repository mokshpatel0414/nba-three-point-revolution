-- =============================================================================
-- 01_league_3pt_trend.sql
-- =============================================================================
-- Question: How has league-wide 3-point shooting changed across the 2000-01
-- through 2022-23 NBA regular seasons?
--
-- Output columns:
--   season_start_year             - first year of the season (e.g., 2000 for 2000-01)
--   season_label                  - human-readable label (e.g., "2000-01")
--   games_played                  - regular-season games in the dataset for that year
--   threes_attempted_per_team_game- avg 3PA per team per game
--   threes_made_per_team_game     - avg 3PM per team per game
--   pct_of_shots_from_three       - % of all FG attempts that were 3PA
--   three_point_pct               - league 3P shooting percentage
--   pts_per_team_game             - avg points per team per game
--
-- Notes:
--   * Each row in `game` represents one game with home + away stats on the same
--     row. To get per-team-per-game averages, we sum home and away values and
--     divide by (games_played * 2).
--   * The 2012-13 season is absent from the source dataset; see
--     00_data_quality_check.sql for the investigation.
--   * Season type filtered with season_id LIKE '2%' to keep regular season only.
-- =============================================================================

WITH season_totals AS (
    SELECT
        CAST(SUBSTR(season_id, 2) AS INTEGER) AS season_start_year,
        COUNT(*)                              AS games_played,
        SUM(fg3a_home + fg3a_away)            AS total_3pa,
        SUM(fg3m_home + fg3m_away)            AS total_3pm,
        SUM(fga_home  + fga_away)             AS total_fga,
        SUM(fgm_home  + fgm_away)             AS total_fgm,
        SUM(pts_home  + pts_away)             AS total_pts
    FROM game
    WHERE season_id LIKE '2%'                       -- regular season only
      AND CAST(SUBSTR(season_id, 2) AS INTEGER) >= 2000
      AND fg3a_home IS NOT NULL
      AND fg3a_away IS NOT NULL
    GROUP BY season_start_year
)
SELECT
    season_start_year,
    season_start_year || '-' ||
        SUBSTR(CAST(season_start_year + 1 AS TEXT), 3, 2)     AS season_label,
    games_played,
    ROUND(total_3pa  * 1.0   / (games_played * 2), 2)         AS threes_attempted_per_team_game,
    ROUND(total_3pm  * 1.0   / (games_played * 2), 2)         AS threes_made_per_team_game,
    ROUND(total_3pa  * 100.0 / total_fga,           2)        AS pct_of_shots_from_three,
    ROUND(total_3pm  * 100.0 / total_3pa,           2)        AS three_point_pct,
    ROUND(total_pts  * 1.0   / (games_played * 2), 2)         AS pts_per_team_game
FROM season_totals
ORDER BY season_start_year;
