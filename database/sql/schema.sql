-- Task 2 by Shem Ayioka.
-- This file creates the three MySQL tables for the project.
-- I split the wide CSV into three tables so no data is repeated.

CREATE DATABASE IF NOT EXISTS tetouan_power;
USE tetouan_power;

-- I drop the tables in order so the script can run again safely.
DROP TABLE IF EXISTS power_consumption;
DROP TABLE IF EXISTS weather;
DROP TABLE IF EXISTS zones;

-- The zones table is a small lookup for the three city zones.
CREATE TABLE zones (
    zone_id   INT PRIMARY KEY,
    zone_name VARCHAR(50) NOT NULL
);

-- The weather table holds one row of weather for each timestamp.
CREATE TABLE weather (
    datetime              DATETIME PRIMARY KEY,
    temperature           FLOAT,
    humidity              FLOAT,
    wind_speed            FLOAT,
    general_diffuse_flows FLOAT,
    diffuse_flows         FLOAT
);

-- The power_consumption table stores one row for each timestamp and zone.
CREATE TABLE power_consumption (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    datetime    DATETIME NOT NULL,
    zone_id     INT NOT NULL,
    consumption FLOAT NOT NULL,
    CONSTRAINT fk_pc_weather FOREIGN KEY (datetime) REFERENCES weather(datetime),
    CONSTRAINT fk_pc_zone    FOREIGN KEY (zone_id)  REFERENCES zones(zone_id)
);

-- These indexes make the time queries faster.
CREATE INDEX idx_pc_datetime ON power_consumption (datetime);
CREATE INDEX idx_pc_zone     ON power_consumption (zone_id);

-- I add the three fixed zone rows.
INSERT INTO zones (zone_id, zone_name) VALUES
    (1, 'Zone 1'),
    (2, 'Zone 2'),
    (3, 'Zone 3');
