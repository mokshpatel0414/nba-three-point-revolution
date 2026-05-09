# NBA Three-Point Revolution: A SQL Analysis (2000-2023)

A SQL-driven analysis of how three-point shooting reshaped the modern NBA,
using 22+ seasons of regular-season and playoff game data.

## Headline Finding

**Teams didn't get better at three-pointers. They just shot dramatically more of them.**

|                          | 2000-01     | 2022-23      | Change          |
|--------------------------|-------------|--------------|-----------------|
| 3PA per team per game    | 13.71       | 34.21        | **+150%**       |
| % of shots from three    | 17.0%       | 38.8%        | **+128%**       |
| 3-point shooting %       | 35.4%       | 36.1%        | virtually flat  |
| Points per team per game | 94.8        | 114.7        | +21%            |

Over two decades, the league-wide 3-point percentage barely moved. Attempts
and scoring went up because of shot selection, not because teams got better
at making the shots.

## Findings Summary

### Q1: League-wide trend
3-point attempts per team-game grew from **13.71 in 2000-01 to 34.21 in 2022-23
(+150%)**. The share of all field-goal attempts taken from three rose from 17%
to 39%. League-wide 3-point efficiency stayed in a tight 34.7% to 36.7% band
the entire time.

### Q2: Who led the revolution?
The **Houston Rockets led the league in 3-point attempts per game in 6 of 7
seasons from 2013-14 through 2019-20**, peaking at 45.4 attempts per game in
2018-19. The Boston Celtics led the early 2000s under Antoine Walker. The best
season for a 3PA leader was the **2015-16 Golden State Warriors**, who finished
73-9 with an 89% win rate. That's the highest leader win rate in the dataset.

### Q3: Did volume = winning?
Within each season, teams in the top half of 3PA volume averaged a higher
win % than teams in the bottom half. But **the gap has decayed dramatically
over time**. The peak gap was **+14.6 percentage points in 2007-08** (Steve
Nash-era Phoenix Suns and the seven-seconds-or-less wave). By the late 2010s
the gap had compressed to near zero, and in **2021-22 it was negative
(-2.3 pp)**: bottom-half teams actually outperformed.

This is alpha decay. Once every team copied the strategy, shooting more threes
stopped being a competitive edge.

### Q4: Does it hold up in the playoffs?
Conventional wisdom says playoff basketball is more conservative. The data
disagrees. **In 15 of 20 seasons, playoff games featured *more* 3-point
attempts per game than regular-season games**. The reason is selection bias.
Teams that reach the playoffs tend to be the league's high-volume 3-point
teams already, so the playoff average gets pulled up. Playoff 3-point
efficiency dropped slightly (median around 0.6 pp), so defenses do tighten,
just less than common wisdom suggests.

## Tools

- **Database:** SQLite (`nba.sqlite`, ~2.5 GB)
- **Source:** [NBA Database on Kaggle](https://www.kaggle.com/datasets/wyattowalsh/basketball)
- **SQL editor:** DBeaver Community
- **Visualization:** Python (pandas, matplotlib, seaborn). *Coming soon.*

## Repository Structure

```
nba-three-point-revolution/
├── README.md                          this file
├── .gitignore
├── sql/
│   ├── 00_data_quality_check.sql      schema discovery + data caveats
│   ├── 01_league_3pt_trend.sql        Q1: league-wide trend
│   ├── 02_3pt_leader_by_season.sql    Q2: team leaders (window functions)
│   ├── 03_volume_vs_winning.sql       Q3: volume vs winning (NTILE split)
│   └── 04_playoffs_vs_regular.sql     Q4: playoffs vs reg season (JOIN)
├── data/
│   ├── 01_league_3pt_trend.csv
│   ├── 02_3pt_leader_by_season.csv
│   ├── 03_volume_vs_winning.csv
│   └── 04_playoffs_vs_regular.csv
├── notebooks/                         (visualization notebook, coming soon)
└── charts/                            (exported charts, coming soon)
```

## SQL techniques demonstrated

- Common table expressions (CTEs), including chained CTEs across multiple steps
- Window functions: `RANK() OVER (PARTITION BY ...)` and `NTILE(2) OVER (...)`
- `UNION ALL` to reshape one-row-per-game data into one-row-per-team-game
- Conditional aggregation with `CASE WHEN`
- `INNER JOIN` between two parallel CTEs
- String parsing with `SUBSTR` and `CAST` to decode the `season_id` field

## Methodology

### Filtering season type

The `game.season_id` column is a 5-character text field where the first digit
encodes season type and the remaining four digits indicate the starting year:

| Prefix | Meaning        |
|--------|----------------|
| `1`    | Preseason      |
| `2`    | Regular season |
| `3`    | All-Star game  |
| `4`    | Playoffs       |

Q1, Q2, and Q3 filter to regular-season games only (`season_id LIKE '2%'`).
Q4 uses both regular-season (`'2%'`) and playoff (`'4%'`) data.

### Per-team-per-game averages

Each row in `game` represents one matchup with both teams' stats on the same
row (`*_home` and `*_away` columns). To produce per-team-per-game averages:

- For league totals (Q1, Q4): home and away values are summed within each
  season and divided by `games_played * 2`.
- For team-level analysis (Q2, Q3): a `UNION ALL` splits each game into two
  team-game rows (one for the home team, one for the away team), which are
  then aggregated to the season-team level.

## Data caveats

Three documented gaps in the source dataset, all confirmed via
[`sql/00_data_quality_check.sql`](sql/00_data_quality_check.sql):

- **2012-13 regular season** is absent from the source dataset. Preseason,
  All-Star, and playoff games for 2012-13 are present, but no regular-season
  games appear under any `season_id` value or within the 2012-10 to 2013-06
  date range. Excluded from all season-level analyses.
- **2001-02 and 2005-06 playoffs** have NULL values in the 3-point shooting
  columns and are excluded from Q4's regular-season-vs-playoffs comparison.
  Q1, Q2, and Q3 are unaffected.
- **2011-12 was lockout-shortened** (990 games vs. the standard 1,230) and
  **2019-20 / 2020-21 were COVID-shortened** (1,059 and 1,080 games). These
  seasons are included in the analysis with a note where relevant.

## Roadmap

- [x] Q1: League-wide 3-point trend over 22 seasons
- [x] Q2: Which teams led the 3-point revolution? (window functions)
- [x] Q3: Does shooting more threes correlate with winning? (NTILE split)
- [x] Q4: Do the same patterns hold in the playoffs? (JOIN of two CTEs)
- [ ] Visualization notebook (matplotlib + seaborn)
- [ ] Final writeup with charts

### Future extensions

- Position-level shift: when did big men start shooting threes? (requires
  joining `play_by_play` shot events to player position data)
- Player-level analysis: career 3PA trajectories for individual stars
- Geographic shot-chart heatmaps using the play-by-play coordinates

## Reproducing this analysis

1. Download the dataset from
   [Kaggle](https://www.kaggle.com/datasets/wyattowalsh/basketball).
2. Open `nba.sqlite` in DBeaver (or any SQLite client).
3. Run the files in `sql/` in numerical order. The
   `00_data_quality_check.sql` file should be run one section at a time
   rather than as a single batch script.
4. Export results to CSV for use in the visualization notebook.
