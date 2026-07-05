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
