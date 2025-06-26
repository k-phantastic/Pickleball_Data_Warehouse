/*
===============================================================================
DDL Script: Create cleaned data tables
===============================================================================
Script Purpose: 
    This script creates the tables for the cleaned schema, dropping existing ones if they already exist. 
===============================================================================
*/

-- Create ball_type_ref table
DROP TABLE IF EXISTS cleaned.ball_type_ref;
CREATE TABLE cleaned.ball_type_ref (
	ball_type 					VARCHAR(10) PRIMARY KEY, 	                                -- Ball type code
	ball_type_desc 				VARCHAR(35), 				                                -- Ball type full name
	datawarehouse_create_date	TIMESTAMP DEFAULT now()										-- Date gathered
);

-- Create shot_type_ref table
DROP TABLE IF EXISTS cleaned.shot_type_ref;
CREATE TABLE cleaned.shot_type_ref (
  	shot_type 					VARCHAR(5) PRIMARY KEY, 	                                -- Shot type code
  	shot_type_desc 				VARCHAR(30), 				                                -- Shot type description
  	shot_type_desc_full 		VARCHAR(200), 				                                -- Full length description
	datawarehouse_create_date	TIMESTAMP DEFAULT now()										-- Date gathered

);

-- Create player table
DROP TABLE IF EXISTS cleaned.player;
CREATE TABLE cleaned.player (
	player_id 					VARCHAR(5) PRIMARY KEY, 	                                -- Unique player identifier
	gender 						VARCHAR(15), 				                                -- F = Female, M = Male
	dom_hand 					VARCHAR(15), 				                                -- Handedness, R = Right, L = Left
	doubles_dupr 				FLOAT, 					                                    -- Doubles DUPR rating
	doublesreliabilityscore 	FLOAT, 					                                    -- Doubles DUPR reliability score
	datawarehouse_create_date	TIMESTAMP DEFAULT now()										-- Date gathered
);

-- Create team table
DROP TABLE IF EXISTS cleaned.team;
CREATE TABLE cleaned.team (
	team_id 					VARCHAR(5),				                                    -- Unique team identifier
	player_id 					VARCHAR(5) REFERENCES cleaned.player (player_id),          -- Unique player identifier
	player_seq_nbr	 			INTEGER,                                                    -- Differentiates two players on the same team
	datawarehouse_create_date	TIMESTAMP DEFAULT now()										-- Date gathered
);

-- Create game table
DROP TABLE IF EXISTS cleaned.game;
CREATE TABLE cleaned.game (
	game_id 					VARCHAR(5) PRIMARY KEY,                                     -- Unique game identifier
	match_id 					VARCHAR(5),                                                 -- Unique match identifier
	game_nbr 					INTEGER,                                                    -- Identifies the when a game was played within a match
	score_w 					INTEGER,                                                    -- Score of the team that won the game
	score_l 					INTEGER,                                                    -- Score of the team that lost the game
	w_team_id 					VARCHAR(5),              									-- Unique team identifier who won the game
	l_team_id 					VARCHAR(5),              									-- Unique team identifier who lost the game
	skill_lvl 					VARCHAR(10),                                                -- Skill level of the match, ranging from 3.0 (low) to Pro (high)
	scoring_type 				VARCHAR(30),                                                -- What type of scoring was used. MLP utilizes rally scoring, whereas standard scoring utilizes side-out scoring.
	ball_type 					VARCHAR(10),  												-- Ball type code (see ball_type_ref)
	dt_played 					TIMESTAMP,                                                  -- date played
	datawarehouse_create_date	TIMESTAMP DEFAULT now()										-- Date gathered
);

