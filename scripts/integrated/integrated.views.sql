/*
===============================================================================
DDL Script: Create Integrated Views
===============================================================================
Script Purpose:
    This script creates views for data analysis and further integration. 
    Each view includes extended descriptions and readable columns, 
    producing a clean business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create integrated.game
-- =============================================================================
DROP VIEW IF EXISTS integrated.game;
CREATE VIEW integrated.game AS
WITH team_typing AS (
SELECT 
    team_id,
    CASE 
        WHEN COUNT(DISTINCT p.gender) = 1 AND MIN(p.gender) = 'Female' THEN 'Women''s Doubles'
        WHEN COUNT(DISTINCT p.gender) = 1 AND MIN(p.gender) = 'Male' THEN 'Men''s Doubles'
        WHEN COUNT(DISTINCT gender) = 2 
             AND BOOL_AND(gender IN ('Male', 'Female')) THEN 'Mixed Doubles'
        ELSE 'Unidentified'
    END AS team_type
FROM cleaned.team t
JOIN cleaned.player p ON t.player_id = p.player_id
GROUP BY team_id
)
SELECT 
g.game_id, 
g.match_id, 
g.game_nbr AS game_number, 
g.score_w AS winner_score, 
g.score_l AS loser_score, 
g.w_team_id AS winning_team_id, 
--t1.team_type AS winning_team_type,
g.l_team_id AS losing_team_id, 
--t2.team_type AS losing_team_type,
g.skill_lvl AS skill_level,
g.scoring_type AS scoring_type,
CASE 
	WHEN (t1.team_type = t2.team_type AND t1.team_type = 'Men''s Doubles') THEN 'Men''s Doubles'
	WHEN (t1.team_type = t2.team_type AND t1.team_type = 'Women''s Doubles') THEN 'Women''s Doubles'
	WHEN (t1.team_type = t2.team_type AND t1.team_type = 'Mixed Doubles') THEN 'Mixed Doubles'
	ELSE 'Doubles'	
END AS doubles_type,
str.ball_type_desc AS ball_type, 
g.dt_played AS date_played
FROM cleaned.game g
JOIN cleaned.ball_type_ref str ON g.ball_type = str.ball_type
JOIN team_typing t1 ON t1.team_id = g.w_team_id 
JOIN team_typing t2 ON t2.team_id = g.l_team_id;

-- =============================================================================
-- Create integrated.rally
-- =============================================================================
DROP VIEW IF EXISTS integrated.rally;
CREATE VIEW integrated.rally AS
SELECT
rally_id, 
game_id, 
match_id, 
rally_nbr AS rally_number, 
w_team_id AS winning_team_id, 
srv_team_id AS serving_team_id,
srv_player_id AS serving_player_id,
rtrn_team_id AS returning_team_id,
rtrn_player_id AS returning_player_id, 
ts_player_id AS thirdshot_player_id,
ts_type AS third_shot_type,
to_ind AS timeout,
to_team_id AS timeout_team_id,
rally_len AS rally_length,
ending_type, 
ending_player_id
FROM cleaned.rally;

-- =============================================================================
-- Create integrated.shot
-- =============================================================================
DROP VIEW IF EXISTS integrated.shot;
CREATE VIEW integrated.shot AS
SELECT 
s.shot_id, 
s.rally_id, 
s.shot_nbr AS shot_number, 
str.shot_type_desc AS shot_type, 
s.player_id, 
s.loc_x, 
s.loc_y, 
s.next_loc_x,
s.next_loc_y
FROM cleaned.shot s
JOIN cleaned.shot_type_ref str ON s.shot_type = str.shot_type;
