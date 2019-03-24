# All-NBA Team Capstone: Milestone Report

## Introduction

Founded in 1946, the National Basketball Association (NBA) is considered to be the premier basketball league in the world. Based in the United States, the NBA boasts millions of viewers not only in North America, but worldwide.

The purpose of this capstone project is to build a machine learning model that will predict the members of the All-NBA first and second teams. This milestone report serves as a mid-project summary of the project, namely the data wrangling and exploratory data analysis.

## Data

The data used is from the [Men's Professional Basketball data set from Kaggle](https://www.kaggle.com/open-source-sports/mens-professional-basketball). The complete data set consists of five main tables and six supplementary tables. For the purpose of this project, only the following data sets are used:

- **master**: biographical information for players and coaches
- **players**: stats for each player, per year
- **awards_players**: player awards, per year
- **player_allstar**: individual player stats for the All-Star Game, per year

### Important Fields and Information

Naturally, much of the pertinent data from Kaggle consist of numerical variables (e.g. points, assists, rebounds), and the majority of the variables in the model will leverage this type of data. There are several categorical variables that will also factor into our model, such as team and position data.

### Limitations (i.e. what questions cannot be answered by the data set?)

The most obvious limitation of the Kaggle data set is that it ends at the 2012 season, which would presumably affect the model accuracy for recent seasons. It also cannot directly capture the true nature of the selection process, which is a point-based voting system amongst a global panel of sportswriters and broadcasters.

The data set also cannot be used to (accurately) predict NBA All-Star teams, which are selected in the middle of the regular season (not to mention involve fan-voting).

## Data Wrangling

As a Kaggle data set, much of the data from the individual tables appeared to be tidy, though several issues arose in the process of further cleaning the data for analysis. Also, in order to leverage as much of the data as possible, it was required that multiple tables be joined, namely yearly player data (*players*), All-Star game data (*player_allstar*), and of course, awards data (*awards_players*). All data wrangling was performed in R using the `dplyr` and `tidyr` packages.

### The *players* Data

The player statistics from the Kaggle data set included observations from before the founding of the NBA, as well as post-season statistics, which doesn't factor into All-NBA team selection (which is decided before the playoffs). These rows were removed first. 

After trimming, general summary statistics were calculated using base R's `summary` function, which brought attention to the fact that offensive/defensive rebounds and 3-point shots were not tracked for all available seasons. As statistics that would no doubt be important to the model, the data set was filtered to include only seasons that tracked every stat. As the NBA didn't begin differentiating offensive vs. defensive rebounds until 1973, this indicated that we should trim the data according to the more restrictive 1979 season, which was the year that the 3-pointer was adopted in the NBA. This was confirmed in R by checking the minimum year for which the total yearly 3-pointers was non-zero.

After selecting relevant features and filtering for complete observations, the data set dimensions were reduced from `(23,751 x 42)` to `(14,577 x 20)`.

### The *master* Data

Since the All-NBA team rosters are selected based on player position (i.e. 1 center, 2 forwards, and 2 guards per team), the data needed to be taken from the **master** data set. After filtering the data for relevant rows and columns, indicator variables were created for each position.

This table also contained the data for the correct player identification code, which is made up of the first five letters of the last name, followed by the first two letters of the first name, followed by a two-digit integer arranged by a player's entry into the league (in case of repeat letter sequences). This master reference served as a vital tool for some coding errors that arose from the All-Star data during the merging of the data sets.

This table, which stored the unique player ID number as *bioID* (as opposed to *playerID* from the player stats data) also foreshadowed the need to rename several variables in the Awards and All-Star game data.

### The *awards_players* and *player_allstar* Data

Similar filters from the *players* data were applied to the Awards and All-Star game data (i.e. `filter(lgID == "NBA", year >= 1979)`). 

For the Awards data, one row was created for each award won by a player, including those in the same year. This lead to some adjustments being made using `dplyr` functions.

The All-Star data would present the most problems during data cleaning (due to coding errors discussed in the next section). Despite the fact that actual game data is recorded in this table, only the combination of playerID and year would be used simply to create an indicator variable for whether or not a player was voted as an All-Star in a particular year.

### Merging the Data

To join the four tables into a single data set ready for analysis, `dplyr::left_join` function was used. `left_join` requires two arguments, `(x, y)`, and returns rows from `x`, and all columns from `x` and `y`, based on a common key (in this case, *playerID* and *year*). In addition, if there are **multiple matches** between the two, **all combinations are returned**. So, when the `left_join` with the All-Star data resulted in a data frame with more than the expected 14,577 rows, it was indicative of something wrong.

Utilizing `anti_join(allstar, players)`, which works similarly to `left_join`, but only returns rows from `allstar` that are not matching values in `players`, it was discovered that there were several incorrect encodings of the playerID's within the All-Star table. The rows from the `anti_join` were cross-referenced with Wikipedia and Basketball-Reference to identify which entries were not properly joined.

After correcting the aforementioned errors, the *allstar* column was summed to verify correctness. The sum was 751, which was 8 rows greater than the expected 743 rows from the All-Star data. Further investigation showed that 10 of these rows were found to be due to All-Star players who were traded (the *players* data set split traded players' into one row for each team), which meant that there were actually 2 more rows unaccounted for. More digging found yet another error from the original All-Star data ("Thomspon" instead of "Thompson"). The final mystery row belonged to the [1991 All-Star game appearance by Magic Johnson](https://en.wikipedia.org/wiki/1992_NBA_All-Star_Game), who didn't actually play during the regular season.

### Data Wrangling Summary

Although the data set appeared to be tidy at first glance, preparing the data to be merged into a single data set ready for analysis caused several issues to arise, primarily inconsistency in naming across tables and more importantly, incorrect and inconsistent player ID coding for several observations (particularly in the All-Star data).

## Exploratory Data Analysis

### First Look
The following figure shows the initial line plots created after summarizing the mean stats per year.

![Lineplots](https://github.com/martij222/capstone-project/blob/master/graphs/lineplots.png)

A cursory glance at these graphs reveals a few things:

1. 3-point shooting became an increasingly important part of the game over the years.
2. Despite the 3-point shooting, the points scored per game decreased overall.
3. Most importantly, **there's a noticeable dive in every statistic in 1998 and 2012**.

Forgetting my NBA history, I had overlooked the fact that there were two "lockouts" that resulted in the shortening of the standard 82-game regular season:

![Games Played Per Season](https://github.com/martij222/capstone-project/blob/master/graphs/gamesperseason.png)

It would be a bad idea to completely omit these seasons, so I instead normalized each stat on a per-game basis. This corrected the issue:

![Lineplots corrected](https://github.com/martij222/capstone-project/blob/master/graphs/lineplotscorrected.png)

### Comparing All-NBA Team Members vs. Non-Members

An interesting question to ask is "**How do All-NBA Team members differ from everyone else?**", and a good place to start answering this question was by plotting the distributions.

![Boxplots of member vs. non-member](https://github.com/martij222/capstone-project/blob/master/graphs/boxplots.png)

![Histograms of member vs. non-member](https://github.com/martij222/capstone-project/blob/master/graphs/histograms.png)

Looking at the stat distributions, it was unsurprising to see that players who made the All-NBA teams typically performed better in just about every facet of the game. A big reason for this, however, is that All-NBA players simply **played much more**, which is readily apparent by looking at the distributions of minutes and games played:

![Playtime](https://github.com/martij222/capstone-project/blob/master/graphs/playtime.png)

Naturally, teams allow their best players to play as much as possible - this also shows by looking at the distributions for personal fouls and turnovers. Additionally, it follows that more playtime means a higher likelihood of injury, and you would be hard-pressed to find many injured players on the All-NBA rosters (look at the distribution of games played!). So, in an attempt to factor in these details, a `healthy` feature was created to indicate whether or not a player played at least 70% of the games in a given season (this was the median of the ratio of games played to games in a season).

An interesting comparison between the two groups was shot percentage, as this stat serves as a kind of "equalizer" (since it isn't strongly correlated with playtime).

![Shot Percentage Densities](https://github.com/martij222/capstone-project/blob/master/graphs/shotpctdensity.png)

The plot above shows a few interesting things:

1. The shapes of the distributions are very similar.
2. Free throw percentage and three point percentage seem to mirror each other about field goal percentage (although this is expected, it's a nice visual).
3. All-NBA players are generally more effective shooters, *except when it comes to 3-pointers*.

The means and medians of each shot percentage are shown below:

```
## Observations: 2
## Variables: 7
## $ distinction     <chr> "All-NBA", "Not"
## $ fgPct_mean      <dbl> 0.4926591, 0.4364386
## $ ftPct_mean      <dbl> 0.7928237, 0.7580955
## $ threePct_mean   <dbl> 0.2962832, 0.3120574
## $ fgPct_median    <dbl> 0.4933212, 0.4389425
## $ ftPct_median    <dbl> 0.7986119, 0.7738095
## $ threePct_median <dbl> 0.3133586, 0.3278689
```

A potential explanation for this could be that All-NBA Team members are better at setting up those shots for their team mates. This idea is supported by the fact that they have many more assists, in general.

## Summary
Although the data set came from Kaggle, there were several issues that came up when preparing the data for analysis, primarily inconsistency in naming across tables and more importantly, incorrect and inconsistent player ID coding for several observations (particularly in the All-Star data).

Exploratory data analysis also showed some issues with the data, particularly with the number of games played per season. This issue was remedied by creating per-game stats, which were then plotted to visualize the distributions of All-NBA Team members versus non-members.

As expected, All-NBA Team members typically had a larger impact on the games they played in, especially considering that they played the majority of those games. This meant more of everything in general, including personal fouls and turnovers. An interesting comparison between the two groups was shot percentage, which showed very similar distributions, and showed that non-members actually averaged a higher three point shot percentage over their All-NBA counterparts!

Detailed reports for [data cleaning](http://rpubs.com/martij222/all-nba-data-wrangling) and [exploratory data analysis](http://rpubs.com/martij222/all-nba-eda) can be found on RPubs.
