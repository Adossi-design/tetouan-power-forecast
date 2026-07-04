"""Shared file used by Task 2 (Shem Ayioka) and Task 3 (Samuel Wanjohi).

This file keeps all database connection settings in one place.
"""

import os

# Settings are read from environment variables with safe local defaults.
MYSQL = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "port": int(os.getenv("MYSQL_PORT", "3306")),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", "root"),
    "database": os.getenv("MYSQL_DATABASE", "tetouan_power"),
}

# Settings for the MongoDB connection.
MONGODB = {
    "uri": os.getenv("MONGODB_URI", "mongodb://localhost:27017"),
    "database": os.getenv("MONGODB_DATABASE", "tetouan_power"),
    "collection": os.getenv("MONGODB_COLLECTION", "readings"),
}

# Path to the dataset file.
CSV_PATH = os.getenv("CSV_PATH", "data/powerconsumption.csv")
