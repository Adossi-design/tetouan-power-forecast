# Tetouan City Power Forecast

This is a group project for the time series assignment, and the goal is to predict how much electricity the city of Tetouan in Morocco uses in total. The forecast is built from the weather and the recent history of demand, and on top of the model the project also includes two databases, an API and a small prediction script so the whole thing works together from end to end.

A few quick facts about the data:

- The file is `data/powerconsumption.csv` and it has 52,416 rows and 9 columns covering the whole year of 2017.
- It records the power used in three city zones every ten minutes, and it also stores weather values like temperature and humidity.
- There are no missing values in the original data.
- The target is a column called `TotalConsumption`, which is simply Zone1 plus Zone2 plus Zone3.
- Two models were trained, a Linear Regression baseline and a Random Forest with a little tuning, and the Random Forest came out on top.

## How the project is organised

```
tetouan-power-forecast/
├── README.md
├── requirements.txt
├── config.py
├── data/powerconsumption.csv
├── notebooks/01_eda_preprocessing_modeling.ipynb
├── src/
│   ├── preprocessing.py
│   └── train.py
├── models/model.pkl
├── database/
│   ├── sql/{schema.sql, erd.dbml, queries.sql, load_data.py}
│   └── mongodb/{design.md, load_data.py, queries.js}
├── api/main.py
├── predict.py
└── report/{report.md, build_pdf.py, report.pdf}
```

## Who did what

The work was split by task, and each person owned one part from start to finish. This table sits here in the middle so that anyone reading can quickly see who to ask about which piece of the project.

| Member              | Task   | Part of the project they owned                            |
|---------------------|--------|-----------------------------------------------------------|
| Jean Muhire         | Task 1 | Exploration, preprocessing and the models (notebook, src) |
| Shem Ayioka         | Task 2 | The MySQL and MongoDB design, loaders and queries         |
| Samuel Wanjohi      | Task 3 | The FastAPI CRUD and time series endpoints                |
| Adossi Fred William | Task 4 | The end to end prediction script                          |

## Setting it up

The easiest way is to make a virtual environment first and then install everything from the requirements file.

```bash
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On macOS or Linux:
# source .venv/bin/activate

pip install -r requirements.txt
```

You only actually need MySQL and MongoDB for Task 2 and for the database routes of the API. Task 1 and Task 4 will run fine without any database installed, so you can try the modelling and the prediction straight away.

## Running each task

### Task 1, the exploration and the model

To train the two models and save the winning one, run the training script. It prints the comparison table and writes the model file.

```bash
python src/train.py
```

To see the full exploration with all the plots and explanations, open the notebook.

```bash
jupyter notebook notebooks/01_eda_preprocessing_modeling.ipynb
```

If you just want to check that the feature code works on its own, you can run the preprocessing file directly.

```bash
python src/preprocessing.py
```

### Task 2, the databases

MySQL needs a running server, and you can put your login details in `config.py` or set them as environment variables. Then create the tables, load the data and run the example queries.

```bash
mysql -u root -p < database/sql/schema.sql
python database/sql/load_data.py
mysql -u root -p tetouan_power < database/sql/queries.sql
```

MongoDB also needs a running server, and it works in a similar way.

```bash
python database/mongodb/load_data.py
mongosh tetouan_power database/mongodb/queries.js
```

For the diagram picture, go to https://dbdiagram.io, paste in the contents of `database/sql/erd.dbml`, and export it as a PNG into the report folder.

### Task 3, the API

Start the API with uvicorn and then open the automatic documentation page in your browser, which is the easiest way to try the endpoints.

```bash
uvicorn api.main:app --reload
# then open http://127.0.0.1:8000/docs
```

The same set of routes exists for both databases, with MySQL under `/mysql` and MongoDB under `/mongo`.

| Method | MySQL path                | MongoDB path                | What it does        |
|--------|---------------------------|-----------------------------|---------------------|
| POST   | `/mysql/weather`          | `/mongo/readings`           | create a record     |
| GET    | `/mysql/weather/{dt}`     | `/mongo/readings/{dt}`      | read one record     |
| PUT    | `/mysql/weather/{dt}`     | `/mongo/readings/{dt}`      | update a record     |
| DELETE | `/mysql/weather/{dt}`     | `/mongo/readings/{dt}`      | delete a record     |
| GET    | `/mysql/latest`           | `/mongo/latest`             | newest record       |
| GET    | `/mysql/by-date-range`    | `/mongo/by-date-range`      | records in a range  |

Here is an example of the date range endpoint in action:
`GET http://127.0.0.1:8000/mysql/by-date-range?start=2017-01-01T00:00:00&end=2017-01-01T01:00:00`

### Task 4, the prediction script

The best way to run it is to start the API first so the script can call the latest endpoint, and then run the script in another terminal.

```bash
uvicorn api.main:app --reload
python predict.py
```

If the API or the database is not running, the script falls back to the last timestamp in the CSV, so it will still run all the way through even during a quick demo.

## Building the PDF report

The written report lives in `report/report.md`, and the repo includes a small script that turns it into a PDF. Run it after you have filled in your names.

```bash
python report/build_pdf.py
```

## Reproducing the results

1. Install everything with `pip install -r requirements.txt`.
2. Run `python src/train.py` to get the comparison table and the saved model.
3. Run `python predict.py` to see a prediction next to the real value.

The Random Forest uses a fixed random state, so you should get the same numbers reported here each time you run it.
