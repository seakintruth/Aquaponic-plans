-- Insert log
INSERT INTO log (log_entry,log_category) VALUES ('Initializing::Reference and Example Data','SETUP');

-- Insert the single anchor point
INSERT INTO geo_ref (anchor_lat, anchor_lon, anchor_elevation, anchor_description) 
    -- Use the coordinates you've determined as the southwest anchor
    -- lattitude, logitude, and elevation in meters.
    VALUES (
        36.81035635235504, 
        -76.17849335514821, 
        10.584,
        '924 Thompson Way, Virginia Beach, VA, 23464, USA'
    )
    ON CONFLICT (anchor_lat, anchor_lon) DO NOTHING;
    -- This ensures uniqueness based on lat and lon, not anchor_id


-- Insert log
INSERT INTO log (log_entry,log_category) VALUES ('Completed::Reference and Example Data','SETUP');