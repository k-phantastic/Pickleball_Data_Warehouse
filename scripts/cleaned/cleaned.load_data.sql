/*
===============================================================================
Procedure: Load cleaned data into cleaned schema 
===============================================================================
Script Purpose: 
	This procedure loads data into the cleaned schema from raw_data tables. 
	It performs the following: 
	- Truncates the tables prior to load
	- Uses INSERT INTO to load csv files

To run: 
    CALL cleaned.load_data();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE cleaned.load_data()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
BEGIN
    batch_start_time := now();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Raw Data';
    RAISE NOTICE '================================================';

    -- ball_type_ref
    start_time := now();
    RAISE NOTICE '>> Truncating Table: cleaned.ball_type_ref';
    DELETE FROM cleaned.ball_type_ref;

    RAISE NOTICE '>> Inserting Data Into: cleaned.ball_type_ref';
    INSERT INTO cleaned.ball_type_ref(
        ball_type,
        ball_type_desc
    )
    SELECT TRIM(ball_type) as ball_type, ball_type_desc
    FROM raw_data.ball_type_ref;
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- shot_type_ref
    start_time := now();
    RAISE NOTICE '>> Truncating Table: cleaned.shot_type_ref';
    DELETE FROM cleaned.shot_type_ref;

    RAISE NOTICE '>> Inserting Data Into: cleaned.shot_type_ref';
    INSERT INTO cleaned.shot_type_ref(
        shot_type,
        shot_type_desc,
        shot_type_desc_full
    )
    SELECT
    TRIM(shot_type) as shot_type, 
    shot_type_desc, 
    CASE 
        WHEN shot_type_desc = 'Other' THEN 'Other type of shot'
        WHEN shot_type_desc = 'Unknown' THEN 'Unknown shot type'
        ELSE shot_type_desc_full
    END AS shot_type_desc_full
    FROM raw_data.shot_type_ref;
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- player
    start_time := now();
    RAISE NOTICE '>> Truncating Table: cleaned.player';
    DELETE FROM cleaned.player;

    RAISE NOTICE '>> Inserting Data Into: cleaned.player';
    INSERT INTO cleaned.player(
        player_id,
        gender, 
        dom_hand, 
        doubles_dupr, 
        doublesreliabilityscore
    )    
    SELECT
    player_id,
    CASE 
        WHEN gender = 'M' THEN 'Male'
        WHEN gender = 'F' THEN 'Female'
        ELSE 'Unidentified'
    END AS gender,
    CASE 
        WHEN dom_hand = 'R' THEN 'Right-handed'
        WHEN dom_hand = 'L' THEN 'Left-handed'
        ELSE 'Unknown'
    END AS dom_hand,
    doubles_dupr, 
    doublesreliabilityscore
    FROM raw_data.player;
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- team
    start_time := now();
    RAISE NOTICE '>> Truncating Table: cleaned.team';
    DELETE FROM cleaned.team;

    RAISE NOTICE '>> Inserting Data Into: cleaned.team';
    INSERT INTO cleaned.team(
        team_id,
        player_id,
        player_seq_nbr
    )
    SELECT team_id, player_id, player_seq_nbr
    FROM raw_data.team;
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- game
    start_time := now();
    RAISE NOTICE '>> Truncating Table: cleaned.game';
    DELETE FROM cleaned.game;

    RAISE NOTICE '>> Inserting Data Into: cleaned.game';
    INSERT INTO cleaned.game(
        game_id,
        match_id,
        game_nbr, 
        score_w, 
        score_l, 
        w_team_id,
        l_team_id,
        skill_lvl,
        scoring_type, 
        ball_type, 
        dt_played
    )    
    SELECT
    game_id, 
    match_id, 
    game_nbr, 
    score_w, 
    score_l, 
    w_team_id, 
    l_team_id, 
    skill_lvl, 
    scoring_type, 
    COALESCE(ball_type, 'U') AS ball_type,
    CASE 
        WHEN dt_played < '01/01/2022' OR dt_played > now() THEN LEAD(dt_played) OVER (ORDER BY match_id)
        ELSE dt_played	
    END AS dt_played
    FROM raw_data.game;
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- rally
    start_time := now();
    RAISE NOTICE '>> Truncating Table: cleaned.rally';
    DELETE FROM cleaned.rally;

    RAISE NOTICE '>> Inserting Data Into: cleaned.rally';
    INSERT INTO cleaned.rally(
        rally_id, 
        game_id, 
        match_id,
        rally_nbr,
        w_team_id, 
        srv_team_id, 
        srv_player_id, 
        rtrn_team_id, 
        rtrn_player_id, 
        ts_player_id, 
        ts_type,
        to_ind,
        to_team_id, 
        rally_len,   
        ending_type,
        ending_player_id, 
        srv_switch_ind, 
        rtrn_switch_ind, 
        srv_team_flipped_ind,
        rtrn_team_flipped_ind,
        srv_team_rs_player_id,
        srv_team_ls_player_id, 
        rtrn_team_rs_player_id,
        rtrn_team_ls_player_id     
    )
    SELECT 
    rally_id, 
    game_id, 
    match_id,
    rally_nbr,
    w_team_id, 
    srv_team_id, 
    srv_player_id, 
    rtrn_team_id, 
    rtrn_player_id, 
    CASE
        WHEN rally_len = 1 THEN 'N/A'
        ELSE ts_player_id
    END AS ts_player_id, 
    CASE
        WHEN rally_len = 1 THEN 'N/A'
        ELSE ts_type
    END AS ts_type, 
    to_ind,
    to_team_id, 
    rally_len, 
    CASE 
        WHEN ending_type IN ('Unforced Error', 'Error', 'Other', 'Winner') THEN ending_type
        ELSE 'Timeout/Unknown'
    END AS ending_type,
    ending_player_id, 
    srv_switch_ind, 
    rtrn_switch_ind, 
    srv_team_flipped_ind,
    rtrn_team_flipped_ind,
    srv_team_rs_player_id,
    srv_team_ls_player_id, 
    rtrn_team_rs_player_id,
    rtrn_team_ls_player_id
    FROM raw_data.rally;
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- shot
    start_time := now();
    RAISE NOTICE '>> Truncating Table: cleaned.shot';
    DELETE FROM cleaned.shot;

    RAISE NOTICE '>> Inserting Data Into: cleaned.shot';
    INSERT INTO cleaned.shot(
        shot_id,
        rally_id,
        shot_nbr, 
        shot_type,
        player_id,
        loc_x, 
        loc_y,
        next_loc_x,
        next_loc_y
    )
    SELECT 
    s.shot_id,
    s.rally_id,
    s.shot_nbr, 
    CASE 
        WHEN str.shot_type IS NULL THEN 'U'
        ELSE s.shot_type
    END AS shot_type,
    s.player_id, 
    s.loc_x, 
    s.loc_y, 
    s.next_loc_x, 
    s.next_loc_y
    FROM raw_data.shot s
    LEFT JOIN raw_data.shot_type_ref str 
    ON s.shot_type = str.shot_type;
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    batch_end_time := now();
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Cleaned Data Completed';
    RAISE NOTICE '   - Total Load Duration: % seconds', EXTRACT(SECOND FROM batch_end_time - batch_start_time);
    RAISE NOTICE '==========================================';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'ERROR OCCURRED DURING LOADING CLEANED DATA';
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE '==========================================';
END;
$$;