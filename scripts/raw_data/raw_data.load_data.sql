/*
===============================================================================
Procedure: Load raw csv files into raw_data 
===============================================================================
Script Purpose: 
	This procedure loads data into the raw_data schema from external CSV files. 
	It performs the following: 
	- Truncates the tables prior to load
	- Uses the COPY, FROM, and WITH (FORMAT csv, HEADER) to load csv files

To run: 
    CALL raw_data.load_data();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE raw_data.load_data()
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
    RAISE NOTICE '>> Truncating Table: raw_data.ball_type_ref';
    DELETE FROM raw_data.ball_type_ref;

    RAISE NOTICE '>> Inserting Data Into: raw_data.ball_type_ref';
    COPY raw_data.ball_type_ref FROM 'C:\Users\Khanh Phan\Desktop\Projects\Pickleball_Data_Warehouse\data\ball_type_ref.csv' WITH (FORMAT csv, HEADER);
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- shot_type_ref
    start_time := now();
    RAISE NOTICE '>> Truncating Table: raw_data.shot_type_ref';
    DELETE FROM raw_data.shot_type_ref;

    RAISE NOTICE '>> Inserting Data Into: raw_data.shot_type_ref';
    COPY raw_data.shot_type_ref FROM 'C:\Users\Khanh Phan\Desktop\Projects\Pickleball_Data_Warehouse\data\shot_type_ref.csv' WITH (FORMAT csv, HEADER);
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- player
    start_time := now();
    RAISE NOTICE '>> Truncating Table: raw_data.player';
    DELETE FROM raw_data.player;

    RAISE NOTICE '>> Inserting Data Into: raw_data.player';
    COPY raw_data.player FROM 'C:\Users\Khanh Phan\Desktop\Projects\Pickleball_Data_Warehouse\data\player.csv' WITH (FORMAT csv, HEADER);
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- team
    start_time := now();
    RAISE NOTICE '>> Truncating Table: raw_data.team';
    DELETE FROM raw_data.team;

    RAISE NOTICE '>> Inserting Data Into: raw_data.team';
    COPY raw_data.team FROM 'C:\Users\Khanh Phan\Desktop\Projects\Pickleball_Data_Warehouse\data\team.csv' WITH (FORMAT csv, HEADER);
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- game
    start_time := now();
    RAISE NOTICE '>> Truncating Table: raw_data.game';
    DELETE FROM raw_data.game;

    RAISE NOTICE '>> Inserting Data Into: raw_data.game';
    COPY raw_data.game FROM 'C:\Users\Khanh Phan\Desktop\Projects\Pickleball_Data_Warehouse\data\game.csv' WITH (FORMAT csv, HEADER);
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- rally
    start_time := now();
    RAISE NOTICE '>> Truncating Table: raw_data.rally';
    DELETE FROM raw_data.rally;

    RAISE NOTICE '>> Inserting Data Into: raw_data.rally';
    COPY raw_data.rally FROM 'C:\Users\Khanh Phan\Desktop\Projects\Pickleball_Data_Warehouse\data\rally.csv' WITH (FORMAT csv, HEADER);
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -- shot
    start_time := now();
    RAISE NOTICE '>> Truncating Table: raw_data.shot';
    DELETE FROM raw_data.shot;

    RAISE NOTICE '>> Inserting Data Into: raw_data.shot';
    COPY raw_data.shot FROM 'C:\Users\Khanh Phan\Desktop\Projects\Pickleball_Data_Warehouse\data\shot.csv' WITH (FORMAT csv, HEADER);
    end_time := now();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    batch_end_time := now();
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Raw Data Completed';
    RAISE NOTICE '   - Total Load Duration: % seconds', EXTRACT(SECOND FROM batch_end_time - batch_start_time);
    RAISE NOTICE '==========================================';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'ERROR OCCURRED DURING LOADING RAW DATA';
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE '==========================================';
END;
$$;