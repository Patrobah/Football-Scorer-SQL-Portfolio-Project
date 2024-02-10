SELECT *
from goalscorers

select *
from results

select *
from shootouts

---create a new table with all the details

create view Football_scorers as
SELECT 
    gs.date, 
    gs.home_team, 
    gs.away_team,
    gs.team,
    gs.scorer,
    gs.minute,
    gs.own_goal,
    gs.penalty,
    rs.tournament,
    rs.city,
    rs.country,
    rs.neutral,
    so.winner,
    so.first_shooter
FROM 
    goalscorers gs
JOIN 
    results rs ON gs.date = rs.date 
               AND gs.home_team = rs.home_team 
               AND gs.away_team = rs.away_team
LEFT JOIN
    shootouts so ON gs.date = so.date
                 AND gs.home_team = so.home_team
                 AND gs.away_team = so.away_team;

---average minute per home_team
SELECT 
    home_team,
    AVG(minute) AS average_minute_per_home_team
FROM 
    Football_scorers
GROUP BY 
	home_team
having 
	AVG(minute) is not null
order by 
	average_minute_per_home_team asc;

---average minute per away_team
SELECT 
    away_team,
    AVG(minute) AS average_minute_per_away_team
FROM 
    Football_scorers
GROUP BY 
	away_team
having 
	AVG(minute) is not null
order by 
	average_minute_per_away_team asc;

---average minute per team
SELECT 
    country,
    AVG(average_minute) AS team_average_minutes
FROM 
    (
    SELECT 
        home_team AS country,
        AVG(minute) AS average_minute
    FROM 
        football_scorers
    GROUP BY 
        home_team
    
    UNION ALL
    
    SELECT 
        away_team AS country,
        AVG(minute) AS average_minute
    FROM 
        football_scorers
    GROUP BY 
        away_team
    ) AS subquery
GROUP BY 
    country
order by team_average_minutes desc;

---highest_scorer by tournament and country
SELECT 
    highest_scorer,
    own_goal,
    tournament,
    country
FROM (
    SELECT 
        scorer AS highest_scorer,
        own_goal,
        tournament,
        country,
        ROW_NUMBER() OVER (PARTITION BY tournament, country ORDER BY scorer ASC) AS rn
    FROM 
        Football_scorers
) AS subquery
WHERE
    rn = 1
ORDER BY 
    tournament, highest_scorer ASC, country;

---country with corresponding tournament
SELECT 
    tournament,
    country
FROM (
    SELECT 
        tournament,
        country,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY tournament) AS rn,
        COUNT(*) OVER (PARTITION BY country) AS tournament_count
    FROM 
        Football_scorers
    GROUP BY 
        tournament, country
) AS subquery
WHERE
    rn = 1
ORDER BY 
    tournament_count DESC, country;

---tournaments per country
SELECT 
    country,
    COUNT(DISTINCT tournament) AS tournaments
FROM 
    Football_scorers
GROUP BY 
    country
ORDER BY 
    tournaments DESC, country;

---most common minute for goals to be scored
SELECT 
    minute,
    COUNT(*) AS goals_count
FROM 
    Football_scorers
WHERE
    minute IS NOT NULL
GROUP BY 
    minute
ORDER BY 
    goals_count DESC, minute;

---All tournaments played in England
SELECT 
    tournament,
    date
FROM 
    Football_scorers
WHERE 
    country = 'England'
ORDER BY 
    date DESC;

---Goalscorers and name of the city where each goal was scored.
SELECT 
    g.date,
    g.home_team,
    g.away_team,
    g.scorer,
    r.city
FROM 
    Goalscorers g
JOIN 
    Results r ON g.date = r.date
              AND g.home_team = r.home_team
              AND g.away_team = r.away_team;

---matches where the same two teams played each other within a tournament
SELECT 
    r1.date,
    r1.tournament,
    r1.home_team AS team1,
    r1.away_team AS team2,
    r2.home_team AS team2,
    r2.away_team AS team1
FROM 
    Results r1
JOIN 
    Results r2 ON r1.tournament = r2.tournament
              AND r1.home_team = r2.away_team
              AND r1.away_team = r2.home_team
              AND r1.date <> r2.date;

---use CTE to join date, team, scorer, and city

WITH Goals AS (
    SELECT 
        date,
        home_team AS team,
        scorer
    FROM 
        Goalscorers
    UNION ALL
    SELECT 
        date,
        away_team AS team,
        scorer
    FROM 
        Goalscorers
),
MatchResults AS (
    SELECT 
        date,
        home_team,
        away_team,
        city
    FROM 
        Results
)
SELECT 
    g.date,
    g.team,
    g.scorer,
    m.city
FROM 
    Goals g
JOIN 
    MatchResults m ON g.date = m.date
                    AND (g.team = m.home_team OR g.team = m.away_team);


---all teams that have directly or indirectly defeated a specific team using hierarchical queries
WITH DefeatedTeams AS (
    SELECT
        home_team AS defeated_team,
        away_team AS defeating_team
    FROM
        Results
    WHERE
        home_team = 'England' or away_team = 'England'

    UNION ALL

    SELECT
        r.home_team AS defeated_team,
        d.defeating_team
    FROM
        Results r
    JOIN
        DefeatedTeams d ON r.away_team = d.defeated_team
)
SELECT DISTINCT
    defeated_team
FROM
    DefeatedTeams
	OPTION (MAXRECURSION 0);


---End