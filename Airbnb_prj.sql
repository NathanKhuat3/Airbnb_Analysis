-- Step 1: Make a new 'city' column for each of the table

UPDATE massive-jet-405702.Airbnb_Prj.berlin
SET city = 'Berlin'
WHERE city IS NULL;

UPDATE massive-jet-405702.Airbnb_Prj.lisbon
SET city = 'Lisbon'
WHERE city IS NULL;

UPDATE massive-jet-405702.Airbnb_Prj.london
SET city = 'London'
WHERE city IS NULL;

UPDATE massive-jet-405702.Airbnb_Prj.paris
SET city = 'Paris'
WHERE city IS NULL;

UPDATE massive-jet-405702.Airbnb_Prj.rome
SET city = 'Rome'
WHERE city IS NULL;

-- Step 2: Combine the tables into a new table with some modifications to the headers for readability, and filter for airbnbs that are for non-business purposes, not private rooms and accomodate 4-6 people

CREATE TABLE massive-jet-405702.Airbnb_Prj.a_main AS
(SELECT 
  int64_field_0 AS id,
  realSUM AS price,
  room_type,
  person_capacity,
  host_is_superhost,
  biz,
  cleanliness_rating,
  guest_satisfaction_overall,
  dist AS city_centre_dist,
  metro_dist,
  city
  FROM massive-jet-405702.Airbnb_Prj.berlin
  WHERE biz = 0 AND room_type != 'Private room' AND (person_capacity BETWEEN 4 AND 6))
UNION ALL
(SELECT 
  int64_field_0 AS id,
  realSUM AS price,
  room_type,
  person_capacity,
  host_is_superhost,
  biz,
  cleanliness_rating,
  guest_satisfaction_overall,
  dist AS city_centre_dist,
  metro_dist,
  city
  FROM massive-jet-405702.Airbnb_Prj.lisbon
  WHERE biz = 0 AND room_type != 'Private room' AND (person_capacity BETWEEN 4 AND 6))
UNION ALL
(SELECT 
  int64_field_0 AS id,
  realSUM AS price,
  room_type,
  person_capacity,
  host_is_superhost,
  biz,
  cleanliness_rating,
  guest_satisfaction_overall,
  dist AS city_centre_dist,
  metro_dist,
  city
  FROM massive-jet-405702.Airbnb_Prj.london
  WHERE biz = 0 AND room_type != 'Private room' AND (person_capacity BETWEEN 4 AND 6))
UNION ALL
(SELECT 
  int64_field_0 AS id,
  realSUM AS price,
  room_type,
  person_capacity,
  host_is_superhost,
  biz,
  cleanliness_rating,
  guest_satisfaction_overall,
  dist AS city_centre_dist,
  metro_dist,
  city
  FROM massive-jet-405702.Airbnb_Prj.paris
  WHERE biz = 0 AND room_type != 'Private room' AND (person_capacity BETWEEN 4 AND 6))
UNION ALL
(SELECT 
  int64_field_0 AS id,
  realSUM AS price,
  room_type,
  person_capacity,
  host_is_superhost,
  biz,
  cleanliness_rating,
  guest_satisfaction_overall,
  dist AS city_centre_dist,
  metro_dist,
  city
  FROM massive-jet-405702.Airbnb_Prj.rome
  WHERE biz = 0 AND room_type != 'Private room' AND (person_capacity BETWEEN 4 AND 6));

-- Step 3: DATA EXPLORATION

-- What are the total number of airbnb for each city?
SELECT
  city,
  COUNT(*) AS total_listings
FROM massive-jet-405702.Airbnb_Prj.a_main
GROUP BY city
ORDER BY total_listings DESC;

-- What are the average, maximum and minimum listing price for each city?
SELECT
  city,
  AVG(price) AS avg_price,
  Max(price) AS max_price,
  Min(price) AS min_price
FROM massive-jet-405702.Airbnb_Prj.a_main
GROUP BY city;

-- What are the average, maximum and minimum guest satisfaction rating for each city?
SELECT
  city,
  AVG(guest_satisfaction_overall) AS avg_rating,
  Max(guest_satisfaction_overall) AS max_rating,
  Min(guest_satisfaction_overall) AS min_rating
FROM massive-jet-405702.Airbnb_Prj.a_main
GROUP BY city;

-- What are the average distance to the city centre and metro in km, assuming this is the unit given by the table?
SELECT
  city,
  ROUND(AVG(city_centre_dist), 1) || ' km' AS avg_city_centre_dist,
  ROUND(AVG(metro_dist),1) || ' km' AS avg_metro_dist
FROM massive-jet-405702.Airbnb_Prj.a_main
GROUP BY city;

-- What is the percentage of super hosts for each city?
SELECT
  city,
  ROUND(COUNTIF(host_is_superhost IS TRUE) / COUNT(*)*100, 2) || '%' AS super_hosts_distribution
FROM massive-jet-405702.Airbnb_Prj.a_main
GROUP BY city
ORDER BY COUNTIF(host_is_superhost IS TRUE) / COUNT(*) DESC;

-- STEP 4: SCORING AIRBNBS

-- The airbnbs will be scored out of 100%, based on the following weighted factors (judged by the perceived value of each factor): price (30%, guest_satisfaction_overall (25%), city_centre_dist (20%), metro_dist (15%), cleanliness_rating (10%)

SELECT *
FROM
(SELECT
  id,
  city,
  price_score,
  rating_score,
  city_centre_dist_score,
  metro_dist_score,
  cleanliness_rating_score,
  total_score,
  RANK() OVER (PARTITION BY city ORDER BY total_score DESC) AS rankings
FROM
(SELECT
  id,
  city,
  NTILE(30) OVER(ORDER BY price DESC) AS price_score,
  guest_satisfaction_overall/100*25 AS rating_score,
  NTILE(20) OVER(ORDER BY city_centre_dist DESC) AS city_centre_dist_score,
  NTILE(15) OVER(ORDER BY metro_dist DESC) AS metro_dist_score,
  cleanliness_rating AS cleanliness_rating_score,
  NTILE(30) OVER(ORDER BY price DESC) + guest_satisfaction_overall/100*25 + NTILE(20) OVER(ORDER BY city_centre_dist DESC) + NTILE(15) OVER(ORDER BY  metro_dist DESC) + cleanliness_rating AS total_score
FROM massive-jet-405702.Airbnb_Prj.a_main))
WHERE rankings <= 10
ORDER BY city, rankings