// =====================================================================
// Movie Analytics Dashboard (Task 10) - Power Query (M) of every query
// Visible in Power BI: Home > Transform data > Advanced Editor
// =====================================================================

// ---------------- DataFolder  (parameter)
"C:\movie-analytics\data\raw\" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// ---------------- Credits Raw  (staging query, not loaded)
let
    Source = Csv.Document(File.Contents(DataFolder & "tmdb_5000_credits.csv"), [Delimiter = ",", Columns = 4, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"movie_id", Int64.Type}, {"title", type text}, {"cast", type text}, {"crew", type text}}, "en-US")
in
    #"Changed Type"

// ---------------- TMDb Movies Raw  (staging query, not loaded)
let
    Source = Csv.Document(File.Contents(DataFolder & "tmdb-movies.csv"), [Delimiter = ",", Columns = 21, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    #"Kept Columns" = Table.SelectColumns(#"Promoted Headers", {"id", "original_title", "popularity", "budget", "revenue", "runtime", "genres", "release_date", "vote_count", "vote_average", "release_year", "budget_adj", "revenue_adj"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Kept Columns", {{"id", Int64.Type}, {"original_title", type text}, {"popularity", type number}, {"budget", type number}, {"revenue", type number}, {"runtime", type number}, {"genres", type text}, {"release_date", type text}, {"vote_count", Int64.Type}, {"vote_average", type number}, {"release_year", Int64.Type}, {"budget_adj", type number}, {"revenue_adj", type number}}, "en-US"),
    #"Removed Duplicates" = Table.Distinct(#"Changed Type", {"id"})
in
    #"Removed Duplicates"

// ---------------- Movies  (loaded table)
let
    Credits = Table.SelectColumns(#"Credits Raw", {"movie_id", "title", "cast", "crew"}),
    Joined = Table.NestedJoin(Credits, {"movie_id"}, #"TMDb Movies Raw", {"id"}, "tmdb", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Joined, "tmdb", {"release_year", "release_date", "genres", "budget", "revenue", "budget_adj", "revenue_adj", "vote_average", "vote_count", "runtime", "popularity"}),
    #"Zero As Unknown" = Table.TransformColumns(Expanded, {{"budget", each if _ = 0 then null else _, type nullable number}, {"revenue", each if _ = 0 then null else _, type nullable number}, {"budget_adj", each if _ = 0 then null else _, type nullable number}, {"revenue_adj", each if _ = 0 then null else _, type nullable number}, {"runtime", each if _ = 0 then null else _, type nullable number}}),
    Director = Table.AddColumn(#"Zero As Unknown", "Director", each let d = List.Transform(List.Select(Json.Document([crew]), (p) => Record.FieldOrDefault(p, "job", "") = "Director"), (p) => p[name]) in if List.IsEmpty(d) then "Unknown" else Text.Combine(d, ", "), type text),
    #"Lead Actor" = Table.AddColumn(Director, "Lead Actor", each let c = List.Sort(Json.Document([cast]), (a, b) => Value.Compare(a[order], b[order])) in if List.IsEmpty(c) then "Unknown" else c{0}[name], type text),
    #"Release Date" = Table.AddColumn(#"Lead Actor", "Release Date", each try let p = Text.Split([release_date], "/") in #date([release_year], Number.From(p{0}), Number.From(p{1})) otherwise null, type nullable date),
    Decade = Table.AddColumn(#"Release Date", "Decade", each Text.From(Number.IntegerDivide([release_year], 10) * 10) & "s", type text),
    #"Main Genre" = Table.AddColumn(Decade, "Main Genre", each if [genres] = null or [genres] = "" then "Unknown" else Text.Split([genres], "|"){0}, type text),
    #"Runtime Class" = Table.AddColumn(#"Main Genre", "Runtime Class", each let r = [runtime] in if r = null then "Unknown" else if r <= 90 then "< 90 min" else if r <= 105 then "90-105 min" else if r <= 120 then "105-120 min" else if r <= 150 then "120-150 min" else "> 150 min", type text),
    #"Runtime Class Order" = Table.AddColumn(#"Runtime Class", "Runtime Class Order", each let r = [runtime] in if r = null then 6 else if r <= 90 then 1 else if r <= 105 then 2 else if r <= 120 then 3 else if r <= 150 then 4 else 5, Int64.Type),
    Profit = Table.AddColumn(#"Runtime Class Order", "Profit", each if [budget] = null or [revenue] = null then null else [revenue] - [budget], type nullable number),
    ROI = Table.AddColumn(Profit, "ROI", each if [budget] = null or [revenue] = null then null else [revenue] / [budget], type nullable number),
    Result = Table.AddColumn(ROI, "Result", each if [Profit] = null then "Unknown" else if [Profit] > 0 then "Profitable" else "Loss-making", type text),
    Renamed = Table.RenameColumns(Result, {{"movie_id", "Movie ID"}, {"title", "Title"}, {"release_year", "Release Year"}, {"runtime", "Runtime"}, {"budget", "Budget"}, {"revenue", "Revenue"}, {"budget_adj", "Budget Adj"}, {"revenue_adj", "Revenue Adj"}, {"vote_average", "Rating"}, {"vote_count", "Votes"}, {"popularity", "Popularity"}}),
    Final = Table.SelectColumns(Renamed, {"Movie ID", "Title", "Release Year", "Release Date", "Decade", "Main Genre", "Director", "Lead Actor", "Runtime", "Runtime Class", "Runtime Class Order", "Budget", "Revenue", "Budget Adj", "Revenue Adj", "Profit", "ROI", "Result", "Rating", "Votes", "Popularity"})
in
    Final

// ---------------- Movie Genres  (loaded table)
let
    Ids = List.Buffer(#"Credits Raw"[movie_id]),
    Selected = Table.SelectRows(#"TMDb Movies Raw", each List.Contains(Ids, [id]) and [genres] <> null and [genres] <> ""),
    Kept = Table.SelectColumns(Selected, {"id", "genres"}),
    Split = Table.TransformColumns(Kept, {{"genres", each Text.Split(_, "|")}}),
    Expanded = Table.ExpandListColumn(Split, "genres"),
    Renamed = Table.RenameColumns(Expanded, {{"id", "Movie ID"}, {"genres", "Genre"}}),
    Typed = Table.TransformColumnTypes(Renamed, {{"Movie ID", Int64.Type}, {"Genre", type text}})
in
    Typed

// ---------------- Movie Directors  (loaded table)
let
    Ids = List.Buffer(#"TMDb Movies Raw"[id]),
    Selected = Table.SelectRows(#"Credits Raw", each List.Contains(Ids, [movie_id])),
    Names = Table.AddColumn(Selected, "Director", each List.Transform(List.Select(Json.Document([crew]), (p) => Record.FieldOrDefault(p, "job", "") = "Director"), (p) => p[name])),
    Kept = Table.SelectColumns(Names, {"movie_id", "Director"}),
    Expanded = Table.ExpandListColumn(Kept, "Director"),
    NonEmpty = Table.SelectRows(Expanded, each [Director] <> null),
    Renamed = Table.RenameColumns(NonEmpty, {{"movie_id", "Movie ID"}}),
    Typed = Table.TransformColumnTypes(Renamed, {{"Movie ID", Int64.Type}, {"Director", type text}})
in
    Typed

// ---------------- Movie Cast  (loaded table)
let
    Ids = List.Buffer(#"TMDb Movies Raw"[id]),
    Selected = Table.SelectRows(#"Credits Raw", each List.Contains(Ids, [movie_id])),
    Leads = Table.AddColumn(Selected, "Lead", each List.Select(Json.Document([cast]), (p) => p[order] < 3)),
    Kept = Table.SelectColumns(Leads, {"movie_id", "Lead"}),
    Expanded = Table.ExpandListColumn(Kept, "Lead"),
    NonEmpty = Table.SelectRows(Expanded, each [Lead] <> null),
    Fields = Table.ExpandRecordColumn(NonEmpty, "Lead", {"name", "order"}, {"Actor", "Billing Order"}),
    Renamed = Table.RenameColumns(Fields, {{"movie_id", "Movie ID"}}),
    Typed = Table.TransformColumnTypes(Renamed, {{"Movie ID", Int64.Type}, {"Actor", type text}, {"Billing Order", Int64.Type}})
in
    Typed

// ---------------- tmdb_5000_credits  (loaded table)
let
    Source = #"Credits Raw",
    Ids = List.Buffer(#"TMDb Movies Raw"[id]),
    #"Cast Members" = Table.AddColumn(Source, "Cast Members", each List.Count(Json.Document([cast])), Int64.Type),
    #"Crew Members" = Table.AddColumn(#"Cast Members", "Crew Members", each List.Count(Json.Document([crew])), Int64.Type),
    #"In Analysis" = Table.AddColumn(#"Crew Members", "In Analysis", each if List.Contains(Ids, [movie_id]) then "Yes" else "No", type text),
    Result = Table.SelectColumns(#"In Analysis", {"movie_id", "title", "Cast Members", "Crew Members", "In Analysis"})
in
    Result

// ---------------- TMDb Movies  (loaded table)
let
    Source = #"TMDb Movies Raw",
    Result = Table.SelectColumns(Source, {"id", "original_title", "release_year", "genres", "budget", "revenue", "vote_average", "vote_count", "runtime"})
in
    Result
