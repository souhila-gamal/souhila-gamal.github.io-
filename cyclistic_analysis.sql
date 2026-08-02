-- ===============================================================================
-- Cyclistic Bike-Share Analysis - Data Pipeline & Aggregations
-- Author: Souhila Gamal
-- Platform: Google BigQuery (SQL)
-- Project: Cyclistic Case Study (Google Data Analytics Capstone)
-- Description: This script handles data union, cleaning, feature engineering, 
-- and descriptive statistics to compare Casual riders vs. Annual members.
-- ===============================================================================

-- -------------------------------------------------------------------------------
-- STEP 1: DATA COMBINATION & STANDARDIZATION (UNION ALL)
-- -------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `capstone-project-504011.cyclistic_data.new_2020` AS  
SELECT 
    ride_id, 
    rideable_type, 
    started_at, 
    ended_at,
    member_casual 
FROM `capstone-project-504011.cyclistic_data.2020_Q1`

UNION ALL 

SELECT  
    CAST(trip_id AS STRING) AS ride_id, 
    'docked_bike' AS rideable_type, 
    start_time AS started_at, 
    end_time AS ended_at, 
    CASE 
        WHEN usertype = 'subscriber' THEN 'member' 
        WHEN usertype = 'customer' THEN 'casual' 
        ELSE usertype 
    END AS member_casual 
FROM `capstone-project-504011.cyclistic_data.2019_Q1`;


-- -------------------------------------------------------------------------------
-- STEP 2: DATA CLEANING & FEATURE ENGINEERING
-- -------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `capstone-project-504011.cyclistic_data.cleaned_trips` AS  
SELECT  
    ride_id, 
    rideable_type, 
    started_at, 
    ended_at, 
    TIMESTAMP_DIFF(ended_at, started_at, SECOND) AS ride_in_seconds, 
    ROUND(TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60, 2) AS ride_in_minutes, 
    FORMAT_DATE('%a', DATE(started_at)) AS day_of_week, 
    member_casual 
FROM `capstone-project-504011.cyclistic_data.new_2020`;


-- -------------------------------------------------------------------------------
-- STEP 3: DATA FILTERING & FINAL CLEANING
-- -------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `capstone-project-504011.cyclistic_data.final_cleaned_data` AS  
SELECT  
    ride_id, 
    rideable_type, 
    started_at,
    ended_at, 
    ride_in_seconds,
    ride_in_minutes, 
    member_casual,
    day_of_week 
FROM `capstone-project-504011.cyclistic_data.cleaned_trips` 
WHERE ride_in_seconds >= 60 
  AND ride_in_seconds <= 86400 
  AND ride_id IS NOT NULL;


-- -------------------------------------------------------------------------------
-- STEP 4: OVERALL SUMMARY & KPIs
-- -------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `capstone-project-504011.cyclistic_data.analysis_summary_overall` AS  
SELECT 
    CASE 
        WHEN LOWER(member_casual) IN ('subscriber', 'member') THEN 'Member' 
        WHEN LOWER(member_casual) IN ('customer', 'casual') THEN 'Casual' 
    END AS member_casual_type, 
    COUNT(ride_id) AS number_of_rides, 
    ROUND(AVG(ride_in_minutes), 2) AS avg_ride_length_in_minutes, 
    ROUND(MAX(ride_in_minutes), 2) AS max_ride_length_in_minutes, 
    ROUND(MIN(ride_in_minutes), 2) AS min_ride_length_in_minutes 
FROM `capstone-project-504011.cyclistic_data.final_cleaned_data` 
GROUP BY 1;


-- -------------------------------------------------------------------------------
-- STEP 5: BREAKDOWN BY DAY OF WEEK
-- -------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `capstone-project-504011.cyclistic_data.analysis_summary_by_day_of_week` AS  
SELECT  
    CASE 
        WHEN LOWER(member_casual) IN ('subscriber', 'member') THEN 'Member' 
        WHEN LOWER(member_casual) IN ('customer', 'casual') THEN 'Casual' 
    END AS member_casual_type, 
    day_of_week, 
    COUNT(ride_id) AS number_of_rides, 
    ROUND(AVG(ride_in_minutes), 2) AS avg_ride_length_in_minutes, 
    ROUND(MAX(ride_in_minutes), 2) AS max_ride_length_in_minutes, 
    ROUND(MIN(ride_in_minutes), 2) AS min_ride_length_in_minutes 
FROM `capstone-project-504011.cyclistic_data.final_cleaned_data` 
GROUP BY 1, day_of_week 
ORDER BY member_casual_type, day_of_week;
