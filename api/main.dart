"""Task 3 by Samuel Wanjohi.

This file is a small REST API that gives CRUD and time queries for both databases.
"""

import os
import sys
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel

# I add the project root to the path so I can import the config file.
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(ROOT)
import config

# I import the MySQL driver in a try block so the app still loads without it.
try:
    import mysql.connector
except ImportError:
    mysql = None

# I import the MongoDB driver in a try block for the same reason.
try:
    from pymongo import MongoClient, ASCENDING, DESCENDING
except ImportError:
    MongoClient = None


app = FastAPI(
    title="Tetouan Power API",
    description="CRUD and time queries over MySQL and MongoDB.",
    version="1.0",
)


# This shape is used when someone creates or reads a weather record.
class WeatherIn(BaseModel):
    datetime: datetime
    temperature: float
    humidity: float
    wind_speed: float
    general_diffuse_flows: float
    diffuse_flows: float


# This shape is used for updates where every field is optional.
class WeatherUpdate(BaseModel):
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    wind_speed: Optional[float] = None
    general_diffuse_flows: Optional[float] = None
    diffuse_flows: Optional[float] = None


def mysql_conn():
    """Open and return a MySQL connection."""
    if mysql is None:
        raise HTTPException(500, "mysql-connector-python is not installed.")
    return mysql.connector.connect(**config.MYSQL)


def mongo_coll():
    """Open and return the MongoDB readings collection."""
    if MongoClient is None:
        raise HTTPException(500, "pymongo is not installed.")
    client = MongoClient(config.MONGODB["uri"])
    return client[config.MONGODB["database"]][config.MONGODB["collection"]]


@app.get("/")
def home():
    """Show a small message so you know the API is running."""
    return {
        "message": "Tetouan Power API is running.",
        "docs": "/docs",
        "mysql_routes": "/mysql/...",
        "mongo_routes": "/mongo/...",
    }


# These routes work on the weather table in MySQL.
@app.post("/mysql/weather", tags=["MySQL CRUD"])
def mysql_create(item: WeatherIn):
    """Create one weather row in MySQL."""
    conn = mysql_conn()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO weather (datetime, temperature, humidity, wind_speed, "
            "general_diffuse_flows, diffuse_flows) VALUES (%s,%s,%s,%s,%s,%s)",
            (item.datetime, item.temperature, item.humidity, item.wind_speed,
             item.general_diffuse_flows, item.diffuse_flows),
        )
        conn.commit()
    except Exception as e:
        raise HTTPException(400, f"Insert failed: {e}")
    finally:
        cur.close()
        conn.close()
    return {"status": "created", "datetime": item.datetime}


@app.get("/mysql/weather/{dt}", tags=["MySQL CRUD"])
def mysql_read(dt: datetime):
    """Read one weather row from MySQL by its datetime."""
    conn = mysql_conn()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT * FROM weather WHERE datetime = %s", (dt,))
    row = cur.fetchone()
    cur.close()
    conn.close()
    if not row:
        raise HTTPException(404, "No weather record at that datetime.")
    return row


@app.put("/mysql/weather/{dt}", tags=["MySQL CRUD"])
def mysql_update(dt
