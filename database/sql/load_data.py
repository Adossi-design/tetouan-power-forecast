"""Task 2 by Shem Ayioka.

This file reads the CSV and loads it into the three MySQL tables.
"""

import os
import sys

import pandas as pd
import mysql.connector

# I add the project root to the path so I can import the config file.
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.append(ROOT)
import config

# I insert rows in chunks so the queries stay small.
BATCH = 5000


def main():
    csv_path = os.path.join(ROOT, config.CSV_PATH)
    print("Reading CSV:", csv_path)
    df = pd.read_csv(csv_path)
    df["Datetime"] = pd.to_datetime(df["Datetime"])
    # MySQL wants dates in this text format.
    df["Datetime"] = df["Datetime"].dt.strftime("%Y-%m-%d %H:%M:%S")

    conn = mysql.connector.connect(**config.MYSQL)
    cur = conn.cursor()

    # First I insert one weather row for each timestamp.
    print("Inserting weather rows...")
    weather_rows = list(df[[
        "Datetime", "Temperature", "Humidity", "WindSpeed",
        "GeneralDiffuseFlows", "DiffuseFlows",
    ]].itertuples(index=False, name=None))

    weather_sql = (
        "INSERT INTO weather "
        "(datetime, temperature, humidity, wind_speed, "
        " general_diffuse_flows, diffuse_flows) "
        "VALUES (%s, %s, %s, %s, %s, %s)"
    )
    for i in range(0, len(weather_rows), BATCH):
        cur.executemany(weather_sql, weather_rows[i:i + BATCH])
        conn.commit()
    print("Inserted", len(weather_rows), "weather rows")

    # Then I turn the three zone columns into long format rows.
    print("Inserting power_consumption rows...")
    zone_map = {
        1: "PowerConsumption_Zone1",
        2: "PowerConsumption_Zone2",
        3: "PowerConsumption_Zone3",
    }
    pc_rows = []
    for zone_id, col in zone_map.items():
        for dt, val in zip(df["Datetime"], df[col]):
            pc_rows.append((dt, zone_id, float(val)))

    pc_sql = (
        "INSERT INTO power_consumption (datetime, zone_id, consumption) "
        "VALUES (%s, %s, %s)"
    )
    for i in range(0, len(pc_rows), BATCH):
        cur.executemany(pc_sql, pc_rows[i:i + BATCH])
        conn.commit()
    print("Inserted", len(pc_rows), "consumption rows")

    cur.close()
    conn.close()
    print("Done. MySQL is loaded.")


if __name__ == "__main__":
    main()
