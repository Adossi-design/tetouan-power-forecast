"""Task 4 by Adossi Fred William.

This script fetches a record, builds features, loads the model, and prints a prediction.
"""

import os
import sys

import joblib
import pandas as pd
import requests

# I import the same feature pipeline that training used.
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), "src"))
from preprocessing import build_features, load_raw, TARGET, FEATURE_COLUMNS

API_URL = os.getenv("API_URL", "http://127.0.0.1:8000")
MODEL_PATH = "models/model.pkl"


def fetch_latest_timestamp():
    """Ask the API for the newest record and return its timestamp."""
    try:
        resp = requests.get(f"{API_URL}/mysql/latest", timeout=3)
        resp.raise_for_status()
        record = resp.json()
        print("Fetched latest record from API:", record.get("datetime"))
        return pd.to_datetime(record["datetime"])
    except Exception as e:
        # If the API is not running I fall back to the CSV.
        print("Could not reach the API:", e)
        print("Falling back to the last timestamp in the CSV.")
        return None


def main():
    # Step 1 is to find the timestamp I want to predict.
    target_ts = fetch_latest_timestamp()

    # Step 2 is to build features with the same pipeline used in training.
    raw = load_raw()
    if target_ts is None:
        # The fallback timestamp is the newest row in the CSV.
        target_ts = raw.index.max()
    print("Predicting total demand for timestamp:", target_ts)

    features = build_features(raw)

    # This timestamp needs at least one day of history before it.
    if target_ts not in features.index:
        raise SystemExit(f"No feature row available for {target_ts}.")

    # I pick the single feature row for my timestamp in the right column order.
    X_row = features.loc[[target_ts], FEATURE_COLUMNS]

    # Step 3 is to load the saved model bundle.
    bundle = joblib.load(MODEL_PATH)
    model = bundle["model"]
    print("Loaded model:", bundle["model_name"])

    # Step 4 is to make the prediction and print it.
    prediction = model.predict(X_row)[0]
    # I also show the true value so I can check the result.
    actual = features.loc[target_ts, TARGET]

    print("================ PREDICTION ================")
    print("Timestamp:", target_ts)
    print(f"Predicted total demand: {prediction:,.2f}")
    print(f"Actual total demand: {actual:,.2f}")
    print(f"Absolute error: {abs(prediction - actual):,.2f}")
    print("============================================")


if __name__ == "__main__":
    main()
