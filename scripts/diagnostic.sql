/*
===============================================================================
Diagnostics
===============================================================================
Script Purpose: 
    Collection of scripts used for identifying and cleaning raw data 
===============================================================================
*/


/* ============================== ball_type_ref =============================== */
-- Metadata/reference table; data was found clean
SELECT * FROM raw_data.ball_type_ref;

/* ============================== shot_type_ref =============================== */
-- Metadata/reference table; data was found clean
SELECT * FROM raw_data.shot_type_ref;

/* ================================= player =================================== */
SELECT * FROM raw_data.player
ORDER BY player_id;

SELECT * FROM raw_data.player
WHERE player_id IS NULL
OR gender IS NULL
OR dom_hand IS NULL;

-- Rename data so that R = Right-handed, L = Left-handed, all else = Unknown
SELECT dom_hand, count(*) as handedness_count
FROM raw_data.player
GROUP BY dom_hand;

-- Rename data so that M = Male, F = Female, all else = Unidentified
SELECT gender, count(*) as gender_count
FROM raw_data.player
GROUP BY gender;

SELECT * FROM raw_data.player
WHERE gender != 'M' AND gender != 'F';

SELECT * FROM raw_data.player
WHERE dom_hand IS NULL or dom_hand = 'M';

/* ======================================= game =============================== */
SELECT * FROM raw_data.game;

-- Confirmation of no duplicate game_id's
SELECT game_id, count(*) 
FROM raw_data.game AS g
GROUP BY game_id
HAVING count(*) > 1;

-- Confirmation of no duplicate winners
SELECT *
FROM raw_data.game
WHERE w_team_id = l_team_id;

-- Verify columns
SELECT DISTINCT skill_lvl
FROM raw_data.game
ORDER BY skill_lvl;

SELECT DISTINCT scoring_type
FROM raw_data.game
ORDER BY scoring_type;

-- Found null value
SELECT DISTINCT ball_type
FROM raw_data.game
ORDER BY ball_type;

-- Digest how to impute null; since there is no other game in match, set to U
-- >>>> COALESCE(ball_type, 'U') AS ball_type,
SELECT * FROM raw_data.game
WHERE match_id = 'M77'

-- Confirm no other nulls
SELECT * FROM raw_data.game
WHERE game_id IS NULL
OR match_id IS NULL
OR game_nbr IS NULL
OR score_w IS NULL
OR score_l IS NULL
OR w_team_id IS NULL
OR l_team_id IS NULL
OR skill_lvl IS NULL
OR scoring_type IS NULL
OR ball_type IS NULL
OR dt_played IS NULL;

SELECT * FROM raw_data.game
ORDER BY dt_played, match_id;

SELECT * FROM raw_data.game
WHERE match_id = 'M188' or match_id = 'M186';

/* 
CASE 
	WHEN dt_played < '01/01/2022' OR dt_played > now() THEN LEAD(dt_played) OVER (ORDER BY match_id)
	ELSE dt_played	
END AS dt_played
*/
SELECT * FROM raw_data.game
ORDER BY match_id, dt_played; -- Contextually understand that M186 and M188 likely occured on Sept 2023, will impute with just the first of month.

/* ================================== team ==================================== */
SELECT * FROM raw_data.team;

SELECT team_id, count(*) FROM raw_data.team
GROUP BY team_id
HAVING count(*) = 1 OR count(*) > 2;

SELECT * FROM raw_data.team
WHERE team_id IS NULL
OR player_id IS NULL
OR player_seq_nbr IS NULL;

-- Data is clean

/* ================================== shot ==================================== */
SELECT * FROM raw_data.shot;

SELECT shot_id, count(*) FROM raw_data.shot
GROUP BY shot_id
HAVING count(*) > 1;

-- Lots of null players, perhaps poorly recorded
SELECT * FROM raw_data.shot
WHERE shot_id IS NULL
OR rally_id IS NULL
OR shot_nbr IS NULL
OR shot_type IS NULL

SELECT shot_type, count(*) FROM raw_data.shot
GROUP BY shot_type;

-- These are unidentified shot types
SELECT *
FROM raw_data.shot s
WHERE NOT EXISTS (
    SELECT *
    FROM raw_data.shot_type_ref r
    WHERE r.shot_type = s.shot_type
)

-- Use left join and read nulls as 'U'  
SELECT * FROM raw_data.shot AS s
LEFT JOIN raw_data.shot_type_ref str ON s.shot_type = str.shot_type
WHERE s.shot_type = 'ball';


/* ================================== rally =================================== */
SELECT * FROM raw_data.rally;

-- Confirm no duplicate rally_id's
SELECT rally_id, count(*) FROM raw_data.rally
GROUP BY rally_id
HAVING count(*) > 1;

-- rally_len has nulls
SELECT * FROM raw_data.rally
WHERE rally_len IS NULL

-- There are lots of rallies in which there is not shot data, consider escalation as no imputation would work here
SELECT *
FROM raw_data.rally r
WHERE NOT EXISTS (
    SELECT *
    FROM raw_data.shot s
    WHERE r.rally_id = s.rally_id
)

-- Context for N/A
SELECT * FROM raw_data.rally
WHERE ending_type = 'N/A'

-- Most of the endings that are N/A or blank are timeouts, exception of four as follows: 
WITH weird_endings AS (
	SELECT * FROM raw_data.rally
	WHERE ending_type NOT IN ('Unforced Error', 'Error', 'Other', 'Winner')
), 
timeouts AS ( 
	SELECT * FROM raw_data.rally
	WHERE to_ind = 'Y'
) 
SELECT * 
FROM weird_endings
WHERE rally_id NOT IN (
    SELECT rally_id FROM timeouts
);


-- CASE WHEN ending_type NOT IN ('Unforced Error', 'Error', 'Other', 'Winner') THEN 'Timeout/Unknown'
SELECT ending_type, count(*)
FROM raw_data.rally
GROUP BY ending_type;


SELECT ts_type, count(*) FROM raw_data.rally
GROUP BY ts_type;

-- Typically indicating that the rally did not reach three shots
SELECT * FROM raw_data.rally
WHERE ts_type NOT IN ('Drive', 'Drop', 'Lob', 'N/A');

-- Noteworthy that a rally_len of -1 could be indicative of a service/ref call
SELECT * FROM raw_data.rally
WHERE ts_type = 'N/A';

SELECT * FROM raw_data.rally
WHERE rally_len = 1;
