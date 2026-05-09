-- =============================================================================
-- 00_data_quality_check.sql
-- =============================================================================
-- Purpose: Schema discovery and data-quality investigation for the `game` table.
-- This file documents the checks I ran before writing analysis queries, so any
-- reviewer can reproduce the discovery process and understand the data caveats.
--
-- Source dataset: https://www.kaggle.com/datasets/wyattowalsh/basketball
-- Database file:  nba.sqlite (SQLite)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. List all tables in the database.
-- Goal: get a high-level map of what's available.
-- -----------------------------------------------------------------------------
SELECT name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;


-- -----------------------------------------------------------------------------
-- 2. Row counts for the tables most relevant to season-level analysis.
-- Goal: confirm scale and that key tables are populated.
-- -----------------------------------------------------------------------------
SELECT 'game'   AS table_name, COUNT(*) AS rows FROM game
UNION ALL
SELECT 'player', COUNT(*) FROM player
UNION ALL
SELECT 'team',   COUNT(*) FROM team;


-- -----------------------------------------------------------------------------
-- 3. Inspect the `game` table schema.
-- Goal: identify the columns needed for shooting analysis (fg3a_*, fg3m_*, etc.)
--       and the data types stored.
-- -----------------------------------------------------------------------------
PRAGMA table_info(game);


-- -----------------------------------------------------------------------------
-- 4. Date coverage of the `game` table.
-- Goal: confirm the full historical range of the dataset.
-- -----------------------------------------------------------------------------
SELECT
    MIN(game_date) AS earliest_game,
    MAX(game_date) AS latest_game,
    COUNT(*)       AS total_games
FROM game;


-- -----------------------------------------------------------------------------
-- 5. Decode the `season_id` field.
-- Observation: season_id is a 5-character TEXT field. The first digit encodes
-- season type, the remaining four digits encode the starting calendar year.
--
-- Result of this query showed the prefixes are:
--   1 = preseason
--   2 = regular season
--   3 = All-Star
--   4 = playoffs
-- -----------------------------------------------------------------------------
SELECT
    SUBSTR(season_id, 1, 1) AS season_type_prefix,
    COUNT(*)                AS games,
    MIN(game_date)          AS earliest,
    MAX(game_date)          AS latest
FROM game
GROUP BY season_type_prefix
ORDER BY season_type_prefix;


-- -----------------------------------------------------------------------------
-- 6. Verify the key shooting columns are populated for recent seasons.
-- Goal: confirm fg3a_home, fg3m_home, etc. have real values (not NULL) for
-- modern seasons before relying on them in analysis.
-- -----------------------------------------------------------------------------
SELECT
    game_date,
    season_id,
    team_abbreviation_home,
    pts_home,
    fg3a_home,
    fg3m_home,
    fga_home,
    fgm_home
FROM game
WHERE game_date >= '2022-01-01'
ORDER BY game_date DESC
LIMIT 5;


-- -----------------------------------------------------------------------------
-- 7. Investigate a missing season: 2012-13.
-- Initial Q1 results showed a gap between 2011-12 and 2013-14.
-- These checks rule out NULL values and confirm the regular-season games are
-- genuinely absent from the source dataset.
-- -----------------------------------------------------------------------------

-- 7a. Are there NULLs in the shooting columns for adjacent seasons?
SELECT
    season_id,
    COUNT(*)                                                        AS games,
    SUM(CASE WHEN fg3a_home IS NULL THEN 1 ELSE 0 END)              AS null_3pa_home,
    SUM(CASE WHEN fg3a_away IS NULL THEN 1 ELSE 0 END)              AS null_3pa_away,
    SUM(CASE WHEN fg3a_home IS NULL OR fg3a_away IS NULL THEN 1 
             ELSE 0 END)                                            AS null_either
FROM game
WHERE season_id IN ('22011', '22012', '22013')
GROUP BY season_id
ORDER BY season_id;
-- Result: 22011 = 990 games (lockout-shortened, no nulls), 22013 = 1,230 games
-- (no nulls). 22012 returned no rows at all.


-- 7b. Confirm 2012-13 is missing across all season types and date ranges.
SELECT 'season_id = 22012'        AS source, COUNT(*) AS rows FROM game WHERE season_id = '22012'
UNION ALL
SELECT 'season_id LIKE _2012',    COUNT(*) FROM game WHERE season_id LIKE '_2012'
UNION ALL
SELECT 'date range 2012-10 to 2013-06', COUNT(*) FROM game
    WHERE game_date >= '2012-10-01' AND game_date <= '2013-06-30';
-- Result: 0 rows for season_id = 22012. 203 rows total for the 2012-13 window,
-- which matches preseason (~117) + All-Star (1) + playoffs (85) = 203.
-- Conclusion: the 2012-13 regular season is genuinely absent from this dataset.
-- All season-level analyses below exclude this season and document the gap.
