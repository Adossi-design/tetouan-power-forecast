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
def mysql_update(dt: datetime, item: WeatherUpdate):
    """Update one or more fields of a weather row in MySQL."""
    # I only update the fields that were actually sent.
    fields = {k: v for k, v in item.dict().items() if v is not None}
    if not fields:
        raise HTTPException(400, "No fields provided to update.")
    set_clause = ", ".join(f"{k} = %s" for k in fields)
    conn = mysql_conn()
    cur = conn.cursor()
    cur.execute(f"UPDATE weather SET {set_clause} WHERE datetime = %s",
                list(fields.values()) + [dt])
    conn.commit()
    affected = cur.rowcount
    cur.close()
    conn.close()
    if affected == 0:
        raise HTTPException(404, "No weather record at that datetime.")
    return {"status": "updated", "datetime": dt, "fields": fields}


@app.delete("/mysql/weather/{dt}", tags=["MySQL CRUD"])
def mysql_delete(dt: datetime):
    """Delete one weather row from MySQL."""
    conn = mysql_conn()
    cur = conn.cursor()
    cur.execute("DELETE FROM weather WHERE datetime = %s", (dt,))
    conn.commit()
    affected = cur.rowcount
    cur.close()
    conn.close()
    if affected == 0:
        raise HTTPException(404, "No weather record at that datetime.")
    return {"status": "deleted", "datetime": dt}


@app.get("/mysql/latest", tags=["MySQL time-series"])
def mysql_latest():
    """Return the newest weather record from MySQL."""
    conn = mysql_conn()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT * FROM weather ORDER BY datetime DESC LIMIT 1")
    row = cur.fetchone()
    cur.close()
    conn.close()
    if not row:
        raise HTTPException(404, "Table is empty.")
    return row


@app.get("/mysql/by-date-range", tags=["MySQL time-series"])
def mysql_range(
    start: datetime = Query(..., description="ISO datetime like 2017-01-01T00:00:00"),
    end: datetime = Query(..., description="ISO datetime like 2017-01-01T01:00:00"),
    limit: int = 100,
):
    """Return weather records between two datetimes from MySQL."""
    conn = mysql_conn()
    cur = conn.cursor(dictionary=True)
    cur.execute(
        "SELECT * FROM weather WHERE datetime BETWEEN %s AND %s "
        "ORDER BY datetime ASC LIMIT %s",
        (start, end, limit),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return {"count": len(rows), "records": rows}


def _clean(doc):
    """Remove the Mongo id field so the result can be sent as JSON."""
    if doc and "_id" in doc:
        doc.pop("_id")
    return doc


# These routes work on the readings collection in MongoDB.
@app.post("/mongo/readings", tags=["MongoDB CRUD"])
def mongo_create(item: WeatherIn):
    """Create one reading document in MongoDB."""
    coll = mongo_coll()
    if coll.find_one({"datetime": item.datetime}):
        raise HTTPException(400, "A reading already exists at that datetime.")
    doc = item.dict()
    # I start with an empty zones list to keep this route simple.
    doc["zones"] = []
    doc["total_consumption"] = 0.0
    coll.insert_one(doc)
    return {"status": "created", "datetime": item.datetime}


@app.get("/mongo/readings/{dt}", tags=["MongoDB CRUD"])
def mongo_read(dt: datetime):
    """Read one reading document from MongoDB by its datetime."""
    coll = mongo_coll()
    doc = coll.find_one({"datetime": dt})
    if not doc:
        raise HTTPException(404, "No reading at that datetime.")
    return _clean(doc)


@app.put("/mongo/readings/{dt}", tags=["MongoDB CRUD"])
def mongo_update(dt: datetime, item: WeatherUpdate):
    """Update one or more fields of a reading in MongoDB."""
    fields = {k: v for k, v in item.dict().items() if v is not None}
    if not fields:
        raise HTTPException(400, "No fields provided to update.")
    coll = mongo_coll()
    result = coll.update_one({"datetime": dt}, {"$set": fields})
    if result.matched_count == 0:
        raise HTTPException(404, "No reading at that datetime.")
    return {"status": "updated", "datetime": dt, "fields": fields}


@app.delete("/mongo/readings/{dt}", tags=["MongoDB CRUD"])
def mongo_delete(dt: datetime):
    """Delete one reading document from MongoDB."""
    coll = mongo_coll()
    result = coll.delete_one({"datetime": dt})
    if result.deleted_count == 0:
        raise HTTPException(404, "No reading at that datetime.")
    return {"status": "deleted", "datetime": dt}


@app.get("/mongo/latest", tags=["MongoDB time-series"])
def mongo_latest():
    """Return the newest reading from MongoDB."""
    coll = mongo_coll()
    doc = coll.find_one(sort=[("datetime", DESCENDING)])
    if not doc:
        raise HTTPException(404, "Collection is empty.")
    return _clean(doc)


@app.get("/mongo/by-date-range", tags=["MongoDB time-series"])
def mongo_range(
    start: datetime = Query(..., description="ISO datetime"),
    end: datetime = Query(..., description="ISO datetime"),
    limit: int = 100,
):
    """Return readings between two datetimes from MongoDB."""
    coll = mongo_coll()
    cursor = (coll.find({"datetime": {"$gte": start, "$lte": end}})
                  .sort("datetime", ASCENDING).limit(limit))
    records = [_clean(d) for d in cursor]
    return {"count": len(records), "records": records}
