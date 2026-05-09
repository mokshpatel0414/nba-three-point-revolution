# NBA Three-Point Revolution: A SQL Analysis (2000–2023)

A SQL-driven analysis of how three-point shooting reshaped the modern NBA, using
22+ seasons of regular-season game data.

## Headline Finding

**Teams didn't get better at three-pointers — they just shot dramatically more of them.**

|                          | 2000-01     | 2022-23      | Change       |
|--------------------------|-------------|--------------|--------------|
| 3PA per team per game    | 13.71       | 34.21        | **+150%**    |
| % of shots from three    | 17.0%       | 38.8%        | **+128%**    |
| 3-point shooting %       | 35.4%       | 36.1%        | virtually flat |
| Points per team per game | 94.8        | 114.7        | +21%         |

Across two decades, the league-wide 3-point percentage barely moved. The rise
in attempts — and in scoring — came from changes in shot selection, not
shooting talent.

## Tools

- **Database:** SQLite (`nba.sqlite`, ~2.5 GB)
- **Source:** [NBA Database on Kaggle](https://www.kaggle.com/datasets/wyattowalsh/basketball)
- **SQL editor:** DBeaver Community
- **Visualization:** Python (pandas, matplotlib, seaborn) — *coming soon*

## Repository Structure

```
nba-three-point-revolution/
├── README.md                          this file
├── sql/
│   ├── 00_data_quality_check.sql      schema discovery + data caveats
│   └── 01_league_3pt_trend.sql        Q1: league-wide trend
├── data/
│   └── 01_league_3pt_trend.csv        Q1 results (exported from DBeaver)
├── notebooks/                         (visualization notebook — coming soon)
└── charts/                            (exported charts — coming soon)
```

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

All season-level analyses filter to regular-season games only
(`season_id LIKE '2%'`).

### Per-team-per-game averages

Each row in `game` represents one matchup with both teams' stats on the same
row (`*_home` and `*_away` columns). To produce per-team-per-game averages,
home and away values are summed within each season and divided by
`games_played × 2`.

### Data-coverage caveat: 2012-13

The 2012-13 NBA regular season is absent from this dataset. Preseason,
All-Star, and playoff games for 2012-13 are present, but no regular-season
games appear under any `season_id` value or within the 2012-10 to 2013-06
date range. This was confirmed via the queries in
[`sql/00_data_quality_check.sql`](sql/00_data_quality_check.sql).

The 2012-13 season is therefore omitted from all season-level results below.
The gap does not materially affect the 22-year trend findings.

### Other data caveats

- **2011-12** was lockout-shortened (990 games vs. the standard 1,230).
- **2019-20** and **2020-21** were COVID-shortened (1,059 and 1,080 games).

These seasons are included in the analysis but flagged where relevant.

## Roadmap

- [x] Q1 — League-wide 3-point trend over 22 seasons
- [x] Q2 — Which teams led the 3-point revolution? (window functions on team-season ranks)
- [ ] Q3 — Does shooting more threes correlate with winning?
- [ ] Q4 — Position-level shift: when did big men start shooting threes?
- [ ] Visualization notebook (matplotlib + seaborn)
- [ ] Final writeup with charts

## Reproducing this analysis

1. Download the dataset from
   [Kaggle](https://www.kaggle.com/datasets/wyattowalsh/basketball).
2. Open `nba.sqlite` in DBeaver (or any SQLite client).
3. Run the files in `sql/` in numerical order.
4. Export results to CSV for use in the visualization notebook.
