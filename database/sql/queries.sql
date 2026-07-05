-- Task 2 by Shem Ayioka.
-- This file has three MySQL queries with their expected results.
-- Run it with: mysql -u root -p tetouan_power < database/sql/queries.sql
USE tetouan_power;

-- Query 1 shows the average consumption for each zone.
-- It joins the two tables and groups by zone.
SELECT z.zone_name,
       ROUND(AVG(pc.consumption), 2) AS avg_consumption
FROM   power_consumption pc
JOIN   zones z ON z.zone_id = pc.zone_id
GROUP  BY z.zone_name
ORDER  BY avg_consumption DESC;


-- Query 2 shows the hour of day with the highest total demand.
-- I sum all zones per timestamp and then average by hour.
SELECT HOUR(datetime)               AS hour_of_day,
       ROUND(AVG(total_per_ts), 2)  AS avg_total_demand
FROM (
        SELECT datetime, SUM(consumption) AS total_per_ts
        FROM   power_consumption
        GROUP  BY datetime
     ) AS totals
GROUP BY HOUR(datetime)
ORDER BY avg_total_demand DESC
LIMIT 5;


-- Query 3 joins weather with total demand grouped by temperature band.
-- It shows that demand grows when the temperature is higher.
SELECT CASE
           WHEN w.temperature < 15 THEN 'cold (<15C)'
           WHEN w.temperature < 25 THEN 'mild (15-25C)'
           ELSE 'hot (>=25C)'
       END                              AS temp_band,
       ROUND(AVG(t.total_per_ts), 2)    AS avg_total_demand,
       COUNT(*)                         AS n_timestamps
FROM   weather w
JOIN ( SELECT datetime, SUM(consumption) AS total_per_ts
       FROM   power_consumption
       GROUP  BY datetime ) t
       ON t.datetime = w.datetime
GROUP  BY temp_band
ORDER  BY avg_total_demand;


