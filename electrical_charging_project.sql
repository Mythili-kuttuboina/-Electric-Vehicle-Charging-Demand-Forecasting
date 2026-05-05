create database E_C_V_project;
use E_C_V_project;
create table electricl_charging_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    charging_start_time DATETIME,
    charging_end_time DATETIME,
    vehicle_type VARCHAR(50),
    weather_condition VARCHAR(50),
    location_type VARCHAR(50),
    charging_priority VARCHAR(50),
    charging_duration_mins FLOAT,
    energy_consumed_kwh FLOAT,
    charging_demand FLOAT
)
select*from electrical_charging_data;

#Peak Charging Hours
SELECT HOUR(charging_start_time) AS hour,
COUNT(*) AS sessions
FROM electrical_charging_data
GROUP BY HOUR(charging_start_time)
ORDER BY sessions DESC;

#Weekend vs Weekday Demand
SELECT 
CASE 
WHEN DAYOFWEEK(charging_start_time) IN (1,7) THEN 'Weekend'
ELSE 'Weekday'
END AS day_type,
AVG(charging_demand) AS avg_demand
FROM electrical_charging_data
GROUP BY day_type;

#Demand Trend Forecast
SELECT 
DATE(charging_start_time) AS day,
SUM(charging_demand) AS daily_demand
FROM electrical_charging_data
GROUP BY DATE(charging_start_time)
ORDER BY day;

#proper TimeSeries 
SELECT 
  DATE(charging_start_time) AS day,
  SUM(charging_demand) AS daily_demand
FROM electrical_charging_data
GROUP BY day
ORDER BY day;

#LAG FEATURES
SELECT 
  day,
  daily_demand,
  LAG(daily_demand, 1) OVER (ORDER BY day) AS prev_day_demand,
  LAG(daily_demand, 7) OVER (ORDER BY day) AS prev_week_demand
FROM (
  SELECT 
    DATE(charging_start_time) AS day,
    SUM(charging_demand) AS daily_demand
  FROM electrical_charging_data
  GROUP BY day
)t;

#moving Average 
SELECT 
  day,
  daily_demand,
  AVG(daily_demand) OVER (
    ORDER BY day
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS moving_avg_7_day
FROM (
  SELECT 
    DATE(charging_start_time) AS day,
    SUM(charging_demand) AS daily_demand
  FROM electrical_charging_data
  GROUP BY day
) t;

#moving average forecast
SELECT 
  day,
  daily_demand,
  AVG(daily_demand) OVER (
    ORDER BY day
    ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
  ) AS predicted_demand
FROM (
  SELECT 
    DATE(charging_start_time) AS day,
    SUM(charging_demand) AS daily_demand
  FROM electrical_charging_data
  GROUP BY day
) t;

#creation of forecast table
CREATE TABLE demand_forecast AS
SELECT 
  day,
  daily_demand,
  AVG(daily_demand) OVER (
    ORDER BY day
    ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
  ) AS predicted_demand
FROM (
  SELECT 
    DATE(charging_start_time) AS day,
    SUM(charging_demand) AS daily_demand
  FROM electrical_charging_data
  GROUP BY day
) t;

#forecast Accuracy
SELECT 
  day,
  daily_demand,
  predicted_demand,
  ABS(daily_demand - predicted_demand) AS error
FROM demand_forecast;

#Peak Demand Day Detection
SELECT 
DATE(charging_start_time) AS charging_date,
SUM(charging_demand) AS total_demand
FROM electrical_charging_data
GROUP BY DATE(charging_start_time)
ORDER BY total_demand DESC
LIMIT 5;