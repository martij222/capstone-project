library(dplyr)

# Data from https://www.kaggle.com/open-source-sports/mens-professional-basketball
# Note: All player data includes pre- and post-all-star game, so analysis may introduce quite a bit of error. Perhaps we should do All-NBA Team instead?
#       Also, All-Star Game format changed last year to a fantasy draft format. So probably.

# Load player game, all-star, awards, and bio data
players <- tbl_df(read.csv("basketball_players.csv"))
glimpse(players)

master <- tbl_df(read.csv("basketball_master.csv"))
glimpse(master)

allstar <- tbl_df(read.csv("basketball_player_allstar.csv"))
glimpse(allstar)

awards <- tbl_df(read.csv("basketball_awards_players.csv"))
glimpse(awards)

# Check for duplicate data
players <- distinct(players)

# Remove non-NBA, post-season, and pre-all-star game stats, as well as miscellaneous variables. Also remove players who did not play
players <- players %>%
  filter(lgID == "NBA", year >= 1950, GP != 0) %>% 
  select(-contains("Post"), -c(note, stint, lgID))


allstar <- allstar %>% 
  filter(league_id == "NBA") %>% 
  select(-c(league_id, games_played, last_name, first_name))

awards <- awards %>% 
  filter(lgID == "NBA") %>% 
  select(-c(lgID, note))

# Looks like many stats aren't recorded in the earlier years - 
# offensive vs. defensive rebounds weren't tracked until 1972, and the 3-pointer wasn't introduced in the NBA until June 1979

# Feature engineering - from https://www.basketball-reference.com/about/glossary.html#mp
# Add some stats grouped by year
players <- players %>% 
  group_by(year) %>% 
  mutate(
    lgPoints = points / sum(points),
    lgAssists = assists / sum(assists),
    lgRebounds = rebounds / sum(rebounds),
    lgDRebounds = dRebounds / sum(dRebounds),
    lgORebounds = oRebounds / sum(oRebounds)) %>% 
  ungroup()

# Add some stats grouped by team
players <- players %>% 
  group_by(year, tmID) %>% 
  mutate(
    tmPoints = points / sum(points),
    tmAssists = assists / sum(assists),
    tmRebounds = rebounds / sum(rebounds),
    tmDRebounds = dRebounds / sum(dRebounds),
    tmORebounds = oRebounds / sum(oRebounds)) %>% 
  ungroup()

# Add other stats
players <- players %>% 
  mutate(
    ftPct = ftMade / ftAttempted,
    fgPct = fgMade / fgAttempted,
    efgP = (fgMade + 0.5 * threeMade) / fgAttempted,
    PPG = points / GP,
    astTovRatio = assists / turnovers,
    dReboundPct = dRebounds / rebounds,
    oReboundPct = oRebounds / rebounds,
    totalGameScore = points + 0.4 * (fgMade + threeMade) - 0.7 * fgAttempted - 0.4 * (ftAttempted - ftMade) + 0.7 * oRebounds + 0.3 * dRebounds + steals + 0.7 * assists + 0.7 * blocks - 0.4 * PF - turnovers,
    avgGameScore = totalGameScore / GP)
# Note: GameScore is typically a per-game-basis type deal

# Save the player data
write.csv(players, "players_clean.csv")