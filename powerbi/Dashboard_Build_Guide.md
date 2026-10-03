# Movie Analytics Dashboard: open, check and adjust

The dashboard is in this folder in two forms: `Movie_Analytics_Dashboard.pbix` (data loaded, opens directly) and `Movie_Analytics_Dashboard.pbit` (template that rebuilds the data from `data/raw/`). This guide explains how to open it, how it is built and how to adjust any visual. Every number below comes from `Movie-Analytics.ipynb`; use them to check the dashboard.

## 1. Open the dashboard

**Quick view:** double-click `Movie_Analytics_Dashboard.pbix`. The seven pages open with the data already loaded; nothing to configure.

**Rebuild from the source files** (template `.pbit`):

1. Get the project: `git clone https://github.com/koffifidelek59-collab/movie-analytics.git` (or *Code → Download ZIP* on GitHub, then extract). The two source files are in `data\raw\`: `tmdb_5000_credits.csv` (supplied) and `tmdb-movies.csv` (enrichment).
2. Double-click `Movie_Analytics_Dashboard.pbit`. The window **DataFolder** proposes `C:\movie-analytics\data\raw\`, which is right if the project is in `C:\movie-analytics\`. Otherwise paste the full path of the project's `data\raw\` folder **with the final backslash**, then **Load**.
3. If Power BI asks about privacy levels, choose **Organizational** for both files (or File → Options → Current file → Privacy → *Ignore the privacy levels*).
4. Accept the two custom visuals (WordCloud, Scroller) if asked.
5. **File → Save as → .pbix** (this is how `Movie_Analytics_Dashboard.pbix` was produced).

The first load takes about a minute: Power Query reads the 40 MB credits file and unpacks the cast and crew JSON. To change the folder later: Home → Transform data → Edit parameters → DataFolder.

## 2. Data pipeline (Home → Transform data)

| Query | Loaded | Role |
|---|---|---|
| `DataFolder` | parameter | folder of the two CSV files |
| `Credits Raw` | no | reads Source 1, the supplied `tmdb_5000_credits.csv` |
| `TMDb Movies Raw` | no | reads Source 2, `tmdb-movies.csv`; keeps 13 columns; removes 1 duplicated `id` |
| `tmdb_5000_credits` | yes | the supplied file as received: `movie_id`, `title`, number of cast and crew members, `In Analysis` (Yes/No) |
| `TMDb Movies` | yes | the enrichment (10,865 films) |
| `Movies` | yes | inner join `movie_id = id`, 0 → null for budget/revenue/runtime, director and lead actor from the JSON, date, decade, main genre, runtime class, profit, ROI, result |
| `Movie Genres` | yes | one row per film and genre |
| `Movie Directors` | yes | crew members with job = Director |
| `Movie Cast` | yes | cast members with billing order 0, 1, 2 (three first-billed) |

The full M code is in `PowerQuery_pipeline.m`. Every step is visible in the *Applied Steps* pane.

**Using `tmdb_5000_movies.csv` instead of `tmdb-movies.csv`** (if your supervisor provides it): in `TMDb Movies Raw`, change the file name and the column list (`id`, `genres` in JSON, `release_date`, `budget`, `revenue`, `runtime`, `vote_average`, `vote_count`, `popularity`); the genre split and the date steps must then be adapted to that file's formats.

## 3. Model view

| Relationship | Cardinality | Cross filter |
|---|---|---|
| `Movie Genres[Movie ID]` → `Movies[Movie ID]` | many to one | Both |
| `Movie Directors[Movie ID]` → `Movies[Movie ID]` | many to one | Both |
| `Movie Cast[Movie ID]` → `Movies[Movie ID]` | many to one | Both |
| `Movies[Movie ID]` → `tmdb_5000_credits[movie_id]` | many to one | Single |
| `Movies[Movie ID]` → `TMDb Movies[id]` | many to one | Single |

`Movies[Runtime Class]` is sorted by `Runtime Class Order`. `Movies[Weighted Rating]` is a calculated column (IMDb formula, C = mean rating, m = 90th percentile of the votes = 1,354). The 22 measures are in `DAX_measures.dax`.

## 4. Pages

| Page | Visuals |
|---|---|
| Home | 8 KPI cards, word cloud of genres, 3 tiles that open the analysis pages, scrolling top-grossing titles |
| Releases & Genres | films per year (R1), films by genre (R2), average rating by genre and by decade (R3) |
| Box Office | budget vs revenue scatter + trend line (R4), Top 10 grossing (R5), median adjusted revenue per year for years with 20+ films (R7), median ROI by main genre |
| Ratings & Runtime | Top 10 by weighted rating (R6), gauge of the average rating, rating and median revenue by runtime class (R8), average rating per year for years with 20+ films (R7) |
| People | Top 10 directors by revenue, Top 10 actors by number of films, best directors by weighted score (3+ films) |
| Insights | the 10 insights (R11) |
| Data Pipeline | the supplied file as loaded: films, films analysed, match rate, cast and crew entries, donut In Analysis, table of `tmdb_5000_credits`, the pipeline steps |

Slicers (release year, genre, runtime class, financial result) are synchronised across the analysis pages (View → Sync slicers).

## 5. Adjust a visual

- **Change a Top N:** select the visual → Filters pane → the Top N filter on Title, Director or Actor → change 10.
- **Change a threshold (20+ films, 3+ films):** Movies table → the measure `Avg Rating 20+`, `Median Revenue Adj ($M) 20+` or `Director Score (3+ films)` → edit the number.
- **Change colours:** View → Themes → Customize current theme (light blue `#4FB3E8`, navy background `#111923`; chart titles white).
- **Move or resize:** drag the visual and its rounded frame together (select both with Ctrl).
- **Data folder moved:** Home → Transform data → Edit parameters → DataFolder.

## 6. Check before submitting

| Check | Expected value |
|---|---|
| Data Pipeline: films in supplied file | 4,803 |
| Data Pipeline: films analysed / match rate | 3,754 / 78.2% |
| Data Pipeline: cast / crew entries | 106,257 / 129,581 |
| Home, no filter: Movies | 3,754 |
| Total revenue / total budget | $369.5 bn / $130.0 bn |
| Median ROI / % profitable | 2.27x / 76.6% |
| Average rating / average runtime | 6.13 / 109 min |
| Total votes | 1,912,799 |
| Genre = Horror | Avg Rating 5.66 |
| Top grossing film | Avatar ($2.78 bn) |
| Top weighted rating | The Shawshank Redemption (7.97) |
| Best director, 3+ films | Christopher Nolan (7.28) |
| Top actor, 3 first-billed | Robert De Niro (44 films) |
