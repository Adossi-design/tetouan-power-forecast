"""Task 2 by Shem Ayioka.

This file reads the CSV and loads it into the MongoDB readings collection.
"""

import os
import sys

import pandas as pd
from pymongo import MongoClient, ASCENDING

# I add the project root to the path so I can import the config file.
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.append(ROOT)
import config

# I insert documents in chunks to keep each write small.
BATCH = 5000


def main():
    csv_path = os.path.join(ROOT, config.CSV_PATH)
    print("Reading CSV:", csv_path)
    df = pd.read_csv(csv_path)
    df["Datetime"] = pd.to_datetime(df["Datetime"])

    client = MongoClient(config.MONGODB["uri"])
    coll = client[config.MONGODB["database"]][config.MONGODB["collection"]]

    # I clear the collection so the loader can run again.
    coll.drop()
    # The unique index keeps one document per timestamp.
    coll.create_index([("datetime", ASCENDING)], unique=True)

    print("Building documents...")
    docs = []
    for row in df.itertuples(index=False):
        z1, z2, z3 = (row.PowerConsumption_Zone1,
                      row.PowerConsumption_Zone2,
                      row.PowerConsumption_Zone3)
        docs.append({
            "datetime": row.Datetime.to_pydatetime(),
            "temperature": float(row.Temperature),
            "humidity": float(row.Humidity),
            "wind_speed": float(row.WindSpeed),
            "general_diffuse_flows": float(row.GeneralDiffuseFlows),
            "diffuse_flows": float(row.DiffuseFlows),
            # I store the three zones as an array of small documents.
            "zones": [
                {"zone": 1, "consumption": float(z1)},
                {"zone": 2, "consumption": float(z2)},
                {"zone": 3, "consumption": float(z3)},
            ],
            # I store the total so time queries stay cheap.
            "total_consumption": float(z1 + z2 + z3),
        })

    print("Inserting", len(docs), "documents...")
    for i in range(0, len(docs), BATCH):
        coll.insert_many(docs[i:i + BATCH])
    print("Done. MongoDB is loaded. Total docs:", coll.count_documents({}))

    client.close()


if __name__ == "__main__":
    main()
