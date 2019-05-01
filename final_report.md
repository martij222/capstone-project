# All-NBA Team Capstone: Final Report

## 1. Introduction

Founded in 1946, the National Basketball Association (NBA) is considered to be the premier basketball league in the world. Based in the United States, the NBA boasts millions of viewers not only in North America, but worldwide. Popularity has also surged in recent years; [total revenue increased by 8.5% over the previous season, hitting the $8 billion mark](https://www.forbes.com/sites/kurtbadenhausen/2019/02/06/nba-team-values-2019-knicks-on-top-at-4-billion/). 

The purpose of this capstone project is to build a machine learning model that will predict the 15 members of the All-NBA team roster. The results can be of interest to sportsbetters, general basketball fans, and with [recent changes to the Collective Bargaining Agreement and salary cap rules](https://www.sportskeeda.com/basketball/all-nba-teams-the-who-what-when-why-and-how), it could even be of interest to team Front-Offices.

This report summarizes each phase of the project, namely the data wrangling, exploratory data analysis, and the buildling of the predictive model.

## 2. Data

The data used is from the [Men's Professional Basketball data set from Kaggle](https://www.kaggle.com/open-source-sports/mens-professional-basketball). The complete data set consists of five main tables and six supplementary tables. For the purpose of this project, only the following data sets are used:

- **master**: biographical information for players and coaches
- **players**: stats for each player, per year
- **awards_players**: player awards, per year
- **player_allstar**: individual player stats for the All-Star Game, per year

Additional data is scraped from [Basketball-Reference](https://www.basketball-reference.com/leagues/NBA_2019_totals.html) and used to predict the All-NBA rosters for the 2018-2019 regular season.

### 2.1 Important Fields and Information

Naturally, much of the pertinent data from Kaggle consist of numerical variables (e.g. points, assists, rebounds), and the majority of the variables in the model will leverage this type of data. There are several categorical variables that will also factor into our model, such as team and position data.

### 2.2 Limitations (i.e. what questions cannot be answered by the data set?)

The most obvious limitation of the Kaggle data set is that it ends at the 2012 season, which would presumably affect the model accuracy for recent seasons. It also cannot directly capture the true nature of the selection process, which is a point-based voting system amongst a global panel of sportswriters and broadcasters. Additonally, since voting takes place during the Playoffs, we can reasonably assume that post-season performance affects voting to some degree, which we can't capture due to not including post-season data. The data set also cannot be used to (accurately) predict NBA All-Star teams, which are selected in the middle of the regular season (not to mention involve fan-voting).

## 3. Data Wrangling

As a Kaggle data set, much of the data from the individual tables appeared to be tidy, though several issues arose in the process of further cleaning the data for analysis. Also, in order to leverage as much of the data as possible, it was required that multiple tables be joined, namely yearly player data (*players*), All-Star game data (*player_allstar*), and of course, awards data (*awards_players*). All data wrangling was performed in R using the `dplyr` and `tidyr` packages.

### 3.1 The *players* Data

The player statistics from the Kaggle data set included observations from before the founding of the NBA, as well as post-season statistics, which doesn't factor into All-NBA team selection (which is decided before the playoffs). These rows were removed first. 

After trimming, general summary statistics were calculated using base R's `summary` function, which brought attention to the fact that offensive/defensive rebounds and 3-point shots were not tracked for all available seasons. As statistics that would no doubt be important to the model, the data set was filtered to include only seasons that tracked every stat. As the NBA didn't begin differentiating offensive vs. defensive rebounds until 1973, this indicated that we should trim the data according to the more restrictive 1979 season, which was the year that the 3-pointer was adopted in the NBA. This was confirmed in R by checking the minimum year for which the total yearly 3-pointers was non-zero.

After selecting relevant features and filtering for complete observations, the data set dimensions were reduced from `(23,751 x 42)` to `(14,577 x 20)`.

### 3.2 The *master* Data

Since the All-NBA team rosters are selected based on player position (i.e. 1 center, 2 forwards, and 2 guards per team), the position data needed to be taken from the **master** data set. After filtering the data for relevant rows and columns, indicator variables were created for each position.

This table also contained the data for the correct player identification code, which is made up of the first five letters of the last name, followed by the first two letters of the first name, followed by a two-digit integer arranged by a player's entry into the league (in case of repeat letter sequences). This master reference served as a vital tool for some coding errors that arose from the All-Star data during the merging of the data sets.

This table, which stored the unique player ID number as *bioID* (as opposed to *playerID* from the player stats data) also foreshadowed the need to rename several variables in the Awards and All-Star game data.

### 3.3 The *awards_players* and *player_allstar* Data

Similar filters from the *players* data were applied to the Awards and All-Star game data (i.e. `filter(lgID == "NBA", year >= 1979)`). 

For the Awards data, one row was created for each award won by a player, including those in the same year. These rows were combined into a single cell which listed every award won in a given season and simplified the creation of indicator variables for each award using `dplyr` functions.

The All-Star data would present the most problems during data cleaning (due to coding errors discussed in the next section). Despite the fact that actual All-Star game stats are recorded in this table, only the combination of playerID and year would be used - simply to create an indicator variable for whether or not a player was voted as an All-Star in a particular year.

### 3.4 Merging the Data

To join the four tables into a single data set ready for analysis, `dplyr::left_join` function was used. `left_join` requires two arguments, `(x, y)`, and returns rows from `x`, and all columns from `x` and `y`, based on a common key (in this case, *playerID* and *year*). In addition, if there are **multiple matches** between the two, **all combinations are returned**. So, when the `left_join` with the All-Star data resulted in a data frame with more than the expected 14,577 rows, it was indicative of something wrong.

Utilizing `anti_join(allstar, players)`, which works similarly to `left_join`, but only returns rows from `allstar` that are **not** matching values in `players`, it was discovered that there were several incorrect encodings of the playerID's within the All-Star table. The rows from the `anti_join` were cross-referenced with Wikipedia and Basketball-Reference to identify which entries were not properly joined.

After correcting the aforementioned errors, the *allstar* column was summed to verify correctness. The sum was 751, which was 8 rows greater than the expected 743 rows from the All-Star data. Further investigation showed that 10 of these rows were found to be due to All-Star players who were traded (the *players* data set split traded players' into one row for each team), which meant that there were actually 2 more rows unaccounted for. More digging found yet another error from the original All-Star data ("Thomspon" instead of "Thompson"). The final mystery row belonged to the [1991 All-Star game appearance by Magic Johnson](https://en.wikipedia.org/wiki/1992_NBA_All-Star_Game), who didn't actually play during the regular season.

### 3.5 Data Wrangling Summary

Although the data set appeared to be tidy at first glance, preparing the data to be merged into a single data set ready for analysis caused several issues to arise, primarily inconsistency in naming across tables and more importantly, incorrect and inconsistent player ID coding for several observations (particularly in the All-Star data).

### 3.6 2019 Regular Season Data

There is an abundance of game data available from Basketball-Reference that we can use to improve our current model, but only [regular season stat totals](https://www.basketball-reference.com/leagues/NBA_2019_totals.html) was scraped since it matched the information provided by the Kaggle data. Scraping was done in R using the `rvest` package. 

Actual stats were scraped as character data. These were converted to numerical data before being rearranged and renamed to exactly match the format and ordering of the Kaggle data. Creating the All-Star indicator required scraping of the [All-Star webpage](https://www.basketball-reference.com/allstar/NBA_2019.html), as well. The data was then processed identically to the original Kaggle data so that it could be easily used with the finished predictive model. 

## 4. Exploratory Data Analysis

### 4.1 First Look
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

### 4.2 Comparing All-NBA Team Members vs. Non-Members

An interesting question to ask is "**How do All-NBA Team members differ from everyone else?**", and a good place to start answering this question was by plotting their respective distributions.

![Boxplots of member vs. non-member](https://github.com/martij222/capstone-project/blob/master/graphs/boxplots.png)

![Histograms of member vs. non-member](https://github.com/martij222/capstone-project/blob/master/graphs/histograms.png)

It was unsurprising to see that, from a raw numbers standpoint, players who made the All-NBA teams typically performed better in just about every facet of the game. A big reason for this, however, is that All-NBA players simply **played much more**, which is readily apparent by looking at the distributions of minutes and games played:

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

## 5. Machine Learning

Three binary classifiers (i.e. All-NBA or Not All-NBA) were created in R using logistic regression and the `glmnet` package. Player data was initially split into a training and test set at a standard 80% - 20%, respectively. However, given the nature of the data, as well as the purpose of the model, all but the last available season (2011-2012) were used as training data. The 2011-2012 season was used as the test set. Note that, results were initially compared for both scenarios. The predicted line-ups did not change much, but each player had an increased probability relative to the 80% - 20% split. Details are presented and discussed in Section 5.6.1 below.

### 5.1 Data Pre-Processing

As with all machine learning algorithms, the data had to be in a particular format before being input. Namely:

1. **Label Encoding**: Though most of our data is numerical, some of our features, including our outcome, are categorical (i.e. `awards`, `healthy`), and thus needed to be converted to indicator variables. This step was performed during data wrangling.
2. **Data Splitting**: As mentioned above, the data was split into a training set that contained every season except the last, which was used as our test set.
3. **Scaling**: The features in the final data set have variable ranges and should be scaled. This is handled automatically by the `glmnet` function.

### 5.2 Regularization

The cleaned data frame had 64 features, many of which were engineered from the original raw statistics. Manually sorting out significant variables would not only be time consuming, but very difficult due to the many engineered features since many of our variables are correlated with one another. To address this issue, we created regularized regression models. **Regularization** is a technique used to prevent model overfitting by imposing a penalty on model coefficients. There are 3 commonly used penalized regression models considered:

1. *LASSO*: only the most significant features are kept (**automatic feature selection**)
2. *Ridge*: all features are kept, but less contributive ones are set really low (**feature shrinkage**)
3. *Elastic-Net*: a combination of the above

The elastic-net mixing parameter, `alpha`, defines the particular type of regularization: `alpha = 1` is lasso and `alpha = 0` is ridge. These are implemented these using the `glmnet` package and adjusting the `alpha` argument. The "strength" of the penalty for all 3 models is dependent on `lambda`.

### 5.3 Threshold Value

With a logistic regression model, we would normally choose a *threshold value* for the logit (i.e. probability) that determines membership of the positive (`allNBA = 1`) or negative class (`allNBA = 0`). For instance, if the threshold value is 0.50, our model would label `allNBA = 1` for probabilities greater than 0.50. 

In practice, the selection of a threshold value is a **business decision** that depends upon the willingness to accept false positives (or false negatives). In our case, there is obviously no consequence for setting our threshold higher or lower. More importantly, however, there are a couple constraints we have to consider regarding the selection of the All-NBA team that we didn't build into our model:

1. Each All-NBA team roster must have 2 forwards, 2 guards, and 1 center.
2. Players who play "hybrid" positions (e.g. C-F, F-G) can be awarded honors in one position or another, depending on how votes shape up.

So, rather than set a threshold value, we'll simply group by player position and sort by descending probability and determine members based on rank. In the ideal case of correctly identifying all 15 unique members: **the top 6 players in the guard and forward lists** and **the top 3 players in the center list** make up all 3 rosters. Of course, because of how player positions are encoded in the data, there may be some overlap that we'll have to look out for.

### 5.4 k-fold Cross-Validation

**Cross-validation** is a technique used to gauge model performance on out-of-sample data. In particular, k-fold cross-validation is done by partitioning data into *k* subsets, of which the model is trained on all but one "holdout" set for different possible values of a parameter. In this regard, it can be used to help choose between alternative models. Using test data to tune parameters implicitly trains the model on that test data, so cross-validation is done using only the training data.

k-fold cross-validation can be performed using the `cv.glmnet` function in `glmnet`. The default is 10-fold (k = 10).

### 5.5 Evaluation Criteria

#### 5.5.1 Area Under the ROC Curve

All things considered, we'll simply want our model to have the best sorting ability (as opposed to evaluating model performance by accuracy, specificity, recall, etc). To characterize this in a way that is insensitive to unbalanced classes (as in our case), we use **Area under the ROC curve (AUC)** as the criterion for cross-validation. The **receiver operating characteristic (ROC)** curve is a plot of *true positive rate* (TPR) against *false positive rate* (FPR) at various threshold values. In the context of our problem, the AUC describes the probability that, given a random player, our model can distinguish between an All-NBA team member and non-member.

Using AUC as our performance metric is done by adding the argument `type.measure = "auc"` to the `cv.glmnet` call.

#### 5.5.2 Area Under the Precision-Recall Curve

Precision is the ratio of the number of true positives (TP) divided by the sum of true positives and false positives (FP):

![Precision = \frac{TP}{TP + FP}](https://latex.codecogs.com/svg.latex?Precision%20%3D%20%5Cfrac%7BTP%7D%7BTP%20&plus;%20FP%7D)

It basically describes the **proportion of positive class predictions** (i.e. `allNBA = 1`) **that were actually correct**.

Recall is the ratio of the number of true positives divided by the sum of true positives and false negatives (FN):

![Recall = \frac{TP}{TP + FN}](https://latex.codecogs.com/svg.latex?Recall%20%3D%20%5Cfrac%7BTP%7D%7BTP%20&plus;%20FN%7D)

It describes the **proportion of correctly identified All-NBA members**.

Considering **both** precision and recall is particularly useful when a problem involves imbalanced classes, which is the case with our problem (i.e. there are many more non-members than there are members). Note that, in the equations above, **we aren't concerned with the number of true negatives** - because of the heavy class imbalance, our model's ability to predict the negative class isn't as important as its ability to **correctly predict the minority (positive) class**.

Though it isn't as easily interpretable as the area under the ROC curve, the area under the precision-recall curve also provides a measure of model performance. A perfect classifier will have **AUPRC = 1.0**. So, as with the ROC curve, an AUPRC value closer to 1.0 (its graph as close to the upper-right corner as possible) suggests better performance.

We can calculate the area under the precision-recall curve using the `pr.curve` function from the `PRROC` package.

#### 5.5.3 Cross-Entropy

**Cross-Entropy** is a typical cost function used with classifiers. The value of the cross-entropy of a given observation is based on two things:

1. The actual class
2. The model's probability of the actual class

For binary classification in particular, cross-entropy can be calculated as

![Cross-Entropy](https://latex.codecogs.com/svg.latex?-%28y%20%5C%20ln%20%28p%29%20&plus;%20%281-y%29%20%5C%20ln%281-p%29%29)

where *y* is the indicator (`0` or `1`) and *p* is the predicted probability. Cross-entropy loss increases rapidly for non-member predictions when the player actually made any roster, and vice versa. A perfect model will have a loss of 0, so the lower the cross-entropy loss, the better a model performed.

From the `ROCR` package, we can use `performance()` with the argument `measure = "mxe"` to calculate *mean* cross-entropy (which this report will still refer to as cross-entropy loss).

### 5.6 LASSO

L1, or Lasso (Least Absolute Shrinkage and Selection Operator), regularization relies on the L1 norm (absolute size) to impose penalties on coefficients.

Practically speaking, this type of penalty results in less-significant variables being "turned off", which essentially translates to **automatic feature selection**.

The degree of the penalty is dependent upon tuning parameter `lambda`, whose optimal value (i.e. `lambda` such that AUROC is greatest) is determined using cross-validation on our training set.

To perform a lasso regression in `glmnet`, we simply set the argument `alpha = 1`.

#### 5.6.1 Initial 80-20 Data Split

As shown in the figure below, the model trained on 80% of the available data performed quite well. The AUROC and AUPRC of this model were 0.9934185 and 0.7796794 (respectively), with the correct players ranked within the top 15 or so most probable players per position for most of the seasons in the test set (2006-2012). Full details are available on RPubs (see section 9).

![First LASSO Model Metrics](https://github.com/martij222/capstone-project/blob/master/graphs/lasso-plots1.png)

In an effort to improve the models, an alternative approach to splitting the data was also considered and is detailed in the following section.

#### 5.6.2 Maximizing Training Data

As an alternative to the typical 80-20 split, **all but the last season** were used for the training set. This method of splitting the data is considered for two reasons:

1. It maximizes the volume of training data available for our algorithms
2. It more closely simulates the scenario in which the model would actually be trained

Recreating the models also provided an opportunity to correct encoding errors for player position that were revealed in observing the results from the first model, namely for Rajon Rondo, Dwight Howard, and Dirk Nowitzki.

![Second LASSO Model Metrics](https://github.com/martij222/capstone-project/blob/master/graphs/lasso-plots2.png)

The model trained in this fashion resulted in a predicted roster more or less the same as the initial 80-20 split. More importantly, however, the **probabilities of each respective player increased** relative to the first model. This is demonstrated in the above figures - despite a slightly lower AUROC of 0.9930087, the AUPRC was much-improved at 0.8369115. These facts as well as the slight improvement in cross-entropy losses (0.04119739 < 0.04313924) suggested a better overall model, so **this data-splitting method was used when building the other models**.

#### 5.6.3 Interpreting the Regression Coefficients

```
## Positive Coefficients
##             lgAssists              tmPoints               GPRatio 
##          2.644141e+02          2.836507e+01          4.883256e+00 
##               allstar         blocksPerGame       reboundsPerGame 
##          2.221494e+00          5.534877e-01          4.629383e-01 
##          avgGameScore               healthy threeAttemptedPerGame 
##          4.184888e-01          3.793851e-01          2.829082e-01 
##         stealsPerGame      oReboundsPerGame        assistsPerGame 
##          2.630618e-01          1.164550e-01          9.175199e-02 
##           lgORebounds         ftMadePerGame             dRebounds 
##          2.065856e-02          6.797864e-03          3.400448e-03 
##        totalGameScore                ftMade 
##          8.442028e-04          7.547251e-05
##
## Zero Coefficients
##                 GP             points          oRebounds 
##                  0                  0                  0 
##           rebounds            assists             steals 
##                  0                  0                  0 
##          turnovers             fgMade        ftAttempted 
##                  0                  0                  0 
##          threeMade      pointsPerGame   dReboundsPerGame 
##                  0                  0                  0 
## ftAttemptedPerGame   threeMadePerGame           lgPoints 
##                  0                  0                  0 
##         lgRebounds              fgPct             efgPct 
##                  0                  0                  0 
##        astTovRatio        dReboundPct 
##                  0                  0
##
## Negative Coefficients
##        fgAttempted             blocks            minutes 
##      -5.286172e-04      -1.428885e-03      -1.510106e-03 
##     threeAttempted     minutesPerGame                 PF 
##      -3.684711e-03      -4.657490e-03      -6.184822e-03 
##      fgMadePerGame fgAttemptedPerGame   turnoversPerGame 
##      -1.271416e-02      -1.054196e-01      -2.008124e-01 
##           threePct        tmORebounds         tmRebounds 
##      -2.606585e-01      -6.922066e-01      -1.883970e+00 
##              ftPct        oReboundPct        tmDRebounds 
##      -2.981195e+00      -4.645660e+00      -4.879549e+00 
##          tmAssists        (Intercept)        lgDRebounds 
##      -5.488186e+00      -1.136295e+01      -4.279627e+02
```

The **logit** mentioned in section 5.3 represents the **log odds**, not probabilities. This means that, for any given variable and holding other variables constant, the actual ratio of probabilities is exp{`beta`}. For example, the regression coefficient for All-Star team membership is `beta = 2.221494`. Then, fixing every other variable at a fixed value, the odds of making an All-NBA team roster for an All-Star (`allstar = 1`) compared to the odds of making the roster for a non-All-Star (`allstar = 0`) is exp{2.221494} = 9.221097. In other words, the **odds are 9.22 times greater for All-Stars to make an All-NBA roster** (if everything else is equal).

#### 5.6.4 Lasso Discussion

It's interesting to see that the lasso model "turned off" many of the offensive variables like points, assists, and field goals, and even more interesting that it *penalizes* others like field goal attempts. Some of these penalties make sense; for instance, personal fouls and turnovers per game. For others, like blocks, the penalties are probably a result of the algorithm adjusting for bias due to other features **over-representing the raw statistic**. This can be seen by comparing the `block` coefficient to the `blocksPerGame` coefficient. The features `GPRatio` and `healthy`, which were inspired by our exploratory data analysis, turned out to be good indicators of All-NBA team membership according to this model.

Overall, it looks like this lasso model did a fairly good job predicting All-NBA membership in general. Except for Rajon Rondo and Carmelo Anthony, the correct players are placed in the top 10 for each position. A cursory glance of the results, particularly the AUROC of 0.9930087, suggest that this is a pretty good model.

### 5.7 Ridge

Similar to lasso regression, L2, or ridge, regression penalizes large coefficients. However, it instead relies on the L2 penalty (squared size). 

Practically speaking, this leads to coefficient or *feature shrinkage* (it doesn't force them to 0).

Again, the "strength" of the penalty is tuned by the parameter `lambda`.

Using `glmnet`, ridge regression can be done by setting `alpha = 0`.

#### 5.7.1 Ridge Discussion

Like the lasso model, the ridge model correctly identified the First Team, as well as a good chunk of the Second Team (see section 5.9.1). Deron Williams again ranked pretty high despite not making a roster at all; John wall also scooted another guard off the top 6. Rajon Rondo was only given a probability of 0.038, which would just barely place him in the top 10 for guards. It had Carmelo Anthony in 7th place for forwards, but it also gave poor Tyson Chandler a measly 0.015 probability of making the roster.

```
## Positive Coefficients
##             lgAssists              lgPoints           lgORebounds 
##          5.763250e+01          4.856552e+01          4.257824e+00 
##              tmPoints            lgRebounds               allstar 
##          2.735093e+00          2.465918e+00          1.795669e+00 
##             tmAssists           tmORebounds            tmRebounds 
##          1.739097e+00          1.412404e+00          1.154470e+00 
##                efgPct                 fgPct           tmDRebounds 
##          1.010174e+00          9.945160e-01          9.354206e-01 
##           dReboundPct         blocksPerGame         stealsPerGame 
##          3.590569e-01          3.252119e-01          1.954983e-01 
##         ftMadePerGame           astTovRatio      threeMadePerGame 
##          1.111507e-01          1.047392e-01          1.024201e-01 
##    ftAttemptedPerGame        assistsPerGame      dReboundsPerGame 
##          9.486095e-02          8.798613e-02          8.109276e-02 
##      oReboundsPerGame         fgMadePerGame          avgGameScore 
##          7.122856e-02          6.500880e-02          5.260153e-02 
##       reboundsPerGame               healthy threeAttemptedPerGame 
##          4.786521e-02          3.829229e-02          2.931582e-02 
##         pointsPerGame              threePct    fgAttemptedPerGame 
##          2.621667e-02          2.215310e-02          1.799737e-02 
##               GPRatio        minutesPerGame                blocks 
##          4.165392e-03          2.614274e-03          2.378526e-03 
##             threeMade                ftMade               assists 
##          1.151087e-03          7.770179e-04          7.755045e-04 
##                steals           ftAttempted        totalGameScore 
##          6.515315e-04          6.238926e-04          4.123563e-04 
##                fgMade             dRebounds        threeAttempted 
##          3.571578e-04          2.227062e-04          1.370472e-04 
##                points              rebounds           fgAttempted 
##          1.353643e-04          5.686495e-05          4.973701e-06
##
## Negative Coefficients
##          minutes        oRebounds        turnovers               PF 
##    -6.467301e-05    -5.346227e-04    -1.223218e-03    -2.111940e-03 
##               GP turnoversPerGame            ftPct      oReboundPct 
##    -2.601061e-03    -9.323615e-03    -4.331699e-02    -4.633257e-01 
##      lgDRebounds      (Intercept) 
##    -5.127471e-01    -1.178001e+01
```

Note that, as mentioned at the top of the section, all of the variables contribute, though some coefficients are quite small and thus bear little effect. All-Star membership remains a strong predictor, though the GPRatio and healthy variables are much less significant compared to the lasso model. Many of the offensive stats are much more important to the Ridge model. Additionally, four different league-wide stats are present in the top 5 coefficients, which suggests that the ridge model places a high importance on relative performance every season. These are followed by team-wide statistics, which can perhaps be interpreted as a player's particular role on his team also bearing high importance.

![Ridge Model Metrics](https://github.com/martij222/capstone-project/blob/master/graphs/ridge-plots.png)

Though the Ridge model pulled off a high AUROC of 0.9915167, it doesn’t perform as well as the lasso model. It doesn't perform as well based on the AUPRC and cross-entropy loss, either - yet, it still predicts the same number of correct players.

### 5.8 Elastic-Net

Elastic-net is a compromise between lasso and ridge regression. As discussed in previous sections, the ratio of L1 and L2 penalties is determined by `alpha`.

#### 5.8.1 Alpha Optimization

To find the optimal alpha, several iterations of cross-validation were performed in parallel using `%dopar%` from the `foreach` package (in conjunction with the `doParallel` package). Results were stored a data frame, from which the alpha that corresponded to the maximum AUC could be easily identified.

#### 5.8.2 Elastic-Net Discussion

```
## Positive Coefficients
##             lgAssists              lgPoints           lgORebounds 
##          1.968793e+02          1.655255e+02          4.185373e+01 
##              tmPoints                 fgPct                efgPct 
##          2.156011e+01          3.145837e+00          2.531974e+00 
##               GPRatio               allstar           dReboundPct 
##          2.401594e+00          2.184386e+00          2.069288e+00 
##         blocksPerGame               healthy           tmORebounds 
##          7.647388e-01          5.311330e-01          4.731112e-01 
##         stealsPerGame      oReboundsPerGame      dReboundsPerGame 
##          4.515525e-01          3.708144e-01          2.747295e-01 
## threeAttemptedPerGame        assistsPerGame       reboundsPerGame 
##          2.451623e-01          2.129503e-01          2.024594e-01 
##          avgGameScore         ftMadePerGame      threeMadePerGame 
##          1.732118e-01          1.464864e-01          1.455032e-01 
##         pointsPerGame        totalGameScore             dRebounds 
##          1.018255e-02          1.300575e-03          1.170581e-03 
##                ftMade              rebounds 
##          5.097407e-04          3.443722e-04
##
## Zero Coefficients
##             points            assists             steals 
##                  0                  0                  0 
##             fgMade        ftAttempted          threeMade 
##                  0                  0                  0 
##      fgMadePerGame ftAttemptedPerGame        astTovRatio 
##                  0                  0                  0
##
## Negative Coefficients
##          oRebounds            minutes        fgAttempted 
##      -1.314830e-04      -7.415770e-04      -8.699819e-04 
##             blocks          turnovers     threeAttempted 
##      -2.149325e-03      -2.949120e-03      -3.103796e-03 
##                 GP fgAttemptedPerGame                 PF 
##      -4.431213e-03      -4.819964e-03      -7.007939e-03 
##     minutesPerGame   turnoversPerGame           threePct 
##      -4.328564e-02      -2.155763e-01      -2.456865e-01 
##         tmRebounds        tmDRebounds              ftPct 
##      -4.367087e-01      -9.687259e-01      -2.003881e+00 
##          tmAssists        oReboundPct        (Intercept) 
##      -2.297697e+00      -2.775426e+00      -1.479367e+01 
##         lgRebounds        lgDRebounds 
##      -1.019791e+02      -3.263354e+02
```

As with the ridge model, the elastic-net model heavily weighted league-wide stats, with assists, points, and offensive rebounds accounting for the top 3 highest coefficients. This model also lends more weight to offensive efficiency, as field goal percentage and effective field goal percentage are the fifth and sixth highest coefficients. Player health (`GPRatio`) and All-Star membership are also strong predictors in this model.

![Elastic-Net Model Metrics](https://github.com/martij222/capstone-project/blob/master/graphs/enet-plots.png)

Overall, the elastic-net model did a fairly good job of predicting all three teams. Like the other two models, the First Team and most of the Second Team are correctly predicted and the true roster were all within the top 15 most probable players. Overall, the model correctly predicts the most players, and has the highest AUROC of 0.9931599, as well as the highest AUPRC of 0.8411672. It has an excellent cross-entropy loss of only 0.04172166, though it's not as low as the lasso model.

### 5.9 Model Comparison

As mentioned in section 5.6.2, there were a few corrections to make before compiling the final predictions:

1. Dirk Nowitzki actually made the team as a *forward*, though he's coded as a center.
2. Dwight Howard made the team as a *center*, though he's coded as a forward.
3. Again, Rajon Rondo was incorrectly coded as a forward, so he should be listed as a *guard*.

The results, with the above adjustments, are shown in the next subsection.

#### 5.9.1 Prediction Summary and Discussion

##### 2012 All-NBA First Team

| Position      | Lasso            | Ridge            | Elastic-Net      | Actual           |
|---------------|:----------------:|:----------------:|:----------------:|:----------------:|
| Guard         | Chris Paul       | Chris Paul       | Chris Paul       | Chris Paul       |
| Guard         | Kobe Bryant      | Kobe Bryant      | Kobe Bryant      | Kobe Bryant      |
| Forward       | LeBron James     | LeBron James     | LeBron James     | LeBron James     |
| Forward       | Kevin Durant     | Kevin Durant     | Kevin Durant     | Kevin Durant     |
| Center        | Dwight Howard    | Dwight Howard    | Dwight Howard    | Dwight Howard    |

##### 2012 All-NBA Second Team

| Position      | Lasso            | Ridge            | Elastic-Net      | Actual           |
|---------------|:----------------:|:----------------:|:----------------:|:----------------:|
| Guard         |~~Deron Williams~~|~~Deron Williams~~|~~Deron Williams~~| Tony Parker      |
| Guard         | Russell Westbrook| Russell Westbrook| Russell Westbrook| Russell Westbrook|
| Forward       | Kevin Love       | Kevin Love       | Kevin Love       | Kevin Love       |
| Forward       | Blake Griffin    | Blake Griffin    | Blake Griffin    | Blake Griffin    |
| Center        | Andrew Bynum     | Andrew Bynum     | Andrew Bynum     | Andrew Bynum     |

##### 2012 All-NBA Third Team

| Position      | Lasso              | Ridge            | Elastic-Net      | Actual           |
|---------------|:------------------:|:----------------:|:----------------:|:----------------:|
| Guard         |~~Brandon Jennings~~| Dwyane Wade      | Dwyane Wade      | Dwyane Wade      |
| Guard         | *Tony Parker*      |~~John Wall~~     | *Tony Parker*    | Rajon Rondo      |
| Forward       |~~Pau Gasol~~       |~~Pau Gasol~~     |~~Pau Gasol~~     | Dirk Nowitzki    |
| Forward       |~~Josh Smith~~      |~~Josh Smith~~    |~~Josh Smith~~    | Carmelo Anthony  |
| Center        |~~Marcin Gortat~~   |~~Marc Gasol~~    |~~Marcin Gortat~~ | Tyson Chandler   |

Note that, in the tables above, players that are struck through did not make any roster (i.e. ~~Marcin Gortat~~, ~~Josh Smith~~, etc.). *Tony Parker* is italicized since he was predicted to make Third Team, but actually made Second Team.

**All 3 models correctly predicted the First Team roster, as well as 4 of 5 Second Team members**. Interestingly, they all models also agreed that Deron Williams should have been on the Second Team, though he didn't actually make any roster (sorry Deron). The Third Team roster is where it gets hairy - the Lasso and Ridge models correctly predicted only 1 of 5 players, and Elastic-Net only predicted 2. Also note that, if Deron Williams wasn't ranked 4th on the Guards list, Tony Parker would have correctly made Second Team for the Elastic-Net model. Unfortunately, poor Rondo was only given a 0.066 probability of making a roster, so he still wouldn't have cracked Third Team on this model.

There are a lot of intangible factors that go into the All-NBA team selection, particularly since it's **determined by a point-based voting system** - and not by players and coaches, but by a panel of sportswriters and broadcasters. From [Wikipedia](https://en.wikipedia.org/wiki/All-NBA_Team):

> Players receive five points for a first team vote, three points for a second team vote, and one point for a third team vote.

This provides a bit of an explanation for the high accuracy of the First and Second teams as well as the low accuracy of the Third Team. Voters mostly seem to **agree on the obvious First- and Second-Teamers**, so those players rack up 5x or 3x the points than do Third-Team votes. Given the weight of the points, it makes sense that the Third Team roster has such variance. Not even the models seem to agree on Third Team, for that matter. 

At any rate, given that all 3 models correctly predicted 9 of 10 First and Second Team rosters, it seems that there's some semblance of agreement upon whatever criteria the voters judge worthiness. But whatever those criteria are, the First Team apparently seem to have it in spades, given their relative probabilities in each model.

#### 5.9.2 Evaluation Metrics

A direct comparison of the ROC and Precision-Recall curves, as well as a summary of the evaluation metrics, are provided below. 

![Model Metrics Comparison Plot](https://github.com/martij222/capstone-project/blob/master/graphs/model-comp-plots.png)

Note: The best value is highlighted in **green** and the worst in **red**.

![Model Metrics Comparison Table](https://github.com/martij222/capstone-project/blob/master/graphs/model-comp-table.png)

The ROC Curves plot demonstrates the similarity in AUROC scores for each model, though we can barely see the edge that the elastic-net model has on the other two (it's on top of them). The Precision-Recall curves are a bit more scattered, so it's difficult to tell which model wins from the plot alone. 

The elastic-net model outperformed the lasso model based on AUROC and AUPRC, although the lasso model has a narrow edge in terms of cross-entropy. The ridge model consistently performed the worst across all metrics. Despite this, however, the **ridge and lasso models correctly predicted the same number of All-NBA team members**. 

The elastic-net model identified the most correct players out of all models, although it only beat the other models by 1 player (11 out of 15 players correctly identified). Based on this and the fact that the elastic-net model won in 2 out of 3 evaluation metrics, we can say that **elastic-net provides the winning model**. 

## 6. Using the Model and Recommendations

As discussed in section 5.3, we're only interested in the *relative* probabilities of each player making the All-NBA team. To reiterate,

> In the ideal case of correctly identifying all 15 unique members: **the top 6 players in the guard and forward lists** and **the top 3 players in the center list** make up all 3 rosters.

It's not only important to identify a player's respective probability of membership, but also their probability compared to other players in their position. For example, in the winning elastic-net model, the potential Third Team center (ranks 3~6) probabilities differ by less than 5%. Of course, that's not to say that a player with a low probability will be excluded from contention (as demonstrated with all of our models giving zero respect to Anthony, Rondo, and Chandler). Ultimately, the results of the model should be used as a guideline, particularly for the Third Team.

### 6.1 2019 All-NBA Team Predictions

By scraping current regular-season data, predictions for the 2019 All-NBA Team can be made, which is a fun test for the elastic-net model. As of the writing of this report (April 30, 2019), the actual team has not yet been announced.

#### 6.1.2 Probability Rankings

The results of using the actual 2018-2019 regular season data are presented below.

##### Guards

![2019 Guard Predictions](https://github.com/martij222/capstone-project/blob/master/graphs/2019-guard-pred.png)

##### Forwards

![2019 Forward Predictions](https://github.com/martij222/capstone-project/blob/master/graphs/2019-forward-pred.png)

##### Centers

![2019 Center Predictions](https://github.com/martij222/capstone-project/blob/master/graphs/2019-center-pred.png)

#### 6.1.3 2019 All-NBA Team Roster

Assuming the ideal case mentioned in sections 5.3 and 6, the elastic-net model predicts the following roster for the 2019 All-NBA Team:

| Position      | First Team            | Second Team      | Third Team         |
|---------------|:---------------------:|:----------------:|:------------------:|
| Guard         | James Harden          | Stephen Curry    | Kemba Walker       |
| Guard         | Russell Westbrook     | Damian Lillard   | Kyrie Irving       |
| Forward       | Giannis Antetokounmpo | Paul George      | Kawhi Leonard      |
| Forward       |	LeBron James          | Kevin Durant     | Blake Griffin      |
| Center        |	Anthony Davis         | Joel Embiid      | Karl-Anthony Towns |

As a casual NBA fan without the time to actually watch many games, this seems like a pretty good list! It also highlights the importance of considering the relative probabilities per position - many people would place Anthony Davis and Joel Embiid as the top 1 and 2 centers, so even though their probabilities only differ by about 0.001, that 1-2 order seems pretty reasonable. But again, the Third Team center is a complete toss-up - not only are ranks 3-5 all above 0.96 probability, but they *differ by just over 1%*. Really, the entire Third Team is a toss-up.

Considering the results, the model also seems pretty confident about the First and Second Teams, which all 3 models were pretty consistent about predicting. So, it'll be very interesting to see how the actual vote pans out. 

It's also worth noting that our model doesn't factor in Playoff performance (or qualification, for that matter) - since the original data only had *total* post-season stats, there was no way to effectively incorporate it even though the actual All-NBA team is typically announced mid-Playoffs. This means that the model is losing out on a lot of potential predictive ability. If we *were* to factor in post-season performance, then our [ranking Damian Lillard at the #4 spot suddenly doesn't seem all that reasonable](https://fivethirtyeight.com/features/damian-lillard-hit-a-series-ending-game-winner-for-the-ages/). But again, the results should be used as a guideline.

## 7. Summary

### 7.1 Data Wrangling and Exploratory Data Analysis

Although the data set came from Kaggle, there were several issues that came up when preparing the data for analysis, primarily inconsistency in naming across tables and more importantly, incorrect and inconsistent player ID coding for several observations (particularly in the All-Star data).

Exploratory data analysis also showed some issues with the data, particularly with the number of games played per season. This issue was remedied by creating per-game stats, which were then plotted to visualize the distributions of All-NBA Team members versus non-members.

As expected, All-NBA Team members typically had a larger impact on the games they played in, especially considering that they played the majority of those games. This meant more of everything in general, including personal fouls and turnovers. An interesting comparison between the two groups was shot percentage, which showed very similar distributions, and showed that non-members actually averaged a higher three point shot percentage over their All-NBA counterparts!

### 7.2 Machine Learning Models

We created 3 regularized logistic regression models using lasso, ridge, and elastic-net. The elastic-net model performed the best, in terms of AUROC, AUPRC, and players correctly predicted. There's a lot of room for improvement, but it's not terrible! It's also worth noting that all 3 models agreed on both the First and Second Teams. 

It's interesting to note that all 3 models have `lgAssists` as the **highest coefficient**, followed either by `lgPoints` or `tmPoints`. Of course, being proportions, league- and team-wide statistics vary from player to player on the order of tenths, hundreths, or even thousandths of a point. On such a scale their importance can be a bit difficult to interpret; this is one of the disadvantages of logistic regression. However, it makes enough sense that the highest scorers and assist-ers have much greater probabilities of making a roster.

Considering the scale of league- and team-wide stats, as well as field goal percentage, All-Star status is likely the **best predictor** of All-NBA team membership - the elastic-net and lasso models gave All-Stars about **9 times greater odds** of making a roster (ridge gave about 6 times). Player health (and/or `GPRatio`) is also a significant contributor - all models had one or the other within the top 10 highest coefficients. Another point of interest is the apparent importance of `lgORebounds`, which can, in some opinions, be an indirect indicator of effort/activity.

Though not exactly unexpected, all 3 models penalize turnovers, turnover per game, and personal fouls. What's more interesting is that **all 3 models also penalize some combination of minutes, minutes per game, and games played**. It's not much of a penalty in any model - for instance, the winning elastic-net model docks ~0.4% chance for every game played. Perhaps this has to do with teams resting their key players every once in a while (or before the playoffs).

## 8. Future Work

There are several paths to take in order to improve upon the current model, including:

1. Scraping the missing regular season statistics (seasons after 2011-2012).
2. Training on algorithms that can describe non-linear relationships (e.g. CART, random forests, gradient boosted trees).
3. Performing resampling or weighting to address class imbalance.
4. Adding Playoff qualification as an indicator variable (this is fine since awards are announced *after* the regular season).
5. Applying clustering before creating models.

## 9. Additional Information

Detailed reports and additional information can be found on RPubs: 

1. [Data Cleaning](http://rpubs.com/martij222/all-nba-data-wrangling) 
2. [Exploratory Data Analysis](http://rpubs.com/martij222/all-nba-eda)
3. [Model Building](http://rpubs.com/martij222/all-nba-ml)
4. [Web Scraping](http://rpubs.com/martij222/web-scraping)
