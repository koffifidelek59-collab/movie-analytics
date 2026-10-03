# Movie Analytics Dashboard

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/koffifidelek59-collab/movie-analytics/blob/main/Movie-Analytics.ipynb)

**What drives the success of a film?** A data pipeline, KPIs, statistical tests and an interactive Power BI dashboard on **3,754 TMDB films (1960-2015)**: volume over the years, genres, ratings, budget and revenue, top films, trends and runtime.

**Author:** KOUAME Koffi Fidèle · Data Analysis Internship (Task 10)

![Home page of the dashboard](figures/dashboard/p1_home.png)

## Key figures (no filter)

| Movies | Total revenue | Total budget | Median ROI | Profitable | Avg rating | Avg runtime |
|---|---|---|---|---|---|---|
| 3,754 | $369.5 bn | $130.0 bn | 2.27x | 76.6% | 6.13 | 109 min |

## Repository structure

```
movie-analytics/
├── Movie-Analytics.ipynb        # Analysis notebook, point by point (runs in < 1 min on a CPU)
├── report.pdf                   # 19-page report with the dashboard captures
├── report.tex                   # LaTeX source of the report
├── data/
│   ├── raw/                     # The two source files (read by the notebook and the dashboard)
│   │   ├── tmdb_5000_credits.csv    # Source 1, supplied: 4,803 films, cast and crew
│   │   └── tmdb-movies.csv          # Source 2, enrichment: year, genres, budget, revenue, rating, runtime
│   └── powerbi/                 # Analysis tables exported by the notebook
│       ├── movies.csv               # one row per film (3,754)
│       ├── movie_genres.csv         # film-genre pairs
│       ├── movie_cast.csv           # film-actor pairs
│       └── movie_directors.csv      # film-director pairs
├── powerbi/
│   ├── Movie_Analytics_Dashboard.pbix   # Power BI dashboard, data loaded: opens directly
│   ├── Movie_Analytics_Dashboard.pbit   # Power BI template (6 tables, 7 pages), reloads data/raw/
│   ├── PowerQuery_pipeline.m            # Power Query (M) code of every query
│   ├── DAX_measures.dax                 # 22 DAX measures and the weighted-rating column
│   ├── Dashboard_Build_Guide.md         # How to open, check and adjust the dashboard
│   └── movie_theme.json                 # Colour theme
├── figures/                     # fig01 to fig10 (notebook and report)
│   └── dashboard/               # Captures of the 7 dashboard pages
└── results/                     # KPI and result tables (CSV)
```

## Data

- **Source 1, supplied:** `tmdb_5000_credits.csv`, from the Kaggle *TMDB 5000 Movie Dataset*, unchanged. It defines the 4,803 films studied and provides titles, actors and directors (cast and crew in JSON).
- **Source 2, enrichment:** `tmdb-movies.csv`, public *TMDb Movies* dataset (10,866 films). The supplied file has no year, genre, budget, revenue, rating or runtime, which the brief asks to analyse; this file provides them. Both files come from TMDb and share the same identifier.
- **Join:** `movie_id = id`, inner join: **3,754 films** of the supplied file (78.2%); most unmatched films are 2016 releases, after the end of Source 2.
- **Cleaning:** budget, revenue and runtime equal to 0 mean *unknown*; ratings are weighted by the vote count (IMDb formula, m = 1,354 votes).

## Run the notebook

**Google Colab:** click the badge above, then *Runtime → Run all*. Missing data files are downloaded from this repository.

**Locally:**
```bash
git clone https://github.com/koffifidelek59-collab/movie-analytics.git
cd movie-analytics
pip install pandas numpy scipy matplotlib jupyter
jupyter notebook Movie-Analytics.ipynb
```
The notebook regenerates `data/powerbi/`, `figures/` and `results/`.

## Open the dashboard

**Quick view:** double-click `powerbi\Movie_Analytics_Dashboard.pbix`: the seven pages open with the data already loaded.

**Rebuild from the source files:**

1. Clone or download the repository (for example into `C:\movie-analytics\`).
2. Double-click `powerbi\Movie_Analytics_Dashboard.pbit` in Power BI Desktop.
3. In the **DataFolder** window, give the full path of `data\raw\`, ending with a backslash (default: `C:\movie-analytics\data\raw\`), then **Load**.
4. If asked about privacy levels, choose **Organizational** for both files; accept the custom visuals (WordCloud, Scroller).
5. Check the page **Data Pipeline**: 4,803 films supplied, 3,754 analysed (78.2%).

Seven pages: **Home · Releases & Genres · Box Office · Ratings & Runtime · People · Insights · Data Pipeline**, with eight KPI cards, four synchronised slicers (year, genre, runtime class, financial result), Top N filters, a page navigator and clickable tiles. All the preparation runs in Power Query: the Table view lists `tmdb_5000_credits` (the supplied file), `TMDb Movies` and the four analysis tables. Details in [`powerbi/Dashboard_Build_Guide.md`](powerbi/Dashboard_Build_Guide.md).

## Main insights

1. Production exploded after 2000: 72% of the films, 150-200 a year.
2. Drama, Comedy, Thriller and Action dominate the catalogue.
3. Genre shapes the rating: Documentary (6.73), War and History lead; Horror (5.66) is the lowest.
4. Money buys revenue, not acclaim: budget and revenue are strongly linked (ρ = 0.65), budget and rating are not (ρ = -0.08).
5. The typical film is profitable: median ROI 2.27x, 76.6% recover their budget.
6. Franchise blockbusters rule the box office (Avatar, Titanic, The Avengers).
7. The best films are widely seen: The Shawshank Redemption, The Dark Knight and The Godfather lead the weighted ranking.
8. The typical film is not richer than thirty years ago in inflation-adjusted dollars.
9. Longer films are better rated and earn more (5.69 below 90 min, 6.93 above 150 min).
10. A few directors concentrate the box office: Spielberg ($9.0 bn), Peter Jackson, James Cameron.

## Tools

Python (pandas, NumPy, SciPy, Matplotlib) · Jupyter / Google Colab · Power BI Desktop (Power Query, DAX) · LaTeX

## License

Code and documentation: [MIT](LICENSE). The data files keep the terms of their sources (TMDb, Kaggle *TMDB 5000 Movie Dataset*, public *TMDb Movies* dataset).

## Contact

KOUAME Koffi Fidèle · koffifidelek59@gmail.com
