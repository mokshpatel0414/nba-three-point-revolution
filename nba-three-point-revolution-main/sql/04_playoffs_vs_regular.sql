-- =============================================================================
-- 04_playoffs_vs_regular.sql
-- =============================================================================
-- Question: Do NBA teams shoot more or fewer threes in the playoffs than in
-- the regular season? Has 3-point efficiency held up under playoff defense?
--
-- Method: Build two parallel CTEs — one for regular-season games (season_id
-- prefix '2'), one for playoffs (prefix '4') — then INNER JOIN them on
-- season_start_year so each row compares the same season's reg vs playoffs.
--
-- Output columns:
--   season_start_year             - first year of the season
--   season_label                  - human-readable label (e.g., "2000-01")
--   reg_3pa_per_team_game         - avg 3PA per team-game, regular season
--   playoff_3pa_per_team_game     - avg 3PA per team-game, playoffs
--   playoff_minus_reg_3pa         - playoff volume minus regular-season volume
--   reg_3pt_pct                   - 3-point % in the regular season
--   playoff_3pt_pct               - 3-point % in the playoffs
--   playoff_minus_reg_3pt_pct     - playoff efficiency minus regular-season
--
-- Data caveats:
--   * 2012-13 regular season is absent from the source; see 00_data_quality_check.sql.
--   * 2001-02 and 2005-06 do not appear in this output. The INNER JOIN excludes
--     any season where either side has NULL fg3a values; for those years the
--     playoffs side had nulls in the shooting columns. Documented but not
--     repaired since the gap doesn't affect the long-term trend.
-- =============================================================================

WITH regular_season AS (
    SELECT
        CAST(SUBSTR(season_id, 2) AS INTEGER)   AS season_start_year,
        COUNT(*)                                AS games,
        SUM(fg3a_home + fg3a_away)              AS total_3pa,
        SUM(fg3m_home + fg3m_away)              AS total_3pm,
        SUM(fga_home  + fga_away)               AS total_fga
    FROM game
    WHERE season_id LIKE '2%'                            -- regular season prefix
      AND CAST(SUBSTR(season_id, 2) AS INTEGER) >= 2000
      AND fg3a_home IS NOT NULL
      AND fg3a_away IS NOT NULL
    GROUP BY season_start_year
),

playoffs AS (
    SELECT
        CAST(SUBSTR(season_id, 2) AS INTEGER)   AS season_start_year,
        COUNT(*)                                AS games,
        SUM(fg3a_home + fg3a_away)              AS total_3pa,
        SUM(fg3m_home + fg3m_away)              AS total_3pm,
        SUM(fga_home  + fga_away)               AS total_fga
    FROM game
    WHERE season_id LIKE '4%'                            -- playoffs prefix
      AND CAST(SUBSTR(season_id, 2) AS INTEGER) >= 2000
      AND fg3a_home IS NOT NULL
      AND fg3a_away IS NOT NULL
    GROUP BY season_start_year
)

SELECT
    r.season_start_year,
    r.season_start_year || '-' ||
        SUBSTR(CAST(r.season_start_year + 1 AS TEXT), 3, 2)            AS season_label,
    ROUND(r.total_3pa * 1.0 / (r.games * 2), 2)                        AS reg_3pa_per_team_game,
    ROUND(p.total_3pa * 1.0 / (p.games * 2), 2)                        AS playoff_3pa_per_team_game,
    ROUND(
        p.total_3pa * 1.0 / (p.games * 2) -
        r.total_3pa * 1.0 / (r.games * 2),
        2
    )                                                                  AS playoff_minus_reg_3pa,
    ROUND(r.total_3pm * 100.0 / r.total_3pa, 2)                        AS reg_3pt_pct,
    ROUND(p.total_3pm * 100.0 / p.total_3pa, 2)                        AS playoff_3pt_pct,
    ROUND(
        p.total_3pm * 100.0 / p.total_3pa -
        r.total_3pm * 100.0 / r.total_3pa,
        2
    )                                                                  AS playoff_minus_reg_3pt_pct
FROM regular_season r
INNER JOIN playoffs p
    ON r.season_start_year = p.season_start_year
ORDER BY r.season_start_year;
