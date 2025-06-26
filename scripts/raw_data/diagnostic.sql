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
SELECT * FROM raw_data.ball_type_ref; -- Initial view



/* ============================== shot_type_ref =============================== */
-- Metadata/reference table; other and unknown to be updated in full description
SELECT * FROM raw_data.shot_type_ref;



/* ================================= player =================================== */
SELECT * FROM raw_data.player -- Initial view
ORDER BY player_id;

-- Confirmation of no duplicate player_id's
SELECT player_id, count(*) FROM raw_data.player
GROUP BY player_id
HAVING count(*) > 1;

-- Identify null values in player_id, gender, and dom_hand (other columns confirmed to have missing data)
SELECT * FROM raw_data.player
WHERE player_id IS NULL
OR gender IS NULL
OR dom_hand IS NULL;

-- View counts of dominant hands. 
SELECT dom_hand, count(*) as handedness_count
FROM raw_data.player
GROUP BY dom_hand;
-- Recommendation: Rename data so that R = Right-handed, L = Left-handed, all else = Unknown

-- View counts of genders.
SELECT gender, count(*) as gender_count
FROM raw_data.player
GROUP BY gender;
-- Recommendation: Rename data so that M = Male, F = Female, all else = Unidentified

-- View specific rows of which gender is not 'M' or 'F', no conclusions; impute as recommended
SELECT * FROM raw_data.player
WHERE gender != 'M' AND gender != 'F';

-- View specific rows of which dom_hand is not 'R' or 'L', no conclusions; impute as recommended
SELECT * FROM raw_data.player
WHERE dom_hand IS NULL or dom_hand = 'M';



/* ======================================= game =============================== */
SELECT * FROM raw_data.game; -- Initial view

-- Confirmation of no duplicate game_id's
SELECT game_id, count(*) 
FROM raw_data.game AS g
GROUP BY game_id
HAVING count(*) > 1;

-- Confirmation of no cases of winner and loser being the same
SELECT *
FROM raw_data.game
WHERE w_team_id = l_team_id;

-- View distinct types of skill brackets
SELECT DISTINCT skill_lvl
FROM raw_data.game
ORDER BY skill_lvl;

-- View distinct types of scoring
SELECT DISTINCT scoring_type
FROM raw_data.game
ORDER BY scoring_type;

-- View distinct types of balls used (found null)
SELECT DISTINCT ball_type
FROM raw_data.game
ORDER BY ball_type;
-- Recommendation: Set null ball types to U (unknown)

-- View specific row in which ball was null. Since there is no other game in match, set to U
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

-- View table ordered by date played (found error entries)
SELECT * FROM raw_data.game
ORDER BY dt_played, match_id;
-- Recommendation: Impute with the date of the next iteration of match_id

-- View table ordered by match_id, confirmation that it is in relative date order 
SELECT * FROM raw_data.game
ORDER BY match_id, dt_played; 



/* ================================== team ==================================== */
SELECT * FROM raw_data.team; -- Initial view

-- View teams only entered once or more than twice (as it is doubles, we expect two entries per team_id)
SELECT team_id, count(*) FROM raw_data.team
GROUP BY team_id
HAVING count(*) = 1 OR count(*) > 2;

-- Confirm no other nulls
SELECT * FROM raw_data.team
WHERE team_id IS NULL
OR player_id IS NULL
OR player_seq_nbr IS NULL;



/* ================================== shot ==================================== */
SELECT * FROM raw_data.shot; -- Initial view

-- Confirmation of no duplicate shot_id's
SELECT shot_id, count(*) FROM raw_data.shot
GROUP BY shot_id
HAVING count(*) > 1;

-- View if any are null; lots of null players, perhaps poorly recorded
SELECT * FROM raw_data.shot
WHERE shot_id IS NULL
OR rally_id IS NULL
OR player_id IS NULL
OR shot_nbr IS NULL
OR shot_type IS NULL

-- View distinct shot types, identifying points in which shot types are not in the range of shot_type_ref
SELECT shot_type, count(*) FROM raw_data.shot
GROUP BY shot_type;
-- Recommendation: Impute/change shot type to 'U'

-- Confirmation of extranneous shot types, row view
SELECT *
FROM raw_data.shot s
WHERE NOT EXISTS (
    SELECT *
    FROM raw_data.shot_type_ref r
    WHERE r.shot_type = s.shot_type
)



/* ================================== rally =================================== */
SELECT * FROM raw_data.rally; -- Initial view

-- Confirmation of no duplicate rally_id's
SELECT rally_id, count(*) FROM raw_data.rally
GROUP BY rally_id
HAVING count(*) > 1;

-- rally_len has lots of nulls, could be due to poor recording/identifying
SELECT * FROM raw_data.rally
WHERE rally_len IS NULL

-- Rallies found with no shot data, consider escalation as no imputation would work here
SELECT *
FROM raw_data.rally r
WHERE NOT EXISTS (
    SELECT *
    FROM raw_data.shot s
    WHERE r.rally_id = s.rally_id
)

-- View of rally ending in 'N/A', observation is most are due to a timeout
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
-- Recommendation: CASE WHEN ending_type NOT IN ('Unforced Error', 'Error', 'Other', 'Winner') THEN 'Timeout/Unknown'

-- View of distinct ending types 
SELECT ending_type, count(*)
FROM raw_data.rally
GROUP BY ending_type;

-- View of distinct third shot types, identifying both blank and N/A 
SELECT ts_type, count(*) FROM raw_data.rally
GROUP BY ts_type;

-- Row view of exceptions; typically indicating that the rally did not reach three shots
SELECT * FROM raw_data.rally
WHERE ts_type NOT IN ('Drive', 'Drop', 'Lob', 'N/A');

-- Row view of third shot = 'N/A'
SELECT * FROM raw_data.rally
WHERE ts_type = 'N/A';

-- Row view of rally length of 1
SELECT * FROM raw_data.rally
WHERE rally_len = 1;
-- Recommendation: When rally length is 1, third shot player and third shot type should be N/A
