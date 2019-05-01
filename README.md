# All-NBA Team Predictions - Capstone Project

## Introduction

Founded in 1946, the National Basketball Association (NBA) is considered to be the premier basketball league in the world. Based in the United States, the NBA boasts millions of viewers not only in North America, but worldwide. Popularity has also surged in recent years; [total revenue increased by 8.5% over the previous season, hitting the $8 billion mark](https://www.forbes.com/sites/kurtbadenhausen/2019/02/06/nba-team-values-2019-knicks-on-top-at-4-billion/). 

The purpose of this capstone project is to build a machine learning model that will predict the 15 members of the All-NBA team roster. The results can be of interest to sportsbetters, general basketball fans, and with [recent changes to the Collective Bargaining Agreement and salary cap rules](https://www.sportskeeda.com/basketball/all-nba-teams-the-who-what-when-why-and-how), it could even be of interest to team Front-Offices.

## Data

The data used is from the [Men's Professional Basketball data set from Kaggle](https://www.kaggle.com/open-source-sports/mens-professional-basketball). The complete data set consists of five main tables and six supplementary tables. For the purpose of this project, only the following data sets are used:

- **master**: biographical information for players and coaches
- **players**: stats for each player, per year
- **awards_players**: player awards, per year
- **player_allstar**: individual player stats for the All-Star Game, per year

Additional data is scraped from [Basketball-Reference](https://www.basketball-reference.com/leagues/NBA_2019_totals.html) and used to predict the All-NBA rosters for the 2018-2019 regular season.

## RPubs Reports

Detailed reports for each stage of this project can be found on RPubs:

1. [Data Cleaning](http://rpubs.com/martij222/all-nba-data-wrangling) 
2. [Exploratory Data Analysis](http://rpubs.com/martij222/all-nba-eda)
3. [Model Building](http://rpubs.com/martij222/all-nba-ml)
4. [Web Scraping](http://rpubs.com/martij222/web-scraping)