-- Create rally table
DROP TABLE IF EXISTS cleaned.rally;
CREATE TABLE cleaned.rally (
	rally_id 					VARCHAR(6) PRIMARY KEY,                                     -- Unique rally identifier
	game_id	 					VARCHAR(5),										            -- Unique game identifier
	match_id 					VARCHAR(5),                                                 -- Unique match identifier
	rally_nbr 					INTEGER,                                                    -- When, relative to other rallies in the game, the rally was played
	w_team_id 					VARCHAR(5),              									-- Identifier of the team that won the rally
	srv_team_id 				VARCHAR(5),              									-- Identifier of the serving team
	srv_player_id 				VARCHAR(5),              									-- Identifier of the serving player
	rtrn_team_id 				VARCHAR(5),              									-- Identifier of the returning team
	rtrn_player_id 				VARCHAR(5),              									-- Identifier of the returning player
	ts_player_id 				VARCHAR(5),              									-- Identifier of the player who hit the third shot (if a third shot was hit)
	ts_type 					VARCHAR(5),                                                 -- Third shot type (if a third shot was hit)
	to_ind 						VARCHAR(1),                                                 -- Set to 'Y' of the record represents a timeout
	to_team_id 					VARCHAR(5),              									-- Identifier of the team who took a timeout (only applicable when to_ind = 'Y')
	rally_len 					INTEGER,                                                    -- Number of shots hit in the rally
	ending_type 				VARCHAR(15),                                                -- How the rally ended (error, unforced error, or winner). Note that users also have the option for omitting this value, which often indicates the rally ended with a forced error (i.e. a ball that was very difficult to return)
	ending_player_id 			VARCHAR(5),              									-- If an ending type was selected, the identifier of the player who ended the rally
	srv_switch_ind 				VARCHAR(3),                                                 -- Indicator if the serving team elected to stack
	rtrn_switch_ind 			VARCHAR(3),                                                 -- Indicator if the returning team elected to stack
	srv_team_flipped_ind 		VARCHAR(3),                                                 -- Indicator of if, after any potential stacking, the serving team was aligned in the same way they began the match ('N') or not ('Y')
	rtrn_team_flipped_ind 		VARCHAR(3),                                                 -- Indicator of if, after any potential stacking, the returning team was aligned in the same way they began the match ('N') or not ('Y')
	srv_team_rs_player_id 		VARCHAR(5),              									-- Unique identifier of the player on the serving team who played the right side (considers stacking) (from perspective of the serving team)
	srv_team_ls_player_id 		VARCHAR(5),              									-- Unique identifier of the player on the serving team who played the left side (considers stacking) (from perspective of the serving team)
	rtrn_team_rs_player_id 		VARCHAR(5),              									-- Unique identifier of the player on the returning team who played the right side (considers stacking) (from perspective of the returning team)
	rtrn_team_ls_player_id 		VARCHAR(5),              									-- Unique identifier of the player on the returning team who played the left side (considers stacking) (from perspective of the returning team)
	datawarehouse_create_date	TIMESTAMP DEFAULT now()										-- Date gathered
);

-- Create shot table
DROP TABLE IF EXISTS cleaned.shot;
CREATE TABLE cleaned.shot (
	shot_id 					VARCHAR(8) PRIMARY KEY,                                     -- Unique shot identifier
	rally_id 					VARCHAR(6) REFERENCES cleaned.rally (rally_id),            -- Unique rally identifier
	shot_nbr 					INTEGER,                                                    -- Sequential value indicating when a shot was hit during a rally (e.g. the first shot in a rally will have a value of 1)
	shot_type 					VARCHAR(5),													-- Type of shot hit, see table description for more information
	player_id 					VARCHAR(5) REFERENCES cleaned.player (player_id),          -- The player who hit the shot, see the table description for more information
	loc_x 						FLOAT,                                                      -- The X coordinate on the court the player struck the ball, in feet. A value of 0 indicates the right sideline and 20 indicates the left sideline (from the perspective of the player hitting the shot)
	loc_y 						FLOAT,                                                      -- The Y coordinate on the on the court the player struck the ball, in feet. A value of 0 represents the net, and a value of 22 indicates the baseline (from the perspective of the player hitting the shot)
	next_loc_x 					FLOAT,                                                      -- The X coordinate of where the subsequent shot was hit from. If this record represents a final shot, this value represents the X coordinate of where the shot landed.
	next_loc_y 					FLOAT,                                                      -- The Y coordinate of where the subsequent shot was hit from. If this record represents a final shot, this value represents the Y coordinate of where the shot landed.
	datawarehouse_create_date	TIMESTAMP DEFAULT now()										-- Date gathered
);

/*
DROP TABLE cleaned.ball_type_ref CASCADE;
DROP TABLE cleaned.game CASCADE;
DROP TABLE cleaned.player CASCADE;
DROP TABLE cleaned.rally CASCADE;
DROP TABLE cleaned.shot CASCADE;
DROP TABLE cleaned.shot_type_ref CASCADE;
DROP TABLE cleaned.team CASCADE;
*/

