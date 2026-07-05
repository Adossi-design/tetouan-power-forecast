"""Task 1 by Jean Muhire.

This file cleans the data and builds the features used by every other part of the project.
"""

import pandas as pd


# These are the three power zone columns from the raw file.
ZONE_COLUMNS = [
    "PowerConsumption_Zone1",
    "PowerConsumption_Zone2",
    "PowerConsumption_Zone3",
]

# This is the value I want to predict.
TARGET = "TotalConsumption"


def load_raw(csv_path: str = "data/powerconsumption.csv") -> pd.DataFrame:
    """Load the raw CSV and turn it into a table indexed by time."""
    df = pd.read_csv(csv_path)
    # I turn the text date into a real date so pandas can work with it.
    df["Datetime"] = pd.to_datetime(df["Datetime"])
    # A time series must be in time order before I make lag features.
    df = df.sort_values("Datetime").set_index("Datetime")
    return df


def add_total_consumption(df: pd.DataFrame) -> pd.DataFrame:
    """Add the target column that sums the three zones together."""
    df = df.copy()
    # Total city demand is the sum of the three zone columns.
    df[TARGET] = df[ZONE_COLUMNS].sum(axis=1)
    return df


def build_features(df: pd.DataFrame, dropna: bool = True) -> pd.DataFrame:
    """Turn a raw time table into a table that is ready for the model."""
    df = df.copy()

    # Make sure the target column exists.
    if TARGET not in df.columns:
        df = add_total_consumption(df)

    # Calendar features help the model learn daily and weekly habits.
    df["hour"] = df.index.hour
    df["dayofweek"] = df.index.dayofweek
    df["month"] = df.index.month
    # is_weekend is 1 on Saturday and Sunday and 0 on other days.
    df["is_weekend"] = (df["dayofweek"] >= 5).astype(int)

    # A lag feature is the demand value from some steps in the past.
    df["lag_1"] = df[TARGET].shift(1)
    df["lag_6"] = df[TARGET].shift(6)
    df["lag_144"] = df[TARGET].shift(144)

    # A moving average is the smoothed demand over a recent window.
    df["roll_mean_6"] = df[TARGET].shift(1).rolling(window=6).mean()
    df["roll_mean_144"] = df[TARGET].shift(1).rolling(window=144).mean()

    # I drop the first rows because their lag and rolling values are empty.
    if dropna:
        df = df.dropna()

    return df


# This is the exact list and order of columns the model is trained on.
FEATURE_COLUMNS = [
    "Temperature",
    "Humidity",
    "WindSpeed",
    "GeneralDiffuseFlows",
    "DiffuseFlows",
    "hour",
    "dayofweek",
    "month",
    "is_weekend",
    "lag_1",
    "lag_6",
    "lag_144",
    "roll_mean_6",
    "roll_mean_144",
]


def get_X_y(df: pd.DataFrame):
    """Split the feature table into inputs X and target y."""
    X = df[FEATURE_COLUMNS]
    y = df[TARGET]
    return X, y


if __name__ == "__main__":
    # This block is a quick self test you can run on its own.
    raw = load_raw()
    print("Raw shape:", raw.shape)
    print("Missing values in raw data:")
    print(raw.isnull().sum())
    feats = build_features(raw)
    print("Feature table shape after build_features:", feats.shape)
    print("Feature columns:", FEATURE_COLUMNS)
    X, y = get_X_y(feats)
    print("X:", X.shape, "y:", y.shape)
