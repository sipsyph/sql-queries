CREATE OR REPLACE FUNCTION array_of_random_unique_int(max_arr_len integer, min integer, max integer) RETURNS integer[] AS $BODY$
begin
	return (
		SELECT ARRAY_AGG( a.n ) FROM (    
			SELECT ROUND(RANDOM()*(max - min) + min)::INT n FROM GENERATE_SERIES(min,max) 
			GROUP BY 1 LIMIT max_arr_len
		) a
	);
end
$BODY$ LANGUAGE plpgsql;

--Random ints between 1 and 20 with a length of 10
--select array_of_random_unique_int(10, 1, 20);
