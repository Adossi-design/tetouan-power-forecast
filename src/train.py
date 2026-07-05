"""Task 1 by Jean Muhire.

This file trains two models and saves the better one to a file.
"""

import os
import sys

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GridSearchCV, TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

# I add the src folder to the path so I can import my own module.
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from preprocessing import build_features, get_X_y, load_raw, FEATURE_COLUMNS, TARGET


MODEL_PATH = "models/model.pkl"


def evaluate(name, y_true, y_pred):
    """Return the three score numbers for one model."""
    mae = mean_absolute_error(y_true, y_pred)
    # RMSE is the square root of the mean squared error.
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    r2 = r2_score(y_true, y_pred)
    return {"model": name, "MAE": mae, "RMSE": rmse, "R2": r2}


def main():
    # Load the data and build the same features used everywhere else.
    print("Loading data and building features...")
    raw = load_raw()
    data = build_features(raw)
    X, y = get_X_y(data)

    # I split by time so the first 80 percent is train and the last 20 percent is test.
    split_index = int(len(X) * 0.80)
    X_train, X_test = X.iloc[:split_index], X.iloc[split_index:]
    y_train, y_test = y.iloc[:split_index], y.iloc[split_index:]
    print("Train rows:", len(X_train), "up to", X_train.index[-1])
    print("Test rows:", len(X_test), "from", X_test.index[0])

    results = []

    # Experiment 1 is a Linear Regression that uses scaled features.
    print("Experiment 1 Linear Regression...")
    # I scale the features because a linear model works better when values share a similar range.
    linreg = Pipeline([
        ("scaler", StandardScaler()),
        ("model", LinearRegression()),
    ])
    linreg.fit(X_train, y_train)
    linreg_pred = linreg.predict(X_test)
    results.append(evaluate("LinearRegression", y_test, linreg_pred))

    # Experiment 2 is a Random Forest with a small search over settings.
    print("Experiment 2 Random Forest with a small grid search...")
    # I keep the grid small so it trains fast on a normal laptop.
    param_grid = {
        "n_estimators": [100, 200],
        "max_depth": [10, 20],
    }
    rf = RandomForestRegressor(random_state=42, n_jobs=-1)
    # TimeSeriesSplit keeps the time order during cross validation.
    tscv = TimeSeriesSplit(n_splits=3)
    grid = GridSearchCV(
        rf,
        param_grid,
        cv=tscv,
        scoring="neg_mean_absolute_error",
        n_jobs=-1,
    )
    grid.fit(X_train, y_train)
    best_rf = grid.best_estimator_
    print("Best Random Forest params:", grid.best_params_)
    rf_pred = best_rf.predict(X_test)
    results.append(evaluate("RandomForest", y_test, rf_pred))

    # Show a small table that compares the two experiments.
    table = pd.DataFrame(results).set_index("model")
    print("Experiment comparison on the 20 percent test set:")
    print(table.round(2).to_string())

    # The model with the lowest MAE is the winner.
    best_name = table["MAE"].idxmin()
    best_model = best_rf if best_name == "RandomForest" else linreg
    print("Best model by MAE:", best_name)

    os.makedirs("models", exist_ok=True)
    # I save the model together with the feature order so prediction is safe.
    bundle = {
        "model": best_model,
        "model_name": best_name,
        "feature_columns": FEATURE_COLUMNS,
        "target": TARGET,
    }
    joblib.dump(bundle, MODEL_PATH)
    print("Saved best model to", MODEL_PATH)


if __name__ == "__main__":
    main()
